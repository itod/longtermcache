//
//  LongTermCacheEvictionPolicy.h
//  LongTermCache
//
//  
//

#import <Foundation/Foundation.h>

@class LongTermCache;

/*!
    @protocol   LongTermCacheEvictionPolicy
    @details    You may provide a custom implemenation this protocol to control a cache's eviction policy. But do not call the methods here directly. 
                They are designed to be called only by `LongTermCache` objects. Your implementation need not be thread safe. 
                The calling `LongTermCache` will ensure thread safety.
*/
@protocol LongTermCacheEvictionPolicy <NSObject>
- (NSArray *)cache:(LongTermCache *)cache pathsForFilesToEvictFromPaths:(NSArray *)inPaths;
- (BOOL)cache:(LongTermCache *)cache shouldEvictFileAtPath:(NSString *)path;
- (BOOL)cache:(LongTermCache *)cache shouldEvictFileWithAttributes:(NSDictionary *)attrs;
- (NSUInteger)maxNumberOfItemsAllowedInCache:(LongTermCache *)cache;

// returns +1, 'new' rule
- (NSDate *)newExpiryDateForItemInCache:(LongTermCache *)cache;
@end

