//
//  TPDatabaseConfig.m
//  TPDatabase
//
//  Created by Topredator on 2024/11/23.
//

#import "TPDatabaseConfig.h"

@implementation TPDatabaseConfig
+ (instancetype)configDBName:(NSString *)name version:(NSString *)version {
    TPDatabaseConfig *config = [TPDatabaseConfig new];
    config.dbName = name;
    config.dbVersion = version;
    return config;
}
- (NSInteger)maxQueryNumber {
    if (_maxQueryNumber == 0) {
        _maxQueryNumber = 100;
    }
    return _maxQueryNumber;
}
@end
