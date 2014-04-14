//
//  LTCDemoAppDelegate.m
//  LTCDemoApp
//
//  
//

#import "LTCDemoAppDelegate.h"
#import "LTCDemoViewController.h"
#import <LongTermCache/LongTermCache.h>

@implementation LTCDemoAppDelegate

- (id)init {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)dealloc {
    self.window = nil;
    self.viewController = nil;
    self.cache = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark UIApplicationDelegate

- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%d", app.applicationState);
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];

    self.cache = [LongTermCache defaultCache];
    
    self.viewController = [[[LTCDemoViewController alloc] initWithNibName:@"LTCDemoViewController" bundle:nil] autorelease];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)app {
    NSLog(@"%s", __PRETTY_FUNCTION__);

    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
 }


- (void)applicationDidEnterBackground:(UIApplication *)app {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    __block NSInteger bgTask = UIBackgroundTaskInvalid;
    
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_cache gc];
        
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    });

}


- (void)applicationWillEnterForeground:(UIApplication *)app {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)app {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)app {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
