//
//  TPDBMessage.h
//  TPDatabase
//
//  Created by Topredator on 2024/11/24.
//

#import <Foundation/Foundation.h>

/// 任务消息模型
@interface TPDBTaskMessage : NSObject
/// 任务消息类型
@property (nonatomic, assign, readonly) NSInteger taskMsgType;
/// 消息参数
@property (nonatomic, strong, readonly) id argument;
/// 处理结果
@property (nonatomic, strong) id result;
+ (instancetype)taskMessageWithType:(NSInteger)type argument:(id)argument;
@end


