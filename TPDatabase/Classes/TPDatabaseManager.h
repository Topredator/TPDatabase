//
//  TPDatabaseManager.h
//  TPDatabase
//
//  Created by Topredator on 2024/11/23.
//

#import <Foundation/Foundation.h>
#import "TPDatabaseConfig.h"
#import <FMDB/FMDB.h>
#import "TPDBModuleProtocol.h"


#define TPDBManager  TPDatabaseManager.manager

/// 数据库管理类
/// 分类为2中操作：
/// 1、一切查询 走query方法
/// 2、一切增删改 走update方法
@interface TPDatabaseManager : NSObject
/// 模块数组
@property (nonatomic, copy) NSArray *moduleArray;
@property (nonatomic, strong, readonly) TPDatabaseConfig *config;
+ (instancetype)manager;
- (void)setConfiguration:(TPDatabaseConfig *)configuration;

/// 同步 - 向所有路由发送回调结果
- (void)callback:(id)result type:(NSInteger)type;
/// 异步 - 向所有路由发送回调结果
- (void)asyncCallback:(id)result type:(NSInteger)type;

/// 数据查询操作
/// - Parameters:
///   - block: FMDB 执行回调
///   - type: 消息类型
///   - waitUnilDone: 是否同步等待
- (id)query:(id (^)(FMDatabase *db))block type:(NSInteger)type waitUntilDone:(BOOL)waitUnilDone;
- (id)query:(id (^)(FMDatabase *db))block type:(NSInteger)type;
/// 数据查询操作
/// - Parameters:
///   - sql: sql语句
///   - param: 参数
///   - type: 消息类型
///   - waitUnilDone: 是否同步等待
- (id)query:(NSString *)sql param:(NSDictionary *)param type:(NSInteger)type waitUntilDone:(BOOL)waitUnilDone;
- (id)query:(NSString *)sql param:(NSDictionary *)param type:(NSInteger)type;


/// 数据更新操作
/// - Parameters:
///   - block: FMDB执行回调
///   - type: 消息类型
///   - waitUnilDone: 是否同步等待
///   - result: 结果 (可空)
- (void)update:(void (^)(FMDatabase *db, BOOL *rollback))block type:(NSInteger)type waitUntilDone:(BOOL)waitUnilDone result:(id)result;
@end


