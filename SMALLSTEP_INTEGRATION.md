# SmallStep Integration

Xenolexia now uses SmallStep as its cross-platform abstraction layer for file system operations and platform detection.

## Changes Made

### Services Updated

1. **XLStorageService**
   - Now uses `SSFileSystem` for database path resolution
   - Cross-platform documents directory access

2. **DownloadService**
   - Uses `SSFileSystem` for file operations
   - Cross-platform directory listing

3. **XLExportService**
   - Uses `SSFileSystem` for file writing
   - Consistent file operations across platforms

4. **XLManager**
   - Uses `SSFileSystem` for legacy method compatibility
   - Unified directory access

## Usage

All file system operations now go through SmallStep:

```objc
#import <SmallStep/SmallStep.h>

SSFileSystem *fileSystem = [SSFileSystem sharedFileSystem];
NSString *documentsDir = [fileSystem documentsDirectory];
NSString *cacheDir = [fileSystem cacheDirectory];
```

## Platform Detection

You can detect the platform at runtime:

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
