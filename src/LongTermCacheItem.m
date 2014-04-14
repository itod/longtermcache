//
//  LongTermCacheItem.m
//
//  
//

#import "LongTermCacheItem.h"

@interface LongTermCacheItem ()
@property (nonatomic, retain, readwrite) id <NSCoding>object;
@property (nonatomic, retain, readwrite) NSDate *expiryDate;
@end

@implementation LongTermCacheItem

+ (LongTermCacheItem *)cacheItemWithObject:(id <NSCoding>)obj expiryDate:(NSDate *)expDate {
    NSParameterAssert(obj);
    
    LongTermCacheItem *item = [[[LongTermCacheItem alloc] init] autorelease];
    item.object = obj;
    item.expiryDate = expDate;
    
    return item;
}


- (id)initWithCoder:(NSCoder *)decoder {
    self.object = [decoder decodeObjectForKey:@"object"];
    self.expiryDate = [decoder decodeObjectForKey:@"expiryDate"];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_object forKey:@"object"];
    [encoder encodeObject:_expiryDate forKey:@"expiryDate"];
}


- (void)dealloc {
    self.object = nil;
    self.expiryDate = nil;
    [super dealloc];
}

@end