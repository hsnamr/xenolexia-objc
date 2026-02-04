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

1. **Build SmallStep as a library** and install headers + lib into xenolexia-objc (do **not** compile SmallStep sources as part of xenolexia-objc):
   ```bash
   cd /path/to/Xenolexia/xenolexia-objc
   ./scripts/install-smallstep.sh /path/to/SmallStep
   ```
   This builds SmallStep as a static library (`libSmallStep.a`), copies headers to `xenolexia-objc/include/`, and the library to `xenolexia-objc/lib/`. If SmallStep is a sibling of Xenolexia, you can omit the path: `./scripts/install-smallstep.sh` (defaults to `../SmallStep`).

2. **Build Xenolexia Linux app** (no xenolexia-shared-c required; uses native ObjC Core/Native and SmallStep from `include/` and `lib/`):
   ```bash
   cd /path/to/Xenolexia/xenolexia-objc/Platform/Linux
   . /usr/share/GNUStep/Makefiles/GNUstep.sh   # if needed
   make
   ```
   Output: `Xenolexia.app/` (or `./Xenolexia`).

Requires: GNUStep, SmallStep, SQLite, libxml2, zlib, libzip. SM-2, EPUB, FB2, PDF (stub), MOBI (stub) are implemented in Core/Native (no xenolexia-shared-c).

## macOS

- Use the same desktop UI as Linux: `XLLinuxApp` + window controllers (NSWindowController).
- Add an Xcode project with a **macOS Application** target:
  - Source files: `Platform/macOS/main.m`, `Platform/Linux/UI/**/*.m`, `Core/**/*.m`, services. SmallStep: use `include/` headers and `lib/libSmallStep.a` (build SmallStep and run install-smallstep.sh for macOS, or add SmallStep sources to the target).
  - Link: AppKit, Foundation, Core/Native (XLSm2, XLEpubReader, XLFB2Reader, XLPDFReader, XLMobiReader), SmallStep.
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
