//
//  LTCDemoAppDelegate.h
//  LTCDemoApp
//
//  
//

#import <UIKit/UIKit.h>

@class LTCDemoViewController;
@class LongTermCache;

@interface LTCDemoAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) LTCDemoViewController *viewController;

@property (strong, nonatomic) LongTermCache *cache;
@end
