//
//  TPDatabaseRouter.h
//  TPDatabase
//
//  Created by Topredator on 2024/11/23.
//

#import <Foundation/Foundation.h>

/// 消息处理协议
@protocol TPDatabaseMessageHandler <NSObject>
/// 消息处理
/// - Parameters:
///   - messageType: 消息类型
///   - result: 特殊参数
///   - argument: 参数
- (BOOL)handleMessage:(NSInteger)messageType result:(NSInteger)result argument:(id)argument;

@end

/// 路由器
@interface TPDBRouter : NSObject
/// 添加路由
+ (void)addRoute:(id <TPDatabaseMessageHandler>)route;
/// 删除路由
+ (void)removeRoute:(id)route;

/// 通过类 查找是否存在路由
/// - Parameter routeClass: 路由对应的类
+ (BOOL)findRoute:(Class)routeClass;

/// 给所有路由发送消息
/// - Parameters:
///   - messageType: 消息类型
///   - result: 特殊参数
///   - argument: 消息参数
+ (void)sendMessageToRoutes:(NSInteger)messageType result:(NSInteger)result argument:(id)argument;



/// 发送需要处理的消息 (主线程执行)
/// - Parameter messageType: 消息类型
+ (void)sendTaskMessage:(NSInteger)messageType;

/// 发送需要处理的消息 (主线程执行)
/// - Parameters:
///   - messageType: 消息类型
///   - argument: 参数
+ (void)sendTaskMessage:(NSInteger)messageType argument:(id)argument;

+ (id)syncSendTaskMessage:(NSInteger)messageType argument:(id)argument;
@end


