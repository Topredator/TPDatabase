//
//  TPDBTaskMessage.m
//  TPDatabase
//
//  Created by Topredator on 2024/11/24.
//

#import "TPDBTaskMessage.h"


@interface TPDBTaskMessage ()
@property (nonatomic, assign) NSInteger taskMsgType;
@property (nonatomic, strong) id argument;
@end

@implementation TPDBTaskMessage
+ (instancetype)taskMessageWithType:(NSInteger)type argument:(id)argument {
    TPDBTaskMessage *taskMessage = [TPDBTaskMessage new];
    taskMessage.taskMsgType = type;
    taskMessage.argument = argument;
    return taskMessage;
}
@end
