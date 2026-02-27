//
//  XLAboutViewController.m
//  Xenolexia (iOS)
//
//  About Xenolexia screen with app_logo.png, version, description, links, acknowledgments.
//  Aligned with xenolexia-typescript/react-native-app AboutScreen.
//

#import "XLAboutViewController.h"
#import <objc/runtime.h>

#if TARGET_OS_IPHONE

static NSString *const kAppVersion = @"1.0.0";
static NSString *const kBuildNumber = @"1";

static NSDictionary *kLinks(void) {
    return @{
        @"privacy": @"https://xenolexia.app/privacy",
        @"terms": @"https://xenolexia.app/terms",
        @"support": @"mailto:support@xenolexia.app",
        @"github": @"https://github.com/xenolexia/xenolexia-react",
    };
}

static NSArray *kAcknowledgments(void) {
    return @[
        @{@"name": @"React Native", @"url": @"https://reactnative.dev"},
        @{@"name": @"Zustand", @"url": @"https://zustand-demo.pmnd.rs"},
        @{@"name": @"React Navigation", @"url": @"https://reactnavigation.org"},
        @{@"name": @"LibreTranslate", @"url": @"https://libretranslate.com"},
        @{@"name": @"FrequencyWords", @"url": @"https://github.com/hermitdave/FrequencyWords"},
    ];
}

@interface XLAboutViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@end

@implementation XLAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"About";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    [self buildUI];
}

