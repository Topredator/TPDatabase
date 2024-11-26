#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "TPDatabaseConfig.h"
#import "TPDatabaseTableMap.h"
#import "TPBaseDao.h"
#import "TPDBRouter.h"
#import "TPDBTaskMessage.h"
#import "TPDatabase.h"
#import "TPDatabaseManager.h"
#import "TPDBModuleProtocol.h"

FOUNDATION_EXPORT double TPDatabaseVersionNumber;
FOUNDATION_EXPORT const unsigned char TPDatabaseVersionString[];

