//
//  XLiOSAppDelegate.h
//  Xenolexia (iOS)
//
//  iOS (UIKit) app delegate. Forwards lifecycle to shared XLAppLogic (SSAppDelegate) and sets up window/root VC.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface XLiOSAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong, nullable) UIWindow *window;
@end

NS_ASSUME_NONNULL_END
