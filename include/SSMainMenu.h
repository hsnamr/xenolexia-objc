//
//  SSMainMenu.h
//  SmallStep
//
//  Generic desktop application menu (GNUStep/Linux, AppKit/macOS).
//  Build main menu from an array of item descriptors; supports both platforms.
//

#import <Foundation/Foundation.h>

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

#if !TARGET_OS_IPHONE

/// Descriptor for one menu item (title, action, key equivalent, optional modifier mask).
@interface SSMainMenuItem : NSObject
#if defined(GNUSTEP) && !__has_feature(objc_arc)
{
    NSString *_title;
    SEL _action;
    NSString *_keyEquivalent;
    NSUInteger _keyEquivalentModifierMask;
    id _target;  /* assign for GNUStep (no weak runtime) */
}
@property (nonatomic, assign) id target;  /* assign for GNUStep */
#else
@property (nonatomic, weak) id target;
#endif
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SEL action;
@property (nonatomic, copy) NSString *keyEquivalent;  // e.g. @"1", @"q"
@property (nonatomic, assign) NSUInteger keyEquivalentModifierMask;  // e.g. NSControlKeyMask, NSCommandKeyMask
+ (instancetype)itemWithTitle:(NSString *)title action:(SEL)action keyEquivalent:(NSString *)keyEquiv modifierMask:(NSUInteger)mask target:(nullable id)target;
@end

/// Build and install a simple app menu (one submenu with items + optional Quit).
/// Use on desktop (GNUStep/macOS) to avoid duplicating NSMenu code per app.
@interface SSMainMenu : NSObject
#if defined(GNUSTEP) && !__has_feature(objc_arc)
{
    NSString *_appName;
}
#endif

/// App name shown in menu bar (e.g. @"Xenolexia").
@property (nonatomic, copy) NSString *appName;

/// Build the main menu with one submenu containing the given items, then a separator and Quit.
/// @param items Array of SSMainMenuItem (e.g. Library, Vocabulary, Settings, ...)
/// @param quitTitle Title for Quit item (e.g. @"Quit Xenolexia")
/// @param quitKeyEquivalent e.g. @"q"
- (void)buildMenuWithItems:(NSArray<SSMainMenuItem *> *)items
                 quitTitle:(NSString *)quitTitle
         quitKeyEquivalent:(NSString *)quitKeyEquivalent;

/// Install the built menu as the app's main menu ([NSApp setMainMenu:]).
- (void)install;

@end

#endif

NS_ASSUME_NONNULL_END
