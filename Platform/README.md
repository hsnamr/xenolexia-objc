# Xenolexia Platform Targets

Xenolexia-objc supports three platforms, using **SmallStep** for cross-platform abstractions (file system, app lifecycle, menu).

## Platforms

| Platform | UI | Entry | Build |
|----------|-----|-------|-------|
| **Linux** | GNUStep (AppKit-compatible) | `Platform/Linux/main.m` → `XLLinuxApp` | `Platform/Linux/GNUmakefile` |
| **macOS** | AppKit | `Platform/macOS/main.m` → same `XLLinuxApp` (desktop) | Xcode project (add macOS app target) |
| **iOS** | UIKit | `Platform/iOS/main.m` → `XLiOSAppDelegate` + `SSHostApplication` | Xcode project (add iOS app target) |

## SmallStep usage

- **SSFileSystem**: All file/directory access (documents, cache, app support). Used by `XLStorageService`, `XLManager`, `XLExportService`, `DownloadService`, `XLLibraryWindowController`, `XLBookParserService`.
- **SSPlatform**: Runtime platform checks (`isMacOS`, `isiOS`, `isLinux`).
- **SSAppDelegate** / **SSHostApplication**: Desktop app lifecycle; on Linux/macOS `[SSHostApplication runWithDelegate:self]` runs NSApplication and forwards `applicationDidFinishLaunching`, `applicationWillTerminate`, etc. On iOS, `[SSHostApplication setAppDelegate:logic]` before `UIApplicationMain`; `XLiOSAppDelegate` forwards to it.
- **SSMainMenu**: Desktop main menu built from items (Library, Vocabulary, Review, Settings, Statistics, Quit). Used by `XLLinuxApp` on Linux and can be used on macOS.

## Linux (GNUStep)

### Build order

1. **Build SmallStep** (sibling of Xenolexia repo at `../SmallStep` or `$(WORKSPACE)/SmallStep`):
   ```bash
   cd /path/to/SmallStep
   . /usr/share/GNUStep/Makefiles/GNUstep.sh   # if needed
   make
   ```

2. **Optional symlink** so xenolexia-objc finds SmallStep: from the Xenolexia repo root, if SmallStep is a sibling (e.g. `Workspace/self/SmallStep` and `Workspace/self/Xenolexia`):
   ```bash
   cd /path/to/Xenolexia
   ln -sn ../SmallStep SmallStep
   ```
   The GNUmakefile expects SmallStep at `xenolexia-objc/Platform/Linux/../../../SmallStep` (i.e. `Xenolexia/SmallStep`).

3. **Build xenolexia-shared-c** (same repo):
   ```bash
   cd /path/to/Xenolexia/xenolexia-shared-c
   make
   ```

4. **Build Xenolexia Linux app**:
   ```bash
   cd /path/to/Xenolexia/xenolexia-objc/Platform/Linux
   . /usr/share/GNUStep/Makefiles/GNUstep.sh   # if needed
   make
   ```
   Output: `Xenolexia.app/` (or `./Xenolexia`).

Requires: GNUStep, SmallStep, xenolexia-shared-c (libxenolexia_sm2, libxenolexia_epub, etc.), SQLite, libxml2, zlib.

## macOS

- Use the same desktop UI as Linux: `XLLinuxApp` + window controllers (NSWindowController).
- Add an Xcode project with a **macOS Application** target:
  - Source files: `Platform/macOS/main.m`, `Platform/Linux/UI/**/*.m`, `Core/**/*.m`, services, SmallStep sources.
  - Link: AppKit, Foundation, xenolexia-shared-c (or use xenolexia-shared-cpp when available).
- Entry point: `Platform/macOS/main.m` → `[XLLinuxApp sharedApp] run` (same as Linux).

## iOS (UIKit)

- **Entry**: `Platform/iOS/main.m` sets `[SSHostApplication setAppDelegate:logic]` then `UIApplicationMain(..., XLiOSAppDelegate)`.
- **XLiOSAppDelegate**: Forwards `application:didFinishLaunchingWithOptions` and `applicationWillTerminate` to `[SSHostApplication appDelegate]` (SSAppDelegate). Creates `UIWindow` and a placeholder root view controller (to be replaced with Library/Vocabulary/Review/Settings/Statistics).
- **App logic**: `XLiOSAppLogic` in `main.m` implements `SSAppDelegate` and `XLStorageServiceDelegate`, initializes the database; full UX (library, reader, vocabulary) can be shared by introducing view-controller abstractions that map to desktop window controllers.

To add a full iOS app in Xcode:

1. New **iOS App** target.
2. Add `Platform/iOS/main.m`, `XLiOSAppDelegate.h/m`, Core, services, SmallStep.
3. Replace the placeholder root view controller with a tab bar or navigation that presents Library, Vocabulary, Review, Settings, Statistics (using the same Core services and SmallStep).

## Abstractions in SmallStep

All cross-platform abstractions used by xenolexia-objc live in **../SmallStep**:

- **SSAppDelegate**: Optional methods `applicationDidFinishLaunching`, `applicationWillTerminate`, `applicationWillFinishLaunching`, `applicationShouldTerminateAfterLastWindowClosed:`.
- **SSHostApplication**: `runWithDelegate:` (desktop: runs NSApplication); `setAppDelegate:` / `appDelegate` (iOS: set before UIApplicationMain, forward from UIApplicationDelegate).
- **SSMainMenu**: Desktop-only; build main menu from `SSMainMenuItem` array (title, action, keyEquivalent, modifierMask, target).
- **SSFileSystem**, **SSPlatform**, **SSFileDialog**, **SSWindowStyle**: Existing SmallStep APIs.

No UI logic is duplicated between xenolexia-objc and SmallStep; xenolexia only implements app-specific screens and uses SmallStep for platform and lifecycle.
