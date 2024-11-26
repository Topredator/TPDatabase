//
//  TPDBModuleProtocol.h
//  TPDatabase
//
//  Created by Topredator on 2024/11/24.
//

#import <FMDB/FMDB.h>
#import "TPDBTaskMessage.h"

/// 模块协议
@protocol TPDBModuleProtocol <NSObject>

@optional
/// 启动时数据库更新
+ (void)updateDBOnLaunching:(FMDatabase *)db;

/// 处理任务消息
+ (BOOL)handleTaskMessage:(TPDBTaskMessage *)msg;
@end