- (void)buildUI {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.spacing = 12;
    stack.layoutMargins = UIEdgeInsetsMake(32, 0, 40, 0);
    stack.layoutMarginsRelativeArrangement = YES;

    /* App logo */
    UIImage *logoImage = [UIImage imageNamed:@"app_logo"];
    if (!logoImage) {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *logoPath = [bundle pathForResource:@"app_logo" ofType:@"png"];
        if (logoPath) {
            logoImage = [UIImage imageWithContentsOfFile:logoPath];
        }
    }
    if (logoImage) {
        UIImageView *logoView = [[UIImageView alloc] initWithImage:logoImage];
        logoView.contentMode = UIViewContentModeScaleAspectFit;
        logoView.translatesAutoresizingMaskIntoConstraints = NO;
        [logoView addConstraint:[NSLayoutConstraint constraintWithItem:logoView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:80]];
        [logoView addConstraint:[NSLayoutConstraint constraintWithItem:logoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:80]];
        [stack addArrangedSubview:logoView];
    }

    /* App name */
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = @"Xenolexia";
    nameLabel.font = [UIFont boldSystemFontOfSize:28];
    nameLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:nameLabel];

    /* Version */
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = [NSString stringWithFormat:@"Version %@ (%@)", kAppVersion, kBuildNumber];
    versionLabel.font = [UIFont systemFontOfSize:14];
    versionLabel.textColor = [UIColor tertiaryLabelColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:versionLabel];

    /* Tagline */
    UILabel *taglineLabel = [[UILabel alloc] init];
    taglineLabel.text = @"Learn languages through reading";
    taglineLabel.font = [UIFont systemFontOfSize:15];
    taglineLabel.textColor = [UIColor secondaryLabelColor];
    taglineLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:taglineLabel];

    /* Description */
    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = @"Xenolexia helps you learn foreign languages naturally by replacing words in the books you read. As you encounter words in context, you build vocabulary without traditional flashcard memorization.";
    descLabel.font = [UIFont systemFontOfSize:15];
    descLabel.textColor = [UIColor secondaryLabelColor];
    descLabel.textAlignment = NSTextAlignmentCenter;
    descLabel.numberOfLines = 0;
    [stack addArrangedSubview:descLabel];

    /* Links section */
    [stack addArrangedSubview:[self sectionTitle:@"LINKS"]];
    NSDictionary *links = kLinks();
    NSArray *linkKeys = @[@"privacy", @"terms", @"support", @"github"];
    NSArray *linkTitles = @[@"Privacy Policy", @"Terms of Service", @"Contact Support", @"Source Code"];
    NSArray *linkIcons = @[@"🔒", @"📜", @"💬", @"💻"];
    for (NSUInteger i = 0; i < [linkKeys count]; i++) {
        NSString *url = [links objectForKey:[linkKeys objectAtIndex:i]];
        NSString *title = [linkTitles objectAtIndex:i];
        NSString *icon = [linkIcons objectAtIndex:i];
        [stack addArrangedSubview:[self linkRowWithTitle:[NSString stringWithFormat:@"%@  %@", icon, title] url:url]];
    }

    /* Acknowledgments */
    [stack addArrangedSubview:[self sectionTitle:@"ACKNOWLEDGMENTS"]];
    UILabel *ackIntro = [[UILabel alloc] init];
    ackIntro.text = @"Built with these amazing open source projects:";
    ackIntro.font = [UIFont systemFontOfSize:14];
    ackIntro.textColor = [UIColor secondaryLabelColor];
    ackIntro.numberOfLines = 0;
    [stack addArrangedSubview:ackIntro];
    for (NSDictionary *item in kAcknowledgments()) {
        [stack addArrangedSubview:[self linkRowWithTitle:[NSString stringWithFormat:@"• %@", [item objectForKey:@"name"]] url:[item objectForKey:@"url"]]];
    }

    /* Credits */
    [stack addArrangedSubview:[self sectionTitle:@"CREDITS"]];
    UILabel *credits1 = [[UILabel alloc] init];
    credits1.text = @"Designed and developed with 📚 for language learners everywhere.";
    credits1.font = [UIFont systemFontOfSize:14];
    credits1.textColor = [UIColor secondaryLabelColor];
    credits1.textAlignment = NSTextAlignmentCenter;
    credits1.numberOfLines = 0;
    [stack addArrangedSubview:credits1];
    UILabel *credits2 = [[UILabel alloc] init];
    credits2.text = @"Special thanks to the open source community and all our early testers.";
    credits2.font = [UIFont systemFontOfSize:14];
    credits2.textColor = [UIColor tertiaryLabelColor];
    credits2.textAlignment = NSTextAlignmentCenter;
    credits2.numberOfLines = 0;
    [stack addArrangedSubview:credits2];

    /* Footer */
    UILabel *footer1 = [[UILabel alloc] init];
    footer1.text = @"© 2024 Xenolexia";
    footer1.font = [UIFont systemFontOfSize:13];
    footer1.textColor = [UIColor tertiaryLabelColor];
    footer1.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:footer1];
    UILabel *footer2 = [[UILabel alloc] init];
    footer2.text = @"Made with ❤️";
    footer2.font = [UIFont systemFontOfSize:13];
    footer2.textColor = [UIColor tertiaryLabelColor];
    footer2.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:footer2];

    _contentStack = stack;

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [scroll addSubview:stack];
    _scrollView = scroll;

    [self.view addSubview:scroll];

    NSDictionary *views = @{@"scroll": scroll, @"stack": stack};
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scroll]|" options:0 metrics:nil views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scroll]|" options:0 metrics:nil views:views]];
    [scroll addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[stack]|" options:0 metrics:nil views:views]];
    [scroll addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[stack]|" options:0 metrics:nil views:views]];
    [scroll addConstraint:[NSLayoutConstraint constraintWithItem:stack attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:scroll attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
}

- (UILabel *)sectionTitle:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:12];
    l.textColor = [UIColor tertiaryLabelColor];
    return [l autorelease];
}

- (UIButton *)linkRowWithTitle:(NSString *)title url:(NSString *)url {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(12, 16, 12, 16);
    objc_setAssociatedObject(btn, "url", url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [btn addTarget:self action:@selector(linkTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)linkTapped:(UIButton *)sender {
    NSString *url = objc_getAssociatedObject(sender, "url");
    if (url) {
        NSURL *u = [NSURL URLWithString:url];
        if (u && [[UIApplication sharedApplication] canOpenURL:u]) {
            [[UIApplication sharedApplication] openURL:u options:@{} completionHandler:nil];
        }
    }
}

- (void)dealloc {
    [_scrollView release];
    [_contentStack release];
    [super dealloc];
}

@end

#endif
