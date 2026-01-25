# Xenolexia Objective-C

Objective-C implementation of Xenolexia, a language learning framework that helps you learn new languages by selectively translating words in books.

## Overview

This implementation targets:
- **macOS** (Cocoa/AppKit)
- **iOS** (UIKit)
- **Linux** (GNUStep)

The core functionality is shared across all platforms, with platform-specific UI code separated into dedicated folders.

## Project Structure

```
xenolexia-objc/
├── Core/                    # Shared core code
│   ├── Models/             # Data models (Language, Book, Vocabulary, Reader)
│   └── Services/           # Core services (Parser, Translation, Storage, Export)
├── Platform/                # Platform-specific UI code
│   ├── macOS/              # macOS UI
│   ├── iOS/                # iOS UI
│   └── Linux/              # GNUStep UI
└── [Legacy files]          # Original implementation files
```

## Features

### Implemented

- ✅ Core data models matching React/C# implementations
- ✅ Book parsing service (TXT format, EPUB structure in place)
- ✅ Translation engine with proficiency-based word selection
- ✅ Vocabulary management with SRS support
- ✅ SQLite storage for books and vocabulary
- ✅ Export service (CSV, JSON, Anki formats)
- ✅ Language support (28+ languages)
- ✅ Proficiency levels (Beginner, Intermediate, Advanced)

### In Progress

- ⏳ Full EPUB parsing (structure in place, needs ZIP/XML parsing)
- ⏳ Enhanced HTML tokenization
- ⏳ Frequency-based word selection
- ⏳ Multiple translation API providers
- ⏳ Platform-specific UI implementations

## Usage

### Basic Usage

```objc
#import "Core/Services/XLManager.h"

// Get the shared manager
XLManager *manager = [XLManager sharedManager];

// Import a book
[manager importBookAtPath:@"/path/to/book.txt" 
           withCompletion:^(XLBook *book, NSError *error) {
    if (book) {
        NSLog(@"Imported: %@", book.title);
    }
}];

// Process a book chapter
[manager processBook:book withCompletion:^(XLProcessedChapter *chapter, NSError *error) {
    if (chapter) {
        // Use processed chapter with foreign words
        NSLog(@"Processed content: %@", chapter.processedContent);
    }
}];

// Translate a word
[manager translateWord:@"hello" 
         withCompletion:^(NSString *translated, NSError *error) {
    NSLog(@"Translation: %@", translated);
}];
```

### Language Configuration

```objc
// Create a language pair
XLLanguagePair *pair = [XLLanguagePair pairWithSource:XLLanguageEnglish 
                                                  target:XLLanguageFrench];

// Create translation options
XLTranslationOptions *options = [XLTranslationOptions optionsWithLanguagePair:pair
                                                             proficiencyLevel:XLProficiencyLevelBeginner
                                                                 wordDensity:0.3];

// Create translation engine
XLTranslationEngine *engine = [[XLTranslationEngine alloc] initWithOptions:options];
```

### Vocabulary Management

```objc
// Save a word to vocabulary
XLVocabularyItem *item = [XLVocabularyItem itemWithSourceWord:@"hello"
                                                    targetWord:@"bonjour"
                                                sourceLanguage:XLLanguageEnglish
                                                targetLanguage:XLLanguageFrench];
item.contextSentence = @"Hello, how are you?";
item.bookId = book.bookId;
item.bookTitle = book.title;

[manager saveWordToVocabulary:item withCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Word saved to vocabulary");
    }
}];

// Get all vocabulary items
[manager getAllVocabularyItemsWithCompletion:^(NSArray<XLVocabularyItem *> *items, NSError *error) {
    NSLog(@"Vocabulary count: %lu", (unsigned long)items.count);
}];
```

### Export Vocabulary

```objc
#import "Core/Services/XLExportService.h"

XLExportService *exportService = [[XLExportService alloc] init];

[exportService exportVocabularyItems:vocabularyItems
                               format:XLExportFormatAnki
                           toFilePath:@"/path/to/export.tsv"
                       withCompletion:^(BOOL success, NSError *error) {
    if (success) {
        NSLog(@"Export completed");
    }
}];
```

## Building

### macOS

```bash
# Create Xcode project or use existing
xcodebuild -project Xenolexia.xcodeproj -scheme Xenolexia-macOS
```

### iOS

```bash
xcodebuild -project Xenolexia.xcodeproj -scheme Xenolexia-iOS -sdk iphonesimulator
```

### Linux (GNUStep)

```bash
# Using GNUstep-make
make -f GNUmakefile
```

## Dependencies

- **Foundation** - Core Objective-C runtime
- **SQLite3** - Database storage
- **CoreLocation** (iOS/macOS only) - Location services

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed architecture documentation.

## Comparison with Other Implementations

This Objective-C implementation matches the functionality of:
- **React Native** (`../xenolexia-react`) - Mobile app
- **C#/.NET** (`../xenolexia-csharp`) - Cross-platform desktop

All three implementations share the same core models and service architecture, ensuring consistency across platforms.

## License

See [LICENSE](LICENSE) file for details.

## Contributing

When adding new features:
1. Add models to `Core/Models/`
2. Add services to `Core/Services/`
3. Keep platform-specific code in `Platform/[platform]/`
4. Update this README and ARCHITECTURE.md

## Status

This is a work in progress. Core functionality is implemented, but platform-specific UI implementations are pending. The core services are functional and can be used in any Objective-C project targeting macOS, iOS, or Linux (GNUStep).
