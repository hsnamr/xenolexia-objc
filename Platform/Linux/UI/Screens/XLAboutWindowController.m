//
//  XLAboutWindowController.m
//  Xenolexia
//
//  About Xenolexia window: app logo, version, description, links, acknowledgments, credits

#import "XLAboutWindowController.h"
#import <objc/runtime.h>

static NSString *const kAppVersion = @"1.0.0";
static NSString *const kBuildNumber = @"1";

static NSDictionary *kLinks(void) {
    return @{
        @"privacy": @"https://xenolexia.app/privacy",
        @"terms": @"https://xenolexia.app/terms",
        @"support": @"mailto:support@xenolexia.app",
        @"github": @"https://github.com/hsnamr/xenolexia-electron",
    };
}

static NSArray *kAcknowledgments(void) {
    return @[
        @{@"name": @"React Native", @"url": @"https://reactnative.dev"},
        @{@"name": @"Zustand", @"url": @"https://zustand-demo.pmnd.rs"},
        @{@"name": @"React Navigation", @"url": @"https://reactnavigation.org"},
        @{@"name": @"LibreTranslate", @"url": @"https://libretranslate.com"},
        @{@"name": @"FrequencyWords", @"url": @"https://github.com/hermitdave/FrequencyWords"},
        @{@"name": @"Electron", @"url": @"https://www.electronjs.org"},
        @{@"name": @"epubjs", @"url": @"https://github.com/futurepress/epub.js"},
    ];
}

@interface XLAboutWindowController ()
- (void)buildContent;
- (void)openURL:(NSString *)urlString;
- (NSButton *)linkButtonWithTitle:(NSString *)title icon:(NSString *)icon action:(SEL)sel urlKey:(NSString *)urlKey;
@end

@implementation XLAboutWindowController

- (instancetype)init {
    self = [super initWithWindowNibName:nil];
    if (self) {
        _delegate = nil;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:self.window];
    [self.window setTitle:@"About Xenolexia"];
    [self.window setContentSize:NSMakeSize(420, 560)];
    [self.window setMinSize:NSMakeSize(360, 400)];
    [self buildContent];
}

