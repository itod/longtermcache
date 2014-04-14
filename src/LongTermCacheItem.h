//
//  LongTermCacheItem.h
//
//  
//

#import <Foundation/Foundation.h>

/*!
    @class      LongTermCacheItem
    @details    This class is private to the LTC lib. Client code should not use this class.
*/
@interface LongTermCacheItem : NSObject <NSCoding>
+ (LongTermCacheItem *)cacheItemWithObject:(id <NSCoding>)obj expiryDate:(NSDate *)expDate;

@property (nonatomic, retain, readonly) id <NSCoding>object;
@property (nonatomic, retain, readonly) NSDate *expiryDate;
@end
