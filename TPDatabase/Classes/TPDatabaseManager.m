//
//  TPDatabaseManager.m
//  TPDatabase
//
//  Created by Topredator on 2024/11/23.
//

#import "TPDatabaseManager.h"
#import "TPDBRouter.h"
#import "TPDatabaseTableMap.h"
#import <Asterism/Asterism.h>

static NSString *kTPDatabaseDefault = @"com.tp.database.userDefault";

@interface TPDatabaseManager ()
@property (nonatomic, strong) TPDatabaseConfig *config;
/// 数据库对象
@property (nonatomic, strong) FMDatabase *mainDB;

@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) dispatch_queue_t databaseQueue;



@end


static TPDatabaseManager *manager = nil;
@implementation TPDatabaseManager
+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [TPDatabaseManager new];
    });
    return manager;
}
- (void)setConfiguration:(TPDatabaseConfig *)configuration {
    self.config = configuration;
}
- (void)setConfig:(TPDatabaseConfig *)config {
    if (!config) {
        _config = [TPDatabaseConfig configDBName:@"TPDatabase.db" version:@"0.1"];
    } else {
        _config = config;
    }
    [self openAndCreate];
}

- (void)openAndCreate {
    NSString *sqlPath = [self databasePath:self.config.dbName];
    self.mainDB = [FMDatabase databaseWithPath:sqlPath];
    self.queue = [FMDatabaseQueue databaseQueueWithPath:sqlPath];
    self.databaseQueue = dispatch_queue_create("com.tp.database.dbqueue", 0);
    if ([self.mainDB open]) {
        // 使用单例 存储表数据
        [self prepareTableMapping];
        /// 开始事务
        [self.mainDB beginTransaction];
        /// 判断数据库版本是否一致，不一致删除源数据库重建 (用于数据库版本更新)
            /// 获取所有数据
        NSMutableDictionary *mdic = [self tryToDropTableWithVersion:self.config.dbVersion];
        
        /// 重新创建数据库并把所有数据存储 (通过类名 创建表)
        [self moduleUpdate];
        NSDictionary *SQLMap = [TPDatabaseTableMap.tableMap tablesInsertSQLMap].copy;
        NSDictionary *dataMap = [TPDatabaseTableMap.tableMap tablesInsertDataMap].copy;
        [self prepareTableMapping];
        
        NSDictionary *SQLMap1 = [TPDatabaseTableMap.tableMap tablesInsertSQLMap].copy;
        NSDictionary *dataMap1 = [TPDatabaseTableMap.tableMap tablesInsertDataMap].copy;
        ASTEach(mdic, ^(NSString *tableName, id obj) {
            /// 前后两次 对比插入
            NSArray *columns1 = [SQLMap[tableName] componentsSeparatedByString:@","];
            NSArray *dataNames1 = [dataMap[tableName] componentsSeparatedByString:@","];
            NSArray *columns2 = [SQLMap1[tableName] componentsSeparatedByString:@","];
            NSArray *dataNames2 = [dataMap1[tableName] componentsSeparatedByString:@","];
            
            NSMutableArray *columns = [NSMutableArray array];
            NSString *columnsStr = @"";
            for (NSString *str1 in columns1) {
                for (NSString *str2 in columns2) {
                    if ([str1 isEqualToString:str2]) {
                        [columns addObject:str1];
                        columnsStr = [NSString stringWithFormat:@"%@,%@", columnsStr, str1];
                        break;
                    }
                }
            }
            columnsStr = [columnsStr substringFromIndex:1];
            NSString *dicnamesStr = @"";
            for (NSString *str1 in dataNames1) {
                for (NSString *str2 in dataNames2) {
                    if ([str1 isEqualToString:str2]) {
                        dicnamesStr = [NSString stringWithFormat:@"%@,%@", dicnamesStr,str1];
                        break;
                    }
                }
            }
            dicnamesStr = [dicnamesStr substringFromIndex:1];
            NSString *sql = [NSString stringWithFormat:@"REPLACE INTO %@(%@) VALUES(%@)",tableName,columnsStr,dicnamesStr];
            for (NSMutableDictionary *dic in obj) {
                NSMutableDictionary *columnsDic = [NSMutableDictionary dictionary];
                [dic enumerateKeysAndObjectsUsingBlock:^(id str1, id obj, BOOL *stop) {
                    for (NSString *str2 in columns) {
                        if ([str1 isEqualToString:str2]) {
                            [columnsDic setObject:obj forKey:str1];
                            break;
                        }
                    }
                }];
                [self.mainDB executeUpdate:sql withParameterDictionary:columnsDic];
            }
        });
        [self.mainDB commit];
    } else {
        [self prepareTableMapping];
    }
}

