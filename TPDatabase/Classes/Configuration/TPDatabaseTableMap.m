//
//  TPDatabaseTableMap.m
//  TPDatabase
//
//  Created by Topredator on 2024/11/23.
//

#import "TPDatabaseTableMap.h"

static TPDatabaseTableMap *mapModel = nil;
@implementation TPDatabaseTableMap
@synthesize tablesMap = _tablesMap;
@synthesize tablesInsertSQLMap = _tablesInsertSQLMap;
@synthesize tablesInsertDataMap = _tablesInsertDataMap;

+ (instancetype)tableMap {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mapModel = [TPDatabaseTableMap new];
    });
    return mapModel;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _tablesMap = @{}.mutableCopy;
        _tablesInsertSQLMap = @{}.mutableCopy;
        _tablesInsertDataMap = @{}.mutableCopy;
    }
    return self;
}
/// 映射存储 表数据
- (void)setMap:(NSString *)tableName datas:(NSArray *)datas {
    if (!tableName || !datas.count) return;
    
    NSString *columns = @"";
    NSString *dicColumns = @"";
    for (NSString *string in datas) {
        columns = [columns stringByAppendingFormat:@"%@,",string];
        dicColumns = [dicColumns stringByAppendingFormat:@":%@,",string];
    }
    columns = [columns substringToIndex:[columns length] - 1];
    dicColumns = [dicColumns substringToIndex:[dicColumns length] - 1];
    
    
    [_tablesMap setValue:datas forKey:tableName];
    [_tablesInsertSQLMap setValue:columns forKey:tableName];
    [_tablesInsertDataMap setValue:dicColumns forKey:tableName];
}
@end
