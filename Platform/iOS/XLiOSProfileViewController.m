//
//  XLiOSProfileViewController.m
//  Xenolexia (iOS)
//
//  Profile screen with menu items. About Xenolexia navigates to XLAboutViewController.
//  Aligned with xenolexia-typescript/react-native-app ProfileScreen.
//

#import "XLiOSProfileViewController.h"
#import "XLAboutViewController.h"

#if TARGET_OS_IPHONE

@interface XLiOSProfileViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIStackView *contentStack;
@end

@implementation XLiOSProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Profile";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self buildUI];
}

- (void)buildUI {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.spacing = 0;
    stack.layoutMargins = UIEdgeInsetsMake(24, 16, 40, 16);
    stack.layoutMarginsRelativeArrangement = YES;

    /* Header */
    UIView *header = [[UIView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    UILabel *avatarLabel = [[UILabel alloc] init];
    avatarLabel.text = @"👤";
    avatarLabel.font = [UIFont systemFontOfSize:48];
    avatarLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:avatarLabel];
    UILabel *nameLabel = [[UILabel alloc] init];
    nameLabel.text = @"Reader";
    nameLabel.font = [UIFont boldSystemFontOfSize:22];
    nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:nameLabel];
    UILabel *subLabel = [[UILabel alloc] init];
    subLabel.text = @"Learning languages";
    subLabel.font = [UIFont systemFontOfSize:15];
    subLabel.textColor = [UIColor secondaryLabelColor];
    subLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [header addSubview:subLabel];

    [header addConstraints:@[
        [NSLayoutConstraint constraintWithItem:avatarLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:header attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:avatarLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:header attribute:NSLayoutAttributeTop multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:nameLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:header attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:nameLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:avatarLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:12],
        [NSLayoutConstraint constraintWithItem:subLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:header attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
        [NSLayoutConstraint constraintWithItem:subLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:nameLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:4],
        [NSLayoutConstraint constraintWithItem:subLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:header attribute:NSLayoutAttributeBottom multiplier:1 constant:0],
    ]];
    [stack addArrangedSubview:header];
    [header release];

    /* App section - About Xenolexia */
    [stack addArrangedSubview:[self sectionTitle:@"APP"]];
    [stack addArrangedSubview:[self menuRowWithIcon:@"ℹ️" title:@"About Xenolexia" subtitle:@"Version, licenses, contact" action:@selector(showAbout:)]];

    /* Version footer */
    UILabel *versionLabel = [[UILabel alloc] init];
    versionLabel.text = @"Xenolexia v1.0.0 • Built with ❤️";
    versionLabel.font = [UIFont systemFontOfSize:13];
    versionLabel.textColor = [UIColor tertiaryLabelColor];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [stack addArrangedSubview:versionLabel];
    [versionLabel release];

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
    l.text = [text uppercaseString];
    l.font = [UIFont boldSystemFontOfSize:12];
    l.textColor = [UIColor tertiaryLabelColor];
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return [l autorelease];
}

- (UIView *)menuRowWithIcon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(16, 16, 16, 40);
    btn.backgroundColor = [UIColor secondarySystemBackgroundColor];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:[NSString stringWithFormat:@"%@  %@", icon, title] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    (void)subtitle;
    return btn;
}

- (void)showAbout:(id)sender {
    (void)sender;
    XLAboutViewController *about = [[[XLAboutViewController alloc] init] autorelease];
    [self.navigationController pushViewController:about animated:YES];
}

- (void)dealloc {
    [_scrollView release];
    [_contentStack release];
    [super dealloc];
}

@end

#endif
