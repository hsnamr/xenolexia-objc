# Xenolexia Objective-C Architecture

This document describes the architecture of the Xenolexia Objective-C implementation, which targets macOS, iOS, and Linux (GNUStep).

## Project Structure

```
xenolexia-objc/
├── Core/                          # Shared core code (platform-independent)
│   ├── Models/                    # Data models
│   │   ├── Language.h/m          # Language and proficiency definitions
│   │   ├── Book.h/m              # Book, Chapter, TOC models
│   │   ├── Vocabulary.h/m        # Vocabulary and word entry models
│   │   └── Reader.h/m            # Reader settings and processed content
│   └── Services/                  # Core services
│       ├── XLBookParserService.h/m    # Book parsing (EPUB, TXT)
│       ├── XLTranslationEngine.h/m     # Word replacement engine
│       ├── XLTranslationService.h/m   # Translation API wrapper
│       ├── XLStorageService.h/m        # SQLite storage
│       ├── XLExportService.h/m         # Export (CSV, JSON, Anki)
│       └── XLManager.h/m               # Main manager class
├── Platform/                      # Platform-specific code
│   ├── macOS/                     # macOS-specific UI
│   ├── iOS/                       # iOS-specific UI
│   └── Linux/                     # GNUStep UI
├── DictionaryService.h/m          # Legacy dictionary service (used for backward compatibility)
├── TranslationService.h/m          # Legacy translation service (used by XLTranslationService)
└── DownloadService.h/m             # File download service (used by XLManager)

```

## Core Architecture

### Models

All models are in `Core/Models/` and are designed to match the React and C# implementations:

- **Language**: Language codes, proficiency levels, language pairs
- **Book**: Book metadata, chapters, table of contents
- **Vocabulary**: Word entries, vocabulary items with SRS (Spaced Repetition System) support
- **Reader**: Reader settings, processed chapters, reading sessions, statistics

### Services

Core services follow a protocol-based architecture for testability:

- **XLBookParserService**: Parses EPUB and TXT files, extracts chapters and metadata
- **XLTranslationEngine**: Processes text, tokenizes words, replaces based on proficiency
- **XLTranslationService**: Wraps translation APIs (currently uses legacy service)
- **XLStorageService**: SQLite-based persistence for books and vocabulary
- **XLExportService**: Exports vocabulary to CSV, JSON, or Anki format

### Manager

`XLManager` is the main entry point that coordinates all services. It provides:
- Book import and processing
- Translation operations
- Vocabulary management
- Legacy method compatibility

## Platform Support

### Shared Code

All code in `Core/` is platform-independent and can be used on:
- macOS (Cocoa)
- iOS (UIKit)
- Linux (GNUStep)

### Platform-Specific Code

Platform-specific UI code should be placed in:
- `Platform/macOS/` - AppKit-based UI
- `Platform/iOS/` - UIKit-based UI
- `Platform/Linux/` - GNUStep-based UI

## Usage Example

```objc
// Import a book
XLManager *manager = [XLManager sharedManager];
[manager importBookAtPath:@"/path/to/book.txt" 
           withCompletion:^(XLBook *book, NSError *error) {
    if (book) {
        // Process the book
        [manager processBook:book withCompletion:^(XLProcessedChapter *chapter, NSError *error) {
            // Use processed chapter with foreign words
        }];
    }
}];

// Translate a word
[manager translateWord:@"hello" 
         withCompletion:^(NSString *translated, NSError *error) {
    NSLog(@"Translation: %@", translated);
}];

// Save to vocabulary
XLVocabularyItem *item = [XLVocabularyItem itemWithSourceWord:@"hello"
                                                    targetWord:@"bonjour"
                                                sourceLanguage:XLLanguageEnglish
                                                targetLanguage:XLLanguageFrench];
[manager saveWordToVocabulary:item withCompletion:^(BOOL success, NSError *error) {
    // Handle result
}];
```

## Database Schema

The SQLite database includes:

- **books**: Book metadata and reading progress
- **vocabulary**: Saved vocabulary items with SRS data

## Translation Engine

The translation engine:
1. Tokenizes HTML content while preserving structure
2. Selects words based on proficiency level and density
3. Looks up translations (cached when possible)
4. Replaces words in the content
5. Returns processed content with foreign word markers

## Future Enhancements

- Full EPUB parsing support (currently TXT only)
- Enhanced tokenization with HTML structure preservation
- Frequency-based word selection
- Multiple translation API providers
- Offline translation support
- Enhanced SRS algorithm implementation

## Compatibility

This implementation maintains backward compatibility with the legacy `Manager` class while providing a modern, protocol-based architecture that matches the React and C# implementations.
