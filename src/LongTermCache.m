//
//  LongTermCache.m
//
//  
//

#import <LongTermCache/LongTermCache.h>
#import <CommonCrypto/CommonDigest.h>
#import "LongTermCacheEvictionPolicyDefault.h"
#import "LongTermCacheItem.h"
#import "LTCUtils.h"

static NSString *md5(NSString *str);

@interface LongTermCache ()
// setup
- (void)setUpDefaultEvictionPolicy;
- (void)setUpDefaultFileManager;
- (void)setUpDefaultCacheDirectory;

// utility
- (NSString *)filePathForKey:(NSString *)key;
- (NSString *)hashForKey:(NSString *)key;

- (LongTermCacheItem *)cacheItemWithObject:(id <NSCoding>)obj expiryDate:(NSDate *)expDate;

- (LongTermCacheItem *)unarchivedCacheItemAtPath:(NSString *)path;
- (void)archiveCacheItem:(LongTermCacheItem *)item toPath:(NSString *)path;

- (NSArray *)allFilePaths;

// garbage collection
- (void)evictFileAtPath:(NSString *)path;

@property (nonatomic, retain) id <LongTermCacheEvictionPolicy>evictionPolicy;
@property (nonatomic, retain, readwrite) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *dirPath;
@end

@implementation LongTermCache

+ (LongTermCache *)defaultCache {
    static LongTermCache *sDefaultInstance = nil;
    @synchronized(self) {
        if (!sDefaultInstance) {

#ifndef NDEBUG
            static NSInteger instanceCount = 0;
            instanceCount++;
            NSAssert(instanceCount <= 1, @"");
#endif
            
            sDefaultInstance = [[self alloc] init];
        }
    }
    return sDefaultInstance;
}


- (id)init {
    self = [self initWithEvictionPolicy:nil fileManager:nil cacheDirectory:nil];
    return self;
}


- (id)initWithEvictionPolicy:(id <LongTermCacheEvictionPolicy>)policy fileManager:(NSFileManager *)mgr cacheDirectory:(NSString *)dirPath {    
    self = [super init];
    if (self) {
        if (policy) {
            self.evictionPolicy = policy;
        } else {
            [self setUpDefaultEvictionPolicy];
        }
    
        if (mgr) {
            self.fileManager = mgr;
        } else {
            [self setUpDefaultFileManager];
        }
        
        if (dirPath) {
            self.dirPath = dirPath;
        } else {
            [self setUpDefaultCacheDirectory];
        }
    }
    return self;
}


- (void)dealloc {
    self.evictionPolicy = nil;
    self.fileManager = nil;
    self.dirPath = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (id <NSCoding>)objectForKey:(NSString *)key {
    LTCAssertNotMainThread();
    NSParameterAssert([key length]);
    NSAssert([_dirPath length], @"");

    if (!key) return nil;

    LongTermCacheItem *item = nil;
    NSString *path = [self filePathForKey:key];

    @synchronized(self) {
        BOOL shouldEvict = [self.evictionPolicy cache:self shouldEvictFileAtPath:path];
        if (shouldEvict) {
            [self evictFileAtPath:path];
        } else {
            item = [self unarchivedCacheItemAtPath:path];
            if (item && [self isCacheItemExpired:item]) {
                item = nil;
                [self evictFileAtPath:path];
            }
        }
    }
    
    id <NSCoding>obj = nil;
    if (item) {
        obj = item.object;
        NSAssert(obj, @"");
    }
    
    return obj;
}


- (void)setObject:(id <NSCoding>)obj forKey:(NSString *)key {
    [self setObject:obj withExpiryDate:nil forKey:key];
}


- (void)setObject:(id <NSCoding>)obj withExpiryDate:(NSDate *)expDate forKey:(NSString *)key {
    LTCAssertNotMainThread();
    NSParameterAssert(obj);
    NSParameterAssert([key length]);
    NSAssert([_dirPath length], @"");

    if (!obj || !key) return;
    
    NSString *path = [self filePathForKey:key];
    LongTermCacheItem *item = [self cacheItemWithObject:obj expiryDate:expDate];
    
    @synchronized(self) {
        [self archiveCacheItem:item toPath:path];
    }
}


- (NSDate *)latestValidExpiryDateFromNow {
    NSDate *expDate = [[self.evictionPolicy newExpiryDateForItemInCache:self] autorelease];
    return expDate;
}


#pragma mark -
#pragma mark Setup

- (void)setUpDefaultEvictionPolicy {
    NSAssert(!_evictionPolicy, @"");
    self.evictionPolicy = [[[LongTermCacheEvictionPolicyDefault alloc] init] autorelease];
    NSAssert(_evictionPolicy, @"");
}


- (void)setUpDefaultFileManager {
    NSAssert(!_fileManager, @"");
    self.fileManager = [NSFileManager defaultManager];
    NSAssert(_fileManager, @"");
}


- (void)setUpDefaultCacheDirectory {
    NSArray *cachesDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSAssert([cachesDir count], @"");
    
    if ([cachesDir count]) {
        NSString *docsPath = [cachesDir lastObject];
        
        self.dirPath = [docsPath stringByAppendingPathComponent:@"YLongTermCache"];
        NSAssert([_dirPath length], @"");
        
        BOOL isDir;
        if (![_fileManager fileExistsAtPath:_dirPath isDirectory:&isDir] || !isDir) {
            NSError *err = nil;
            if (![_fileManager createDirectoryAtPath:_dirPath withIntermediateDirectories:NO attributes:nil error:&err]) {
                NSAssert(0, @"could not create cache dir!");
                if (err) {
                    LTCLog(@"%@", err);
                }
            }
        }
    }
    NSAssert([_dirPath length], @"");
}


#pragma mark -
#pragma mark Utility

- (BOOL)isCacheItemExpired:(LongTermCacheItem *)item {
    NSParameterAssert(item);
    NSParameterAssert(item.expiryDate);
    
    NSTimeInterval secsSinceExpriy = [item.expiryDate timeIntervalSinceNow];
    BOOL isExpiryDatePast = secsSinceExpriy < 0.0;
    return isExpiryDatePast;
}


- (NSString *)hashForKey:(NSString *)key {
    key = [[key copy] autorelease];
    NSString *hash = md5(key);
    NSAssert([hash length], @"");
    return hash;
}


- (NSString *)filePathForKey:(NSString *)key {
    NSParameterAssert([key length]);
    NSAssert([_dirPath length], @"");
    
    NSString *hash = [self hashForKey:key];
    NSString *path = [_dirPath stringByAppendingPathComponent:hash];
    
    NSAssert([path length], @"");
    return path;
}


- (LongTermCacheItem *)cacheItemWithObject:(id <NSCoding>)obj expiryDate:(NSDate *)expDate {
    if (!expDate) {
        expDate = [[self.evictionPolicy newExpiryDateForItemInCache:self] autorelease];
    }
    LongTermCacheItem *item = [LongTermCacheItem cacheItemWithObject:obj expiryDate:expDate];
    return item;
}


- (LongTermCacheItem *)unarchivedCacheItemAtPath:(NSString *)path {
    NSParameterAssert([path length]);

    LongTermCacheItem *item = nil;
    
    NSError *err = nil;
    NSData *archive = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:&err];
    if (archive) {
        item = [NSKeyedUnarchiver unarchiveObjectWithData:archive];
    } else {
//        LTCLog(@"could not unarchive cached item at path: %@", path);
//        if (err) LTCLog(@"%@", err);
    }

    return item;
}


