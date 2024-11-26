//
//  TPBaseDao.h
//  TPDatabase
//
//  Created by Topredator on 2024/11/25.
//

#import <Foundation/Foundation.h>


/// 数据库操作对象基类  (提供常用的数据库操作Api)
@interface TPBaseDao : NSObject
/// 数据表名称
@property (nonatomic, copy) NSString *tableName;
/// 执行完操作进行赋值 用于路由数据传递
@property (nonatomic, strong) id updateResult;
+ (instancetype)daoWithTableName:(NSString *)tableName;

#pragma mark----------------- insert and update -----------------

/// 保存数据
/// 执行(REPLACE INTO 操作，插入的数据与主键或唯一索引冲突，先删除原有数据，再进行插入操作)
///
/// - Parameters:
///   - data: 数据 (类型: 字典/数组)
///   - messageType: 消息类型
///   - waitUtilDone: (同步)是否等待执行完成
- (void)save:(id)data messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUtilDone;


/// 保存数据
/// - Parameters:
///   - data: 数据 (类型: 字典/数组)
///   - messageType: 消息类型
///   - waitUtilDone: 是否同步等待
///   - ignore:
///   - - YES: 插入数据与主键或唯一索引冲突时，忽略此次操作
///   - - NO: 执行REPLACE INTO 操作，插入的数据与主键或唯一索引冲突，先删除原有数据，再进行插入操作
- (void)save:(id)data messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUtilDone igoner:(BOOL)ignore;


/// 更新数据
/// - Parameters:
///   - sql: sql语句
///   - parameter: 参数
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (void)update:(NSString *)sql parameter:(id)parameter messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;

/// 更新数据
/// - Parameters:
///   - dic: 参数
///   - primeValue: 主键的值
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (void)update:(NSDictionary *)dic ByPrimeKeyValue:(id)primeValue messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;


/// 执行sql语句
/// - Parameters:
///   - sql: sql语句
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (void)excute:(NSString *)sql messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;


/// 支持 事务的更新、删除
/// - Parameters:
///   - sqlArr: sql语句数组
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (void)updateTransaction:(NSArray *)sqlArr messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;
#pragma mark----------------- query -----------------

/// 查询数据
/// - Parameters:
///   - dic: 参数
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (id)search:(NSDictionary *)dic messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;

/// 通过SQL语句查询数据
/// - Parameters:
///   - sql: sql语句
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (id)searchWithSQL:(NSString *)sql messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;

/// 通过SQL语句查询数据
/// - Parameters:
///   - sql: sql语句
///   - parameter: 参数
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (id)searchWithSQL:(NSString *)sql parameter:(NSDictionary *)parameter messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;

#pragma mark----------------- delete -----------------

/// 通过 主键的值 删除数据
/// - Parameters:
///   - primeValue: 主键的值
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (void)deleteByPrimeKey:(id)primeValue messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;

/// 删除数据
/// - Parameters:
///   - data: 参数
///   - messageType: 消息类型
///   - waitUntilDone: 是否同步等待
- (void)deleteByParam:(id)param messageType:(NSInteger)messageType waitUntilDone:(BOOL)waitUntilDone;


#pragma mark----------------- Addition method -----------------
/// 生成 INSERT OR IGNORE INTO 语句
- (NSString *)generateAddOrIgnoreSQL;
/// 生成 插入或更新 SQL语句
- (NSString *)generateAddOrUpdateSQL;
/// 参数、主键的值 生成 更新SQL语句
/// - Parameters:
///   - dic: 参数
///   - primeValue: 主键的值
- (NSString *)generateUpdateSQL:(NSDictionary *)dic primeKeyValue:(id)primeValue;
/// 字典 生成 查询SQL语句
- (NSString *)generateQuerySQLWithDictionary:(NSDictionary *)dictionary;
/// 字典 生成 更新SQL语句  eg: @"name = :name , age = :age"
- (NSString *)generateUpdateSQLWithDictionary:(NSDictionary *)dic;

/// 删除参数中无用的key
/// - Parameter arg: 参数 (类型 字典/数组)
- (id)removeUnusedKey:(id)arg;

@end


