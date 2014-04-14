//
//  LTCDefaultLongTermCacheTest.m
//  LTCDemoAppTests
//
//  
//

#import "LTCDefaultLongTermCacheTest.h"

@interface LongTermCache (UnitTest)
- (NSArray *)allFilePaths;
@property (nonatomic, retain, readonly) id <LongTermCacheEvictionPolicy>evictionPolicy;
@end

@implementation LTCDefaultLongTermCacheTest

- (void)setUp {
    [super setUp];
    
    // create cache with default eviction policy, file manager, and dir path
    self.cache = [LongTermCache defaultCache];
}


- (void)tearDown {
    [_cache clear];
    
    self.cache = nil;
    
    [super tearDown];
}


- (void)testDefaultCacheSetter {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    
    [_cache setObject:foo forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNotNil(result);
    AssertEqualObjects(foo, result);
}


- (void)testDefaultCacheClear {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    
    [_cache setObject:foo forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNotNil(result);
    AssertEqualObjects(foo, result);
    
    [_cache clear];
    
    result = [_cache objectForKey:key];
    
    AssertNil(result);
}


- (void)testDefaultExpiryDateCacheSetter {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    
    [_cache setObject:foo withExpiryDate:nil forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNotNil(result);
    AssertEqualObjects(foo, result);
}


- (void)testExpiryDateInPast {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    NSDate *recentPast = [NSDate dateWithTimeIntervalSinceNow:-1.0];
    
    [_cache setObject:foo withExpiryDate:recentPast forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNil(result);
}


- (void)testExpiryDateInFuture {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    NSDate *oneMinFromNow = [NSDate dateWithTimeIntervalSinceNow:60.0];
    
    [_cache setObject:foo withExpiryDate:oneMinFromNow forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNotNil(result);
    AssertEqualObjects(foo, result);
}


- (void)testExpiration {
    AssertNotNil(_cache);
    
    NSString *key = @"aKey";
    NSString *foo = @"foo";
    NSDate *twoSecsFromNow = [NSDate dateWithTimeIntervalSinceNow:2.0];
    
    [_cache setObject:foo withExpiryDate:twoSecsFromNow forKey:key];
    id result = [_cache objectForKey:key];
    
    AssertNotNil(result);
    AssertEqualObjects(foo, result);
    
    sleep(2);

    result = [_cache objectForKey:key];

    AssertNil(result);

    sleep(1);
    
    result = [_cache objectForKey:key];
    
    AssertNil(result);
}


- (void)testOverMaxItemsWithDelay {
    AssertNotNil(_cache);
    
    NSUInteger maxNumItems = [_cache.evictionPolicy maxNumberOfItemsAllowedInCache:_cache];
    AssertTrue(NSNotFound != maxNumItems);
    AssertTrue(0 != maxNumItems);
    
    NSUInteger totalNumItems = maxNumItems * 2.0;
    
    for (NSInteger i = 0; i < totalNumItems; i++) {
        NSNumber *val = [NSNumber numberWithInteger:i];
        NSString *key = [val stringValue];
        [_cache setObject:val withExpiryDate:nil forKey:key];
        sleep(1);
    }
    AssertEquals(totalNumItems, [[_cache allFilePaths] count]);
    
    [_cache gc];
    AssertEquals(maxNumItems, [[_cache allFilePaths] count]);
    
    for (NSInteger i = 0; i < maxNumItems; i++) {
        NSNumber *val = [NSNumber numberWithInteger:i];
        NSString *key = [val stringValue];
        id obj = [_cache objectForKey:key];
        AssertNil(obj);
    }

    for (NSInteger i = maxNumItems; i < totalNumItems; i++) {
        NSNumber *val = [NSNumber numberWithInteger:i];
        NSString *key = [val stringValue];
        id obj = [_cache objectForKey:key];
        AssertNotNil(obj);
    }
}


- (void)testOverMaxItemsWithoutDelay {
    AssertNotNil(_cache);
    
    NSUInteger maxNumItems = [_cache.evictionPolicy maxNumberOfItemsAllowedInCache:_cache];
    AssertTrue(NSNotFound != maxNumItems);
    AssertTrue(0 != maxNumItems);
    
    NSUInteger totalNumItems = maxNumItems * 2.0;
    
    for (NSInteger i = 0; i < totalNumItems; i++) {
        NSNumber *val = [NSNumber numberWithInteger:i];
        NSString *key = [val stringValue];
        [_cache setObject:val withExpiryDate:nil forKey:key];
        //sleep(1);
    }
    AssertEquals(totalNumItems, [[_cache allFilePaths] count]);
    
    [_cache gc];
    AssertEquals(maxNumItems, [[_cache allFilePaths] count]);
    
    for (NSInteger i = 0; i < maxNumItems; i++) {
        NSNumber *val = [NSNumber numberWithInteger:i];
        NSString *key = [val stringValue];
        id obj = [_cache objectForKey:key];
        AssertNil(obj);
    }
    
    for (NSInteger i = maxNumItems; i < totalNumItems; i++) {
        NSNumber *val = [NSNumber numberWithInteger:i];
        NSString *key = [val stringValue];
        id obj = [_cache objectForKey:key];
        AssertNotNil(obj);
    }
}

@end
