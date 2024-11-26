//
//  TPDatabaseRouter.m
//  TPDatabase
//
//  Created by Topredator on 2024/11/23.
//

#import "TPDBRouter.h"
#import "TPDBTaskMessage.h"
#import "TPDatabaseManager.h"

static NSMutableArray <TPDatabaseMessageHandler> *globalRoutes = nil;

static TPDBRouter *router = nil;
@implementation TPDBRouter

+ (void)addRoute:(id<TPDatabaseMessageHandler>)route {
    if (!globalRoutes) globalRoutes = @[].mutableCopy;
    if ([globalRoutes containsObject:route]) return;
    [globalRoutes addObject:route];
}
+ (void)removeRoute:(id)route {
    if ([route conformsToProtocol:@protocol(TPDatabaseMessageHandler)]) {
        [globalRoutes removeObject:route];
    }
}
+ (BOOL)findRoute:(Class)routeClass {
    NSInteger count = globalRoutes.count;
    for (NSInteger i = count - 1; i >= 0; i --) {
        id route = [globalRoutes objectAtIndex:i];
        if ([[route class].description isEqualToString:routeClass.description]) {
            return YES;
        }
    }
    return NO;
}
+ (void)sendMessageToRoutes:(NSInteger)messageType result:(NSInteger)result argument:(id)argument {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger count = globalRoutes.count;
        for (NSInteger i = count - 1; i >= 0; i--) {
            id <TPDatabaseMessageHandler> route = globalRoutes[i];
            BOOL isDone = [route handleMessage:messageType result:result argument:argument];
            if (isDone) {
                break;
            }
        }
    });
}

+ (void)sendTaskMessage:(NSInteger)messageType {
    [self sendTaskMessage:messageType argument:nil];
}
+ (void)sendTaskMessage:(NSInteger)messageType argument:(id)argument {
    dispatch_async(dispatch_get_main_queue(), ^{
        TPDBTaskMessage *taskMsg = [TPDBTaskMessage taskMessageWithType:messageType argument:argument];
        for (Class class in TPDatabaseManager.manager.moduleArray) {
            if ([class respondsToSelector:@selector(handleTaskMessage:)] && [class handleTaskMessage:taskMsg]) {
                return;
            }
        }
    });
}
+ (id)syncSendTaskMessage:(NSInteger)messageType argument:(id)argument {
    TPDBTaskMessage *taskMsg = [TPDBTaskMessage taskMessageWithType:messageType argument:argument];
    for (Class class in TPDatabaseManager.manager.moduleArray) {
        if ([class respondsToSelector:@selector(handleTaskMessage:)] && [class handleTaskMessage:taskMsg]) {
            return taskMsg.result;
        }
    }
    return nil;
}
@end