- (void)prepareTableMapping {
    NSMutableArray *names = @[].mutableCopy;
    NSMutableArray *colArrs = @[].mutableCopy;
    /// 同步查询表数据
    ///
    [self query:^id(FMDatabase *db) {
        FMResultSet *resultSet = [db executeQuery:@"SELECT name FROM sqlite_master WHERE type = 'table'"];
        while ([resultSet next]) {
            NSString *name = [resultSet stringForColumn:@"name"];
            if (![name isEqualToString:@"sqlite_sequence"]) {
                [names addObject:name];
            }
        }
        [resultSet close];
        for (NSString *name in names) {
            NSMutableArray *cols = [NSMutableArray array];
            FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"PRAGMA table_info(%@)", name]];
            while ([resultSet next]) {
                [cols addObject:[resultSet stringForColumn:@"name"]];
            }
            [resultSet close];
            [colArrs addObject:cols];
        }
        return nil;
    } type:0 waitUntilDone:YES];
    
    for (int i = 0; i < names.count; i++) {
        NSString *key = names[i];
        NSArray *cols = colArrs[i];
        [TPDatabaseTableMap.tableMap setMap:key datas:cols];
    }
}
/// 通过版本 drop table 然后 从新创建
- (NSMutableDictionary *)tryToDropTableWithVersion:(NSString *)version {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    /// 获取存储的版本
    id dbVersion = [ud valueForKey:kTPDatabaseDefault];
    if (!dbVersion) {
        [ud setValue:version forKey:kTPDatabaseDefault];
    } else if (![version isEqualToString:dbVersion]) {
        [ud setValue:version forKey:kTPDatabaseDefault];
        
        // 数据库语句
        NSString *sqlFormat = @"DROP TABLE IF EXISTS %@";
        NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
        
        for (NSString *tableName in TPDatabaseTableMap.tableMap.tablesMap.allKeys) {
            NSMutableArray *marr = @[].mutableCopy;
            FMResultSet *rs = [self.mainDB executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@", tableName]];
            while ([rs next]) {
                [marr addObject:[rs resultDictionary]];
            }
            [rs close];
            // 存储 表数据
            [mdic setObject:marr forKey:tableName];
            // 删除表
            [self.mainDB executeUpdate:[NSString stringWithFormat:sqlFormat, tableName]];
        }
        return mdic;
    }
    return nil;
}

- (void)moduleUpdate {
    if (!self.moduleArray) return;
    for (Class className in self.moduleArray) {
        if ([className respondsToSelector:@selector(updateDBOnLaunching:)]) {
            [className updateDBOnLaunching:self.mainDB];
        }
    }
}

- (id)query:(id (^)(FMDatabase *db))block type:(NSInteger)type {
    return [self query:block type:type waitUntilDone:NO];
}
- (id)query:(id (^)(FMDatabase *db))block type:(NSInteger)type waitUntilDone:(BOOL)waitUnilDone {
    __block id result = nil;
    void (^queryBlock) (FMDatabase *db) = ^(FMDatabase *db){
        result = block(db);
    };
    if (waitUnilDone) {
        if([[NSThread currentThread] isMainThread]) {
            return block(self.mainDB);
        } else {
            [self.queue inDatabase:queryBlock];          //如果不是主线程 放入队列中执行以保证顺序
            /// 通知
            [self callback:result type:type];
            return result;
        }
    } else {
        __weak typeof(self) weakSelf = self;
        dispatch_async(self.databaseQueue, ^{            //放入异步队列执行
            assert(![[NSThread currentThread] isMainThread]);
            
            [weakSelf.queue inDatabase:queryBlock];
            /// 通知
            [weakSelf callback:result type:type];
        });
    }
    return nil;
}
- (id)query:(NSString *)sql param:(NSDictionary *)param type:(NSInteger)type {
    return [self query:sql param:param type:type waitUntilDone:NO];
}
- (id)query:(NSString *)sql param:(NSDictionary *)param type:(NSInteger)type waitUntilDone:(BOOL)waitUnilDone {
    NSString *infoLog = [NSString stringWithFormat:@"🔍 SQL: \n%@\n", sql];
    if (param) {
        infoLog = [infoLog stringByAppendingFormat:@"Param:\n%@\n", param];
    }
    NSLog(@"%@", infoLog);
    __weak typeof(self) weakSelf = self;
    id (^block) (FMDatabase *db) = (id) ^(FMDatabase *db){
        NSMutableArray *result = [NSMutableArray array];
        FMResultSet *rs;
        if (param) {
            rs = [db executeQuery:sql withParameterDictionary:param];
        } else {
            rs = [db executeQuery:sql];
        }
        if([db hadError]) {
            NSLog(@"❌ SQL Error:\nCode: %d\nMessage: %@\n",[db lastErrorCode], [db lastErrorMessage]);
        } else {
            NSString *successLog = [NSString stringWithFormat:@"✅ Success:\nSQL:\n%@\n", sql];
            if (param) {
                successLog = [successLog stringByAppendingFormat:@"Param:\n%@\n", param];
            }
            NSLog(@"%@", successLog);
        }
        while ([rs next]) {
            [result addObject:[weakSelf removeNSNullFromDic:[rs resultDictionary]]];
        }
        return result;
    };
    return [self query:block type:type waitUntilDone:waitUnilDone];
}
- (void)update:(void (^)(FMDatabase *db, BOOL *rollback))block type:(NSInteger)type waitUntilDone:(BOOL)waitUnilDone result:(id)result {
    if ([NSThread.currentThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            if (waitUnilDone) { // 等待执行完
                [weakSelf.queue inTransaction:block];
                [weakSelf callback:result type:type];
            } else {
                dispatch_async(weakSelf.databaseQueue, ^{
                    [weakSelf.queue inTransaction:block];
                    [weakSelf callback:result type:type];
                });
            }
        });
    } else {
        if (waitUnilDone) { // 等待执行完
            [self.queue inTransaction:block];
            [self callback:result type:type];
        } else {
            __weak typeof(self) weakSelf = self;
            dispatch_async(weakSelf.databaseQueue, ^{
                [weakSelf.queue inTransaction:block];
                [weakSelf callback:result type:type];
            });
        }
    }
}

- (void)callback:(id)result type:(NSInteger)type {
    if (type != 0) {
        [TPDBRouter sendMessageToRoutes:type result:0 argument:result];
    }
}
- (void)asyncCallback:(id)result type:(NSInteger)type {
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.databaseQueue, ^{
        [weakSelf callback:result type:type];
    });
}
// 去除数据库查询中的所有NSNULL
- (id)removeNSNullFromDic:(id)dic {
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:dic];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if([obj isKindOfClass:[NSNull class]]) {
            [result removeObjectForKey:key];
        }
    }];
    return result;
}
#pragma mark----------------- Private method -----------------
- (NSString *)databaseDirPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths objectAtIndex:0];
    NSString *directory = [documentDirectory stringByAppendingPathComponent:@"TPDataBase"];
    NSFileManager *manager = NSFileManager.defaultManager;
    if (![manager fileExistsAtPath:directory]) {
        [manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    return directory;
}
- (NSString *)databasePath:(NSString *)dbName {
    return [[self databaseDirPath] stringByAppendingPathComponent:dbName];
}
@end
