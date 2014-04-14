//
//  LongTermCache.h
//
//  
//

#import <Foundation/Foundation.h>
#import <LongTermCache/LongTermCacheEvictionPolicy.h>

/*!
    @class      LongTermCache
    @details    All methods are thread-safe.
*/
@interface LongTermCache : NSObject

/*!
    @brief      Shared singleton with default eviction policy, file manager, and cache dir path.
    @details    Created lazily/on-first-call.
    @result     Shared singleton cache.
*/
+ (LongTermCache *)defaultCache;

/*!
    @brief      Designated Initializer.
    @details    Designated Initializer. Params are for dependency injection
    @param      policy eviction policy to be used
    @param      fileManager file manager to be use
    @param      dirPath location of cache on disk. pass `nil` for default location in Documents directory
    @result     an initialized cache
*/
- (id)initWithEvictionPolicy:(id <LongTermCacheEvictionPolicy>)policy fileManager:(NSFileManager *)fileManager cacheDirectory:(NSString *)dirPath;

/*!
    @brief      fetch a previously cached object
    @details    Do not call on main thread
    @param      key to cache for
    @result     object previously cached for `key`
*/
- (id <NSCoding>)objectForKey:(NSString *)key;

/*!
    @brief      cache an object
    @details    Do not call on main thread. uses default expiry date (which is date returned from `-latestValidExpiryDateFromNow`)
    @param      obj to cache
    @param      key to cache for
*/
- (void)setObject:(id <NSCoding>)obj forKey:(NSString *)key;

/*!
    @brief      cache an object with a specific expiry date
    @details    Do not call on main thread.
    @param      obj to cache
    @param      expiryDate for obj in the cache
    @param      key to cache for
*/
- (void)setObject:(id <NSCoding>)obj withExpiryDate:(NSDate *)expiryDate forKey:(NSString *)key;

/*!
    @brief      run garbage collection on this cache
    @details    runs garbage collection synchronously on calling thread. objects past their individual expriy dates are evicted. don't call on main thread
*/
- (void)gc;

/*!
    @brief      run garbage collection on this cache
    @details    runs garbage collection synchronously on calling thread. objects past their individual expriy dates are evicted. don't call on main thread
*/
- (void)clear;

/*!
    @brief      
    @details    objects with dates later than this passed into `-setObject:withExpiryDate:forKey:` now will be evicted after this date regardless
    @returns    the latest date after which eviction will definitely occur for any object inserted "now".
*/
- (NSDate *)latestValidExpiryDateFromNow;
@end

/*!
    @category   LongTermCache+LongTermCacheEvictionPolicy
    @details    for use by unit tests and eviction policy only. Client code should not call.
*/
@interface LongTermCache (LongTermCacheEvictionPolicy)
@property (nonatomic, retain, readonly) NSFileManager *fileManager;
@end
