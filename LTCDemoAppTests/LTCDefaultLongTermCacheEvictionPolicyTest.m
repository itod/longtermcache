//
//  LTCDefaultLongTermCacheEvictionPolicyTest.m
//  LTCDemoAppTests
//
//  
//

#import "LTCDefaultLongTermCacheEvictionPolicyTest.h"

@implementation LTCDefaultLongTermCacheEvictionPolicyTest

- (void)setUp {
    [super setUp];
    
    // create cache with default eviction policy, file manager, and dir path
    self.cache = [LongTermCache defaultCache];
}


- (void)tearDown {
    self.cache = nil;
    
    [super tearDown];
}


- (void)testDefaultCacheAccessors {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    
    [_cache setObject:foo forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNotNil(result);
    AssertEqualObjects(foo, result);
}

@end