- (void)buildContent {
    NSView *windowContent = [self.window contentView];
    CGFloat width = [windowContent bounds].size.width;
    CGFloat y = 24;
    CGFloat padding = 24.0;
    CGFloat contentWidth = width - 2 * padding;

    _scrollView = [[NSScrollView alloc] initWithFrame:[windowContent bounds]];
    [_scrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_scrollView setHasVerticalScroller:YES];
    [_scrollView setHasHorizontalScroller:NO];
    [_scrollView setAutohidesScrollers:YES];
    [_scrollView setBorderType:NSNoBorder];
    [_scrollView setDrawsBackground:NO];

    _contentView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, contentWidth + 2 * padding, 1)];
    [_contentView setFlipped:YES];
    [_contentView setAutoresizingMask:NSViewMinYMargin];

    /* App logo */
    NSImage *logoImage = [NSImage imageNamed:@"app_logo"];
    if (!logoImage) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *logoPath = [bundle pathForResource:@"app_logo" ofType:@"png"];
        if (logoPath) {
            logoImage = [[[NSImage alloc] initWithContentsOfFile:logoPath] autorelease];
        }
    }
    if (logoImage) {
        _logoImageView = [[NSImageView alloc] initWithFrame:NSMakeRect((contentWidth - 80) / 2 + padding, y, 80, 80)];
        [_logoImageView setImage:logoImage];
        [_logoImageView setImageScaling:NSImageScaleProportionallyUpOrDown];
        [_contentView addSubview:_logoImageView];
        y += 96;
    } else {
        y += 24;
    }

    /* App name */
    NSTextField *nameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 28)];
    [nameLabel setStringValue:@"Xenolexia"];
    [nameLabel setFont:[NSFont boldSystemFontOfSize:24]];
    [nameLabel setEditable:NO];
    [nameLabel setBordered:NO];
    [nameLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [nameLabel setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:nameLabel];
    [nameLabel release];
    y += 36;

    /* Version */
    NSTextField *versionLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 18)];
    [versionLabel setStringValue:[NSString stringWithFormat:@"Version %@ (%@)", kAppVersion, kBuildNumber]];
    [versionLabel setFont:[NSFont systemFontOfSize:13]];
    [versionLabel setTextColor:[NSColor tertiaryLabelColor]];
    [versionLabel setEditable:NO];
    [versionLabel setBordered:NO];
    [versionLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [versionLabel setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:versionLabel];
    [versionLabel release];
    y += 28;

    /* Tagline */
    NSTextField *taglineLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 20)];
    [taglineLabel setStringValue:@"Learn languages through reading"];
    [taglineLabel setFont:[NSFont systemFontOfSize:14]];
    [taglineLabel setTextColor:[NSColor secondaryLabelColor]];
    [taglineLabel setEditable:NO];
    [taglineLabel setBordered:NO];
    [taglineLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [taglineLabel setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:taglineLabel];
    [taglineLabel release];
    y += 36;

    /* Description */
    NSTextField *descLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 60)];
    [descLabel setStringValue:@"Xenolexia helps you learn foreign languages naturally by replacing words in the books you read. As you encounter words in context, you build vocabulary without traditional flashcard memorization."];
    [descLabel setFont:[NSFont systemFontOfSize:13]];
    [descLabel setTextColor:[NSColor secondaryLabelColor]];
    [descLabel setEditable:NO];
    [descLabel setBordered:NO];
    [descLabel setBackgroundColor:[NSColor controlBackgroundColor]];
    [descLabel setAlignment:NSCenterTextAlignment];
    [descLabel setLineBreakMode:NSLineBreakByWordWrapping];
    [descLabel setUsesSingleLineMode:NO];
    [_contentView addSubview:descLabel];
    [descLabel release];
    y += 80;

    /* Links section */
    NSTextField *linksTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 16)];
    [linksTitle setStringValue:@"LINKS"];
    [linksTitle setFont:[NSFont boldSystemFontOfSize:11]];
    [linksTitle setTextColor:[NSColor tertiaryLabelColor]];
    [linksTitle setEditable:NO];
    [linksTitle setBordered:NO];
    [linksTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [_contentView addSubview:linksTitle];
    [linksTitle release];
    y += 28;

    NSDictionary *links = kLinks();
    NSArray *linkKeys = @[@"privacy", @"terms", @"support", @"github"];
    NSArray *linkTitles = @[@"Privacy Policy", @"Terms of Service", @"Contact Support", @"Source Code"];
    NSArray *linkIcons = @[@"🔒", @"📜", @"💬", @"💻"];
    for (NSUInteger i = 0; i < [linkKeys count]; i++) {
        NSString *title = [linkTitles objectAtIndex:i];
        NSString *icon = [linkIcons objectAtIndex:i];
        NSString *url = [links objectForKey:[linkKeys objectAtIndex:i]];
        NSButton *btn = [[NSButton alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 36)];
        [btn setTitle:[NSString stringWithFormat:@"%@  %@", icon, title]];
        [btn setBezelStyle:NSRegularSquareBezelStyle];
        [btn setBordered:NO];
        [btn setAlignment:NSLeftTextAlignment];
        [btn setTarget:self];
        [btn setAction:@selector(linkClicked:)];
        objc_setAssociatedObject(btn, "url", url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_contentView addSubview:btn];
        [btn release];
        y += 40;
    }
    y += 8;

    /* Acknowledgments */
    NSTextField *ackTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 16)];
    [ackTitle setStringValue:@"ACKNOWLEDGMENTS"];
    [ackTitle setFont:[NSFont boldSystemFontOfSize:11]];
    [ackTitle setTextColor:[NSColor tertiaryLabelColor]];
    [ackTitle setEditable:NO];
    [ackTitle setBordered:NO];
    [ackTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [_contentView addSubview:ackTitle];
    [ackTitle release];
    y += 28;

    NSTextField *ackIntro = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 20)];
    [ackIntro setStringValue:@"Built with these amazing open source projects:"];
    [ackIntro setFont:[NSFont systemFontOfSize:12]];
    [ackIntro setTextColor:[NSColor secondaryLabelColor]];
    [ackIntro setEditable:NO];
    [ackIntro setBordered:NO];
    [ackIntro setBackgroundColor:[NSColor controlBackgroundColor]];
    [_contentView addSubview:ackIntro];
    [ackIntro release];
    y += 32;

    NSArray *ack = kAcknowledgments();
    for (NSDictionary *item in ack) {
        NSString *name = [item objectForKey:@"name"];
        NSString *url = [item objectForKey:@"url"];
        NSButton *btn = [[NSButton alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 22)];
        [btn setTitle:[NSString stringWithFormat:@"• %@", name]];
        [btn setBezelStyle:NSRegularSquareBezelStyle];
        [btn setBordered:NO];
        [btn setAlignment:NSLeftTextAlignment];
        [btn setFont:[NSFont systemFontOfSize:12]];
        [[btn cell] setLineBreakMode:NSLineBreakByTruncatingTail];
        [btn setTarget:self];
        [btn setAction:@selector(ackLinkClicked:)];
        objc_setAssociatedObject(btn, "url", url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_contentView addSubview:btn];
        [btn release];
        y += 26;
    }
    y += 12;

    /* Credits */
    NSTextField *creditsTitle = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 16)];
    [creditsTitle setStringValue:@"CREDITS"];
    [creditsTitle setFont:[NSFont boldSystemFontOfSize:11]];
    [creditsTitle setTextColor:[NSColor tertiaryLabelColor]];
    [creditsTitle setEditable:NO];
    [creditsTitle setBordered:NO];
    [creditsTitle setBackgroundColor:[NSColor controlBackgroundColor]];
    [_contentView addSubview:creditsTitle];
    [creditsTitle release];
    y += 28;

    NSTextField *credits1 = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 20)];
    [credits1 setStringValue:@"Designed and developed with 📚 for language learners everywhere."];
    [credits1 setFont:[NSFont systemFontOfSize:12]];
    [credits1 setTextColor:[NSColor secondaryLabelColor]];
    [credits1 setEditable:NO];
    [credits1 setBordered:NO];
    [credits1 setBackgroundColor:[NSColor controlBackgroundColor]];
    [credits1 setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:credits1];
    [credits1 release];
    y += 28;

    NSTextField *credits2 = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 20)];
    [credits2 setStringValue:@"Special thanks to the open source community and all our early testers."];
    [credits2 setFont:[NSFont systemFontOfSize:12]];
    [credits2 setTextColor:[NSColor tertiaryLabelColor]];
    [credits2 setEditable:NO];
    [credits2 setBordered:NO];
    [credits2 setBackgroundColor:[NSColor controlBackgroundColor]];
    [credits2 setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:credits2];
    [credits2 release];
    y += 40;

    /* Footer */
    NSTextField *footer1 = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 16)];
    [footer1 setStringValue:@"© 2024 Xenolexia"];
    [footer1 setFont:[NSFont systemFontOfSize:12]];
    [footer1 setTextColor:[NSColor tertiaryLabelColor]];
    [footer1 setEditable:NO];
    [footer1 setBordered:NO];
    [footer1 setBackgroundColor:[NSColor controlBackgroundColor]];
    [footer1 setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:footer1];
    [footer1 release];
    y += 22;

    NSTextField *footer2 = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, contentWidth, 16)];
    [footer2 setStringValue:@"Made with ❤️"];
    [footer2 setFont:[NSFont systemFontOfSize:12]];
    [footer2 setTextColor:[NSColor tertiaryLabelColor]];
    [footer2 setEditable:NO];
    [footer2 setBordered:NO];
    [footer2 setBackgroundColor:[NSColor controlBackgroundColor]];
    [footer2 setAlignment:NSCenterTextAlignment];
    [_contentView addSubview:footer2];
    [footer2 release];
    y += 40;

    CGFloat totalHeight = y + 24;
    [_contentView setFrame:NSMakeRect(0, 0, contentWidth + 2 * padding, totalHeight)];
    [_scrollView setDocumentView:_contentView];
    [_contentView release];

    [windowContent addSubview:_scrollView positioned:NSWindowBelow relativeTo:nil];
    [_scrollView release];
}

- (void)linkClicked:(id)sender {
    NSString *url = objc_getAssociatedObject(sender, "url");
    if (url) {
        [self openURL:url];
    }
}

- (void)ackLinkClicked:(id)sender {
    NSString *url = objc_getAssociatedObject(sender, "url");
    if (url) {
        [self openURL:url];
    }
}

- (void)openURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url && [[NSWorkspace sharedWorkspace] respondsToSelector:@selector(openURL:)]) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)windowWillClose:(NSNotification *)notification {
    if (_delegate && [_delegate respondsToSelector:@selector(aboutWindowDidClose)]) {
        [_delegate aboutWindowDidClose];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:self.window];
    [_logoImageView release];
    [super dealloc];
}

@end
