//
//  TPBaseDao.m
//  TPDatabase
//
//  Created by Topredator on 2024/11/25.
//

#import "TPBaseDao.h"
#import "TPDatabaseManager.h"
#import "TPDatabaseTableMap.h"
#import <TPJsonModel/TPJsonModel.h>

@implementation TPBaseDao
+ (instancetype)daoWithTableName:(NSString *)tableName {
    TPBaseDao *dao = [[self alloc] init];
    dao.tableName = tableName;
    return dao;
}
#pragma mark----------------- Update -----------------
- (void)save:(id)data messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUtilDone {
    [self save:data messageType:messageType waitUntilDone:waitUtilDone igoner:NO];
}
- (void)save:(id)data messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUtilDone igoner:(BOOL)ignore {
    // 数据为空 或者  传入空数组 直接发送通知
    if (!data || ([data isKindOfClass:NSArray.class] && [data count] == 0)) {
        if (waitUtilDone) {
            [TPDBManager callback:nil type:messageType];
        } else {
            [TPDBManager asyncCallback:nil type:messageType];
        }
        return;
    }
    NSString *sql = ignore ? [self generateAddOrIgnoreSQL] : [self generateAddOrUpdateSQL];
    id parameter = [self removeUnusedKey:data];
    if (parameter) {
        [self update:sql parameter:parameter messageType:messageType waitUntilDone:waitUtilDone];
    }
}
- (void)update:(NSString *)sql parameter:(id)parameter messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    NSString *infoLog = [NSString stringWithFormat:@"🚀 SQL: \n%@\n", sql];
    if (parameter) {
        infoLog = [infoLog stringByAppendingFormat:@"Param:\n%@\n", parameter];
    }
    NSLog(@"%@", infoLog);
    void (^saveBlock) (FMDatabase *db, BOOL *rollback) = ^(FMDatabase *db, BOOL *rollback){
        if ([parameter isKindOfClass:[NSDictionary class]] || [parameter isKindOfClass:[NSMutableDictionary class]]) {
            [db executeUpdate:sql withParameterDictionary:parameter];
        } else if ([parameter isKindOfClass:[NSArray class]] || [parameter isKindOfClass:[NSMutableArray class]]) {
            for (id dic in parameter) {
                [db executeUpdate:sql withParameterDictionary:dic];
            }
        } else if (!parameter) {
            [db executeUpdate:sql];
        } else {
            [db executeQuery:sql, parameter];
        }
        if ([db hadError]) {
            NSLog(@"❌ SQL Error\nCode: %d\nMessage: %@\n",[db lastErrorCode],[db lastErrorMessage]);
        } else {
            NSString *successLog = [NSString stringWithFormat:@"✅ Success\nSQL:\n%@\n", sql];
            if (parameter) {
                successLog = [successLog stringByAppendingFormat:@"Param:\n%@\n", parameter];
            }
            NSLog(@"%@", successLog);
        }
    };
    [TPDBManager update:saveBlock type:messageType waitUntilDone:waitUntilDone result:self.updateResult];
}
- (void)update:(NSDictionary *)dic ByPrimeKeyValue:(id)primeValue messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    if (!dic || dic.count == 0) return;
    // 删除无用的key
    NSDictionary *tempDic = [self removeUnusedKeyForUpdateForDictionary:dic];
    NSString *sql = [self generateUpdateSQL:tempDic primeKeyValue:primeValue];
    [self update:sql parameter:tempDic messageType:messageType waitUntilDone:waitUntilDone];
}
- (void)excute:(NSString *)sql messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    [self update:sql parameter:nil messageType:messageType waitUntilDone:waitUntilDone];
}
- (void)updateTransaction:(NSArray *)sqlArr messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    NSLog(@"🚀 SQL:\n%@\n", sqlArr);
    void (^block)(FMDatabase *db, BOOL *rollback) = ^(FMDatabase *db,BOOL *rollback) {
        for (NSString *sql in sqlArr) {
            [db executeUpdate:sql];
        }
        if ([db hadError]) {
            NSLog(@"❌ SQL Error\nCode: %d\nMessage: %@\n",[db lastErrorCode],[db lastErrorMessage]);
        } else {
            NSLog(@"✅ Success\nSQL:\n%@\n", sqlArr);
        }
    };
    [TPDBManager update:block type:messageType waitUntilDone:waitUntilDone result:self.updateResult];
}

#pragma mark----------------- Query -----------------
- (id)search:(NSDictionary *)dic messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    if (!dic) return nil;
    NSString *sql = [self generateQuerySQLWithDictionary:dic];
    return [TPDBManager query:sql param:dic type:messageType waitUntilDone:waitUntilDone];
}
- (id)searchWithSQL:(NSString *)sql messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    return [TPDBManager query:sql param:nil type:messageType waitUntilDone:waitUntilDone];
}
- (id)searchWithSQL:(NSString *)sql parameter:(NSDictionary *)parameter messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    return [TPDBManager query:sql param:parameter type:messageType waitUntilDone:waitUntilDone];
}
#pragma mark----------------- Delete -----------------
- (void)deleteByPrimeKey:(id)primeValue messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    NSString *primeKey = [TPDBTableMap.tablesMap[self.tableName] objectAtIndex:0];
    if (!primeKey || !primeValue) {
        return;
    }
    NSDictionary *param = [NSDictionary dictionaryWithObject:primeValue forKey:primeKey];
    [self deleteByParam:param messageType:messageType waitUntilDone:waitUntilDone];
}
- (void)deleteByParam:(id)param messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone {
    NSString *sql;
    if ([param isKindOfClass:NSArray.class] || [param isKindOfClass:NSMutableArray.class]) {
        sql = [self generateDeleteSQLWithDictionary:[param lastObject]];
    } else {
        sql = [self generateDeleteSQLWithDictionary:param];
    }
    [self update:sql parameter:param messageType:messageType waitUntilDone:waitUntilDone];
}
#pragma mark----------------- Private method -----------------
/// 生成 INSERT OR IGNORE INTO 语句
- (NSString *)generateAddOrIgnoreSQL {
    NSString *columns = [TPDBTableMap.tablesInsertSQLMap valueForKey:self.tableName];
    NSString *dataNames = [TPDBTableMap.tablesInsertDataMap valueForKey:self.tableName];
    return [NSString stringWithFormat:@"INSERT OR IGNORE INTO %@(%@) VALUES(%@)", self.tableName, columns, dataNames];
}

