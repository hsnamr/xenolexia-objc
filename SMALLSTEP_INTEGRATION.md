# SmallStep Integration

Xenolexia uses SmallStep as its cross-platform abstraction layer for file system operations, platform detection, app lifecycle, and desktop menu. No functionality is duplicated that SmallStep already provides.

## Changes Made

### Services and UI Updated

1. **XLStorageService**
   - Uses `SSFileSystem` for database path resolution and documents directory.

2. **DownloadService**
   - Uses `SSFileSystem` for file operations and directory listing.

3. **XLExportService**
   - Uses `SSFileSystem` for file writing.

4. **XLManager**
   - Uses `SSFileSystem` for directory access.

5. **XLLibraryWindowController**
   - Uses `SSFileSystem` for window state path (`applicationSupportDirectory` + `xenolexia/window_state.plist`) and cover file existence checks.

6. **XLBookParserService**
   - Uses `SSFileSystem` for `fileExistsAtPath:` instead of `NSFileManager` directly.

7. **XLLinuxApp (desktop)**
   - Uses `SSHostApplication runWithDelegate:self` instead of manually setting NSApplication delegate and calling `[app run]`.
   - Uses `SSMainMenu` to build the main menu from items (Library, Vocabulary, Review, Settings, Statistics, Quit) instead of building NSMenu by hand.
   - Conforms to `SSAppDelegate`; lifecycle is forwarded by SmallStep’s desktop adapter.

## Usage

All file system operations now go through SmallStep:

```objc
#import <SmallStep/SmallStep.h>

SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
NSString *documentsDir = [fileSystem documentsDirectory];
NSString *cacheDir = [fileSystem cacheDirectory];
```

## App Lifecycle (SSAppDelegate / SSHostApplication)

- **Desktop (Linux/macOS):** Call `[SSHostApplication runWithDelegate:myDelegate]`. Your delegate conforms to `SSAppDelegate` (optional: `applicationDidFinishLaunching`, `applicationWillTerminate`, `applicationShouldTerminateAfterLastWindowClosed:`). SmallStep runs NSApplication and forwards these to your delegate.
- **iOS:** Before `UIApplicationMain`, call `[SSHostApplication setAppDelegate:logic]`. Your `UIApplicationDelegate` forwards `application:didFinishLaunchingWithOptions` and `applicationWillTerminate` to `[SSHostApplication appDelegate]`.

## Desktop Main Menu (SSMainMenu)

Use `SSMainMenu` and `SSMainMenuItem` to build the app menu instead of duplicating NSMenu code:

```objc
SSMainMenu *menu = [[[SSMainMenu alloc] init] autorelease];
[menu setAppName:@"Xenolexia"];
NSArray *items = @[
    [SSMainMenuItem itemWithTitle:@"Library" action:@selector(showLibrary:) keyEquivalent:@"1" modifierMask:NSControlKeyMask target:self],
    // ...
];
[menu buildMenuWithItems:items quitTitle:@"Quit Xenolexia" quitKeyEquivalent:@"q"];
```

## Platform Detection

```objc
if ([SSPlatform isMacOS]) {
    // macOS-specific code
} else if ([SSPlatform isiOS]) {
    // iOS-specific code
} else if ([SSPlatform isLinux]) {
    // Linux/GNUStep-specific code
}
```

## Building with SmallStep

### macOS/iOS

1. Add SmallStep framework to your Xcode project
2. Link against SmallStep.framework
3. Import: `#import <SmallStep/SmallStep.h>`

### Linux (GNUStep)

1. Build and install SmallStep:
   ```bash
   cd ~/Workspace/self/SmallStep
   make
   sudo make install
   ```

2. In your GNUmakefile, link against SmallStep:
   ```makefile
   YourApp_LIBRARIES_DEPEND_UPON = -lSmallStep
   ```

## Benefits

- **Cross-platform compatibility**: Same code works on macOS, iOS, and Linux
- **Platform conventions**: Respects XDG on Linux, Cocoa on Apple platforms
- **Unified API**: Single interface for all platforms
- **Future-proof**: Easy to add new platforms or features
