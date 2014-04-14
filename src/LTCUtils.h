//
//  LTCUtils.h
//  LongTermCache
//
//  
//

#ifndef LongTermCache_LTCUtils_h
#define LongTermCache_LTCUtils_h

#ifdef NDEBUG
#define LTCLog(fmt, ...) (void)0
#else
#define LTCLog(fmt, ...) do { NSLog(@"LongTermCache:"); NSLog(fmt, ##__VA_ARGS__); } while (0)
#endif

#define LTCAssertNotMainThread() NSAssert1(![[NSThread currentThread] isMainThread], @"%s should never execute on the main thread", __PRETTY_FUNCTION__);

#endif
