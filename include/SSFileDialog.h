//
//  SSFileDialog.h
//  SmallStep
//
//  Cross-platform file dialog abstraction
//

#import <Foundation/Foundation.h>

#if TARGET_OS_MAC && !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#elif TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <PhotosUI/PhotosUI.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#elif TARGET_OS_WIN32
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/// File dialog result codes
typedef NS_ENUM(NSInteger, SSFileDialogResult) {
    SSFileDialogResultOK = 0,
    SSFileDialogResultCancel = 1
};

/// Cross-platform file dialog abstraction
@interface SSFileDialog : NSObject
#if TARGET_OS_IPHONE
<PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate>
#endif
{
    NSArray *_allowedFileTypes;
    BOOL _allowsMultipleSelection;
    BOOL _canChooseDirectories;
    BOOL _canChooseFiles;
    BOOL _canCreateDirectories;
    BOOL _isSaveDialog;
}

/// Create a file open dialog
+ (instancetype)openDialog;

/// Create a file save dialog
+ (instancetype)saveDialog;

/// Set allowed file types
/// @param fileTypes Array of file extensions (e.g., @[@"jpg", @"png"])
- (void)setAllowedFileTypes:(NSArray *)fileTypes;

/// Set whether multiple files can be selected
/// @param allowsMultiple Whether to allow multiple selection
- (void)setAllowsMultipleSelection:(BOOL)allowsMultiple;

/// Set whether directories can be selected
/// @param canChooseDirectories Whether directories can be chosen
- (void)setCanChooseDirectories:(BOOL)canChooseDirectories;

/// Set whether files can be selected
/// @param canChooseFiles Whether files can be chosen
- (void)setCanChooseFiles:(BOOL)canChooseFiles;

/// Set whether directories can be created (for save dialogs)
/// @param canCreateDirectories Whether directories can be created
- (void)setCanCreateDirectories:(BOOL)canCreateDirectories;

/// Show the dialog modally (synchronous)
/// @return Array of selected URLs, or nil if cancelled
- (NSArray *)showModal;

#if __has_feature(blocks) || (TARGET_OS_IPHONE && __clang__)
/// File dialog completion handler
typedef void (^SSFileDialogCompletionHandler)(SSFileDialogResult result, NSArray *urls);

/// Show the dialog and call completion handler (async, all platforms)
/// @param completionHandler Block called when dialog is dismissed
- (void)showWithCompletionHandler:(SSFileDialogCompletionHandler)completionHandler;
#endif

@end

NS_ASSUME_NONNULL_END