/// 生成 REPLACE INTO 语句
- (NSString *)generateAddOrUpdateSQL {
    NSString *columns = [TPDBTableMap.tablesInsertSQLMap valueForKey:self.tableName];
    NSString *dataNames = [TPDBTableMap.tablesInsertDataMap valueForKey:self.tableName];
    return [NSString stringWithFormat:@"REPLACE INTO %@(%@) VALUES(%@)", self.tableName, columns, dataNames];
}
/// 字典 生成 更新SQL语句  eg: @"name = :name , age = :age"
- (NSString *)generateUpdateSQLWithDictionary:(NSDictionary *)dic {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:dic.count];
    for (NSString *key in dic.allKeys) {
        [array addObject:[NSString stringWithFormat:@"%@ = :%@ ", key, key]];
    }
    return [array componentsJoinedByString:@" , "];
}
- (NSString *)generateUpdateSQL:(NSDictionary *)dic primeKeyValue:(id)primeValue {
    NSString *columns = [self generateUpdateSQLWithDictionary:dic];
    if ([primeValue isKindOfClass:NSDictionary.class]) {
        NSMutableString *sql = [NSMutableString stringWithString:@"UPDATE %@ SET %@"];
        if ([primeValue count] > 0) {
            NSMutableArray *conds = @[].mutableCopy;
            [primeValue enumerateKeysAndObjectsUsingBlock:^(NSString *key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [conds addObject:[NSString stringWithFormat:@" %@ = '%@' ", key, obj]];
            }];
            [sql appendString:@" WHERE "];
            [sql appendString:[conds componentsJoinedByString:@" AND "]];
        }
        return [NSString stringWithFormat:sql, self.tableName, columns];
    }
    NSString *updateSQL = [primeValue isKindOfClass:NSString.class]
    ? @"UPDATE %@ SET %@ WHERE %@ = '%@'"
    : @"UPDATE %@ SET %@ WHERE %@ = %@";
    return [NSString stringWithFormat:updateSQL, self.tableName, columns, [TPDBTableMap.tablesMap[self.tableName] objectAtIndex:0], primeValue];
}

/// 通过字典 生成 查询SQL语句
- (NSString *)generateQuerySQLWithDictionary:(NSDictionary *)dictionary {
    NSString *condition = @"0 = 0";
    for (NSString *key in dictionary.allKeys) {
        condition = [condition stringByAppendingFormat:@" AND %@ = (:%@)", key, key];
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@ WHERE ( %@ ) ", self.tableName, condition];
    return sql;
}

/// 字典 生成 删除SQL语句
- (NSString *)generateDeleteSQLWithDictionary:(NSDictionary *)dictionary {
    NSString *condition = @"0 = 0";
    if (dictionary != nil && dictionary.count) {
        for (NSString *key in dictionary.allKeys) {
            condition = [condition stringByAppendingFormat:@" AND %@ = (:%@)", key, key];
        }
    }
    return [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@", self.tableName, condition];
}

/// 删除参数中未使用的key
/// - Parameter arg: 操作传递的参数
- (id)removeUnusedKey:(id)arg {
    if (!arg) return nil;
    if ([arg isKindOfClass:NSArray.class] || [arg isKindOfClass:NSMutableArray.class]) {
        NSMutableArray *argArray = @[].mutableCopy;
        for (NSDictionary *dictionary in arg) {
            [argArray addObject:[self removeUnusedKey:dictionary]];
        }
        return argArray;
    }
    return [self removeUnusedKeyFromDictionary:arg];
}

- (NSDictionary *)removeUnusedKeyFromDictionary:(NSDictionary *)dictionary {
    NSArray *columns = [TPDBTableMap.tablesMap valueForKey:self.tableName];
    NSMutableDictionary *mDic = @{}.mutableCopy;
    for (NSString *column in columns) {
        NSString *key;
        if (!dictionary[column]) {
            key = [column substringFromIndex:[column rangeOfString:self.tableName].length];
        } else {
            key = column;
        }
        id obj = [dictionary valueForKey:key];
        [mDic setValue:obj ? ([obj isKindOfClass:NSDictionary.class] ? [obj tp_modelToJSONString] : obj) : NSNull.null forKey:column];
    }
    return mDic.copy;
}

- (NSDictionary *)removeUnusedKeyForUpdateForDictionary:(NSDictionary *)dictionary {
    NSArray *columns = [TPDBTableMap.tablesMap valueForKey:self.tableName];
    NSMutableDictionary *mDic = @{}.mutableCopy;
    for (NSString *column in columns) {
        NSString *key;
        if (!dictionary[column]) {
            key = [column substringFromIndex:[column rangeOfString:self.tableName].length];
        } else {
            key = column;
        }
        id obj = [dictionary valueForKey:key];
        if (obj) {
            [mDic setValue:obj forKey:column];
        }
    }
    return mDic.copy;
}

@end
