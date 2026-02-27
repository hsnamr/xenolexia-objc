//
//  XLAboutWindowController.h
//  Xenolexia
//
//  About Xenolexia window: app info, logo, links, acknowledgments, credits

#import <AppKit/AppKit.h>

@protocol XLAboutWindowDelegate <NSObject>
- (void)aboutWindowDidClose;
@end

@interface XLAboutWindowController : NSWindowController {
    id<XLAboutWindowDelegate> _delegate;
    NSImageView *_logoImageView;
    NSScrollView *_scrollView;
    NSView *_contentView;
}

@property (nonatomic, assign) id<XLAboutWindowDelegate> delegate;

@end