- (void)archiveCacheItem:(LongTermCacheItem *)item toPath:(NSString *)path {
    NSParameterAssert(item);
    NSParameterAssert([path length]);

    if (!path) return;
    
    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:item];
    NSAssert(archive, @"");
    
    if (!archive) return;
    
    NSError *err = nil;
    if (![archive writeToFile:path options:NSDataWritingAtomic error:&err]) {
        LTCLog(@"could not archive cached item to path: %@", path);
        if (err) LTCLog(@"%@", err);
    }
}


- (NSArray *)allFilePaths {
    NSError *err = nil;
    NSMutableArray *allFilePaths = nil;

    @synchronized(self) {
        NSArray *filenames = [_fileManager contentsOfDirectoryAtPath:_dirPath error:&err];

        allFilePaths = [NSMutableArray arrayWithCapacity:[filenames count]];
        for (NSString *filename in filenames) {
            NSString *path = [_dirPath stringByAppendingPathComponent:filename];
            NSAssert([path length], @"");
            if (path) [allFilePaths addObject:path];
        }
    }

    if (![allFilePaths count]) {
        if (err) {
            LTCLog(@"error finding contents of directory: %@", err);
        }
        allFilePaths = nil;
    }
    
    return [[allFilePaths copy] autorelease];
}


#pragma mark -
#pragma mark Garbage Collection

- (void)gc {
    LTCAssertNotMainThread();
    NSAssert([_dirPath length], @"");
    if (!_dirPath) return;
    
    @synchronized(self) {
        NSArray *allFilePaths = [self allFilePaths];
        if (!allFilePaths) return;
        
        NSArray *evictPaths = [self.evictionPolicy cache:self pathsForFilesToEvictFromPaths:allFilePaths];
        
        for (NSString *evictPath in evictPaths) {
            [self evictFileAtPath:evictPath];
        }
    }
}


- (void)evictFileAtPath:(NSString *)path {
    NSParameterAssert([path length]);

    NSError *err = nil;
    @synchronized(self) {
        if (![_fileManager removeItemAtPath:path error:&err]) {
            LTCLog(@"cannot evict file at path: %@", path);
            if (err) LTCLog(@"%@", err);
        }
    }
}


- (void)clear {
    NSParameterAssert([_dirPath length]);
    
    NSError *err = nil;
    @synchronized(self) {
        if (![_fileManager removeItemAtPath:_dirPath error:&err]) {
            LTCLog(@"cannot clear cache at path: %@", _dirPath);
            if (err) LTCLog(@"%@", err);
        }
        
        [self setUpDefaultCacheDirectory];
    }
}

@end

static NSString *md5(NSString *str) {
    //assert(![str isKindOfClass:[NSMutableString class]]);
    const char *cStr = [str UTF8String];
    if (!cStr) {
        NSLog(@"Error:Null string given for MD5:");
        assert(cStr);
        return @"";
    }
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (uint32_t)strlen(cStr), result);
    return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]];
}

