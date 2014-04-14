//
//  LongTermCacheEvictionPolicyDefault.m
//
//  
//

#import "LongTermCacheEvictionPolicyDefault.h"
#import "LTCUtils.h"

#define ONE_WEEK_IN_SECS 604800

#define DEFAULT_TIME_TO_LIVE ONE_WEEK_IN_SECS

#define MAX_NUM_FILES 20

#define FILE_PATH @"__y_file_path__"

@interface LongTermCacheEvictionPolicyDefault ()
// utility
- (BOOL)isFileOutOfDate:(NSDictionary *)attrs;
- (NSMutableArray *)cache:(LongTermCache *)cache pathsForFilesToEvictWhenOverMaxNumFilesFromPaths:(NSArray *)inPaths;
@end

@implementation LongTermCacheEvictionPolicyDefault

#pragma mark -
#pragma mark LongTermCacheEvictionPolicy

// returns +1, 'new' rule
- (NSDate *)newExpiryDateForItemInCache:(LongTermCache *)cache {
    NSDate *d = [[NSDate alloc] initWithTimeIntervalSinceNow:ONE_WEEK_IN_SECS];
    return d;
}


- (NSArray *)cache:(LongTermCache *)cache pathsForFilesToEvictFromPaths:(NSArray *)inPaths {
    NSMutableArray *result = [NSMutableArray array];
    
    NSUInteger numFiles = [inPaths count];
    if (numFiles > MAX_NUM_FILES) {
        [result addObjectsFromArray:[self cache:cache pathsForFilesToEvictWhenOverMaxNumFilesFromPaths:inPaths]];
    } else if (numFiles > 0) {
        for (NSString *path in inPaths) {
            if ([self cache:cache shouldEvictFileAtPath:path]) {
                NSAssert(path, @"");
                if (path) [result addObject:path]; // defensive check
            }
        }
    }
    
    return result;
}


- (BOOL)cache:(LongTermCache *)cache shouldEvictFileAtPath:(NSString *)path {
    NSParameterAssert([path length]);
    if (!path) return NO;
    
    NSFileManager *mgr = cache.fileManager;
    NSError *err = nil;
    NSDictionary *attrs = [mgr attributesOfItemAtPath:path error:&err];
    if (!attrs) {
        return NO;
    }
    
    BOOL result = [self cache:cache shouldEvictFileWithAttributes:attrs];
    return result;
}


- (BOOL)cache:(LongTermCache *)cache shouldEvictFileWithAttributes:(NSDictionary *)attrs {
    NSParameterAssert([attrs count]);

    BOOL result = [self isFileOutOfDate:attrs];
    return result;
}


- (NSUInteger)maxNumberOfItemsAllowedInCache:(LongTermCache *)cache {
    return MAX_NUM_FILES;
}


#pragma mark -
#pragma mark Utility

- (BOOL)isFileOutOfDate:(NSDictionary *)attrs {
    NSParameterAssert([attrs count]);
    if (!attrs) return NO;

    NSDate *modDate = [attrs fileModificationDate];
    NSAssert(modDate, @"");
    
    NSTimeInterval diff = [modDate timeIntervalSinceNow];
    BOOL result = diff > DEFAULT_TIME_TO_LIVE;
    return result;
}


- (NSArray *)cache:(LongTermCache *)cache pathsForFilesToEvictWhenOverMaxNumFilesFromPaths:(NSArray *)inPaths {
    
    // first, gather all attributes from all files
    NSMutableArray *allAttrs = [NSMutableArray arrayWithCapacity:[inPaths count]];
    
    for (NSString *path in inPaths) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:[cache.fileManager attributesOfItemAtPath:path error:nil]];
        
        if ([attrs count]) {
            // and put each file's file path in its attrs dict too, for convenience
            attrs[FILE_PATH] = path;
            [allAttrs addObject:attrs];
        }
    }
    
    // then sort by mod date. oldest first.
    //NSLog(@"before %@", allAttrs);
    [allAttrs sortUsingComparator:^NSComparisonResult(NSDictionary *attrs1, NSDictionary *attrs2) {
        NSDate *modDate1 = [attrs1 fileModificationDate];
        NSDate *modDate2 = [attrs2 fileModificationDate];
        
        NSComparisonResult result = [modDate1 compare:modDate2];
        
        // (if mod date is same, use File system number instead).
        if (NSOrderedSame == result) {
            id num1 = attrs1[NSFileSystemFileNumber];
            id num2 = attrs2[NSFileSystemFileNumber];
            
            result = [num1 compare:num2];
        }
        
        return result;
    }];
    //NSLog(@"after %@", allAttrs);
    
    // then return oldest (first) half (to be removed)
    NSRange r = NSMakeRange(0, MAX_NUM_FILES);
    NSArray *oldestAttrs = [allAttrs subarrayWithRange:r];

    // then gather just the paths of the oldest files as an array. and return the array
    NSMutableArray *oldestPaths = [NSMutableArray arrayWithCapacity:[oldestAttrs count]];
    for (NSDictionary *attrs in oldestAttrs) {
        [oldestPaths addObject:attrs[FILE_PATH]];
    }
    
    //NSLog(@"oldestPaths %@", oldestPaths);
    return [[oldestPaths copy] autorelease];
}

@end
