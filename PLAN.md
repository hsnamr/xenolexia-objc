# Xenolexia Objective-C Development Plan 📋

This document outlines the complete development roadmap for Xenolexia Objective-C, targeting macOS, iOS, Windows (WinObjC), and Linux (GNUStep).

---

## 📅 Development Phases

### Phase 0: Project Setup
**Status: ✅ COMPLETED**

#### 0.1 Environment Configuration
- [x] Create project structure with Core/ and Platform/ separation
- [x] Initialize cross-platform abstraction layer (SmallStep)
- [x] Set up Git repository
- [x] Configure build systems (GNUmakefile for Linux, Xcode for macOS/iOS)
- [x] Set up SmallStep framework/library

#### 0.2 Core Dependencies
- [x] Foundation framework (all platforms)
- [x] SQLite3 for database storage
- [x] SmallStep for cross-platform file operations
- [x] AppKit (macOS/Linux) / UIKit (iOS) for UI

#### 0.3 Initial App Structure
- [x] Create Core models matching React/C# implementations
- [x] Create Core services architecture
- [x] Set up platform-specific UI folders
- [x] Create SmallStep cross-platform layer

---

### Phase 1: Core Models & Services
**Status: ✅ COMPLETED**

#### 1.1 Core Models
- [x] Language model (28+ languages, proficiency levels, language pairs)
- [x] Book model (metadata, chapters, TOC, progress tracking)
- [x] Vocabulary model (word entries, SRS support)
- [x] Reader model (settings, processed chapters, reading sessions, statistics)

#### 1.2 Core Services
- [x] XLBookParserService - Book parsing (TXT implemented, EPUB structure ready)
- [x] XLTranslationEngine - Word replacement with proficiency-based selection
- [x] XLTranslationService - Translation API wrapper
- [x] XLStorageService - SQLite-based persistence
- [x] XLExportService - Export (CSV, JSON, Anki)
- [x] XLManager - Main coordinator class

#### 1.3 Cross-Platform Layer
- [x] SmallStep framework created
- [x] Platform detection (macOS, iOS, Linux, Windows)
- [x] Unified file system operations
- [x] Platform-specific utilities

---

### Phase 2: Library Screen
**Status: 🔶 IN PROGRESS**

#### 2.1 Book Import
- [x] Basic book import functionality
- [x] Support for TXT format
- [ ] Support for EPUB format (structure in place, needs ZIP/XML parsing)
- [ ] Support for FB2, MOBI formats
- [x] Store book files in app storage
- [x] Create database schema for books
- [x] SQLite database operations (save, get, delete, getAll with sorting)
- [x] File size detection on import
- [ ] Import progress modal with status indicator (blocked by GNUStep block support)

#### 2.2 Library UI
- [x] Basic Library window controller (Linux/GNUStep)
- [x] Table view with book list
- [x] Search functionality
- [x] Import button
- [x] Sort options (recent, title, author, progress) - implemented with menu
- [x] Delete book functionality - implemented with confirmation dialog
- [x] Book detail screen - implemented
- [ ] Grid/List view toggle
- [ ] Book cards with cover, title, progress (currently using table view)
- [ ] Edit book functionality
- [ ] macOS/iOS/Windows UI implementations

**Note**: Current implementation uses blocks for async callbacks, which GNUStep doesn't support. Need to refactor to use delegate pattern or synchronous methods for full GNUStep compatibility.

**Technical Details:**
```objc
// Book entity structure (Implemented)
@interface XLBook : NSObject <NSCoding>
@property (nonatomic, copy) NSString *bookId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *author;
@property (nonatomic, copy) NSString *coverPath;
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic) XLBookFormat format;
@property (nonatomic) long long fileSize;
@property (nonatomic, retain) NSDate *addedAt;
@property (nonatomic, retain) NSDate *lastReadAt;
@property (nonatomic) double progress; // 0-100
@property (nonatomic, copy) NSString *currentLocation;
@property (nonatomic, retain) XLLanguagePair *languagePair;
@property (nonatomic) XLProficiencyLevel proficiencyLevel;
@property (nonatomic) double wordDensity;
@end
```

---

### Phase 3: Translation Engine
**Status: ✅ COMPLETED**

#### 3.1 Word Database Setup
- [x] Translation service with multiple language support
- [x] Language pair configuration (28+ languages)
- [x] Proficiency level mapping (Beginner, Intermediate, Advanced)
- [x] Word caching system
- [ ] Frequency-ranked word lists per language (structure ready)
- [ ] Dynamic word database with frequency data

#### 3.2 Word Replacement Algorithm
- [x] Basic tokenization
- [x] Word selection based on proficiency and density
- [x] Word replacement in content
- [ ] Enhanced HTML tokenization (preserve structure)
- [ ] Handle punctuation correctly (basic support)
- [ ] Support hyphenated words
- [ ] Avoid replacing within quotes, names, technical terms
- [ ] Preserve case in replacements

#### 3.3 Context-Aware Selection
- [x] Random selection based on density setting
- [x] Basic word spacing
- [ ] Distributed selection strategy (evenly spread words)
- [ ] Frequency-based selection (prefer common words)
- [ ] Skip protected content (quotes, names, code)
- [ ] Track replaced words to avoid repetition

---

### Phase 4: Reader Screen
**Status: ⏳ NOT STARTED**

#### 4.1 Basic Reader
- [ ] Render processed book content
- [ ] Implement continuous scroll with progress tracking
- [ ] Chapter navigation (prev/next + chapter list)
- [ ] Progress tracking (scroll position + chapter)
- [ ] Save reading position automatically

#### 4.2 Reader Customization
- [ ] Font selection (Serif, Sans-serif, Dyslexic-friendly)
- [ ] Font size adjustment
- [ ] Line spacing control
- [ ] Margin adjustment
- [ ] Theme selection (Light, Dark, Sepia)
- [ ] Brightness control

#### 4.3 Foreign Word Interaction ⭐
- [ ] Style foreign words distinctly
- [ ] Click/tap detection on foreign words
- [ ] Translation popup component:
  - Original word
  - Phonetic pronunciation
  - Context sentence display
  - Proficiency level badge
  - Save to vocabulary button
  - "I knew this" button
- [ ] Visual feedback on interaction

#### 4.4 Reading Statistics
- [ ] Track time spent reading
- [ ] Count chapters read
- [ ] Track words revealed vs. saved
- [ ] Session summary on close

---

### Phase 5: Vocabulary Manager
**Status: 🔶 PARTIALLY COMPLETED**

#### 5.1 Word Storage
- [x] Save words from reader to vocabulary (structure ready)
- [x] Store context sentence with each word
- [x] Track when word was first seen (addedAt)
- [x] Track reveal count per word
- [x] Mark words as "learned" (status field)
- [x] SM-2 algorithm structure (easeFactor, interval)

#### 5.2 Vocabulary Screen
- [ ] List all saved words
- [ ] Filter by book, date, status
- [ ] Search vocabulary
- [ ] Edit/delete words
- [x] Export vocabulary (CSV, Anki, JSON)
- [ ] Stats header with due count

#### 5.3 Spaced Repetition System (SRS)
- [x] SM-2 algorithm structure in place
- [ ] Schedule word reviews (getDueForReview)
- [ ] Review mode UI:
  - Show foreign word (FlashCard front)
  - User attempts recall (tap to flip)
  - Reveal and self-grade
- [ ] Track review statistics

---

### Phase 6: Settings & Onboarding
**Status: ⏳ NOT STARTED**

#### 6.1 Onboarding Flow
- [ ] Welcome screen with app explanation
- [ ] Select source language (28 languages supported)
- [ ] Select target language (with search)
- [ ] Select proficiency level (with CEFR + examples)
- [ ] Adjust initial density preference
- [ ] Summary and start screen
- [ ] Skip option for returning users

#### 6.2 Settings Screen
- [ ] Language pair configuration
- [ ] Proficiency level adjustment
- [ ] Word density slider
- [ ] Reader appearance defaults
- [ ] Notification preferences
- [ ] Data export/backup
- [ ] About & help section

---

### Phase 7: Platform-Specific UI
**Status: 🔶 IN PROGRESS**

#### 7.1 Linux (GNUStep)
- [x] Basic Library window controller
- [x] Table view with book list
- [x] Search functionality
- [x] Import button
- [ ] Reader window
- [ ] Vocabulary window
- [ ] Statistics window
- [ ] Settings window

#### 7.2 macOS
- [ ] Library window (AppKit)
- [ ] Reader window
- [ ] Vocabulary window
- [ ] Statistics window
- [ ] Settings window

#### 7.3 iOS
- [ ] Library screen (UIKit)
- [ ] Reader screen
- [ ] Vocabulary screen
- [ ] Statistics screen
- [ ] Settings screen

#### 7.4 Windows (WinObjC)
- [ ] Library window
- [ ] Reader window
- [ ] Vocabulary window
- [ ] Statistics window
- [ ] Settings window

---

### Phase 8: Polish & Testing
**Status: ⏳ NOT STARTED**

#### 8.1 Testing
- [ ] Unit tests for services
- [ ] Component tests
- [ ] Store tests
- [ ] E2E tests for critical flows
- [ ] Performance testing with large books

#### 8.2 Optimization
- [ ] Performance monitoring
- [ ] Debounce/throttle helpers
- [ ] List optimization
- [ ] Image optimization
- [ ] Lazy loading

#### 8.3 Error Handling
- [ ] ErrorBoundary component
- [ ] ScreenErrorBoundary wrapper
- [ ] Error fallback UI
- [ ] Dev mode error details

#### 8.4 Accessibility
- [ ] Screen reader support
- [ ] Dynamic text sizing
- [ ] High contrast mode

---

### Phase 9: Release Preparation
**Status: ⏳ NOT STARTED**

#### 9.1 App Store Assets
- [ ] App metadata configuration
- [ ] App Store description and keywords
- [ ] Privacy policy
- [ ] Terms of service
- [ ] App icons (all sizes)
- [ ] Screenshots for all platforms

#### 9.2 Build Configuration
- [x] GNUmakefile for Linux
- [ ] Xcode project for macOS/iOS
- [ ] Visual Studio project for Windows
- [ ] CI/CD pipeline setup

#### 9.3 Documentation
- [x] README.md
- [x] ARCHITECTURE.md
- [x] IMPLEMENTATION_SUMMARY.md
- [x] PLAN.md (this file)
- [ ] User guide
- [ ] Developer guide

---

## 🔧 Technical Decisions

### Why Objective-C?
- Native performance on Apple platforms
- Cross-platform with GNUStep on Linux
- WinObjC support for Windows
- Mature ecosystem and tooling

### Why SmallStep?
- Unified API across all platforms
- Platform-appropriate directory handling
- Easy to extend with new platforms
- Minimal dependencies

### Architecture
- **Core/**: Shared business logic and models
- **Platform/**: Platform-specific UI implementations
- **SmallStep**: Cross-platform abstraction layer

### EPUB Rendering Strategy
- Use WebView (WKWebView on macOS/iOS, WebKit on Linux)
- Inject custom CSS for foreign word styling
- Use JavaScript bridge for word interaction
- Fall back to native Text components for simple content

---

## 📊 Data Models

### Database Schema (SQLite)

```sql
-- Books table
CREATE TABLE books (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  author TEXT,
  cover_path TEXT,
  file_path TEXT NOT NULL,
  format INTEGER,
  file_size INTEGER,
  added_at INTEGER NOT NULL,
  last_read_at INTEGER,
  progress REAL DEFAULT 0,
  current_location TEXT,
  source_language INTEGER,
  target_language INTEGER,
  proficiency_level INTEGER,
  word_density REAL DEFAULT 0.3
);

-- Vocabulary table
CREATE TABLE vocabulary (
  id TEXT PRIMARY KEY,
  source_word TEXT NOT NULL,
  target_word TEXT NOT NULL,
  source_language INTEGER,
  target_language INTEGER,
  context_sentence TEXT,
  book_id TEXT,
  added_at INTEGER NOT NULL,
  last_reviewed_at INTEGER,
  review_count INTEGER DEFAULT 0,
  ease_factor REAL DEFAULT 2.5,
  interval INTEGER DEFAULT 0,
  status INTEGER DEFAULT 0,
  FOREIGN KEY (book_id) REFERENCES books(id)
);

-- Reading sessions table
CREATE TABLE reading_sessions (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  ended_at INTEGER,
  pages_read INTEGER DEFAULT 0,
  words_revealed INTEGER DEFAULT 0,
  words_saved INTEGER DEFAULT 0,
  FOREIGN KEY (book_id) REFERENCES books(id)
);
```

---

## 🚧 Known Challenges & Solutions

### Challenge 1: EPUB Complexity
**Problem:** EPUBs vary wildly in structure and formatting.
**Status:** Structure in place, needs ZIP/XML parsing library
**Solution:** Use ZIP library (libzip or similar) for extraction, XML parser for structure

### Challenge 2: GNUStep Compatibility
**Problem:** GNUStep doesn't support all modern Objective-C features.
**Status:** ✅ RESOLVED - Fixed nullable, strong, generics, dispatch_once, dictionary literals
**Solution:** Use retain instead of strong, remove nullable, use objectAtIndex instead of subscripting

### Challenge 3: Cross-Platform UI
**Problem:** Different UI frameworks for each platform.
**Status:** 🔶 IN PROGRESS - Linux UI started
**Solution:** Platform-specific UI implementations sharing Core business logic

### Challenge 4: Performance with Large Books
**Problem:** Processing entire books at once is slow.
**Status:** ⏳ PENDING
**Solution:** Process chapters on-demand, cache processed content

### Challenge 5: Offline Functionality
**Problem:** Users expect to read without internet.
**Status:** ✅ RESOLVED - All core features work offline
**Solution:** Translation caching, local storage

---

## 📈 Success Metrics

### MVP Success (Phase 1-4 Release)
- [ ] Can import and read a TXT book
- [ ] Foreign words appear at correct proficiency level
- [ ] Click-to-reveal works smoothly
- [ ] Can save words to vocabulary
- [ ] App doesn't crash on common operations
- [ ] Works on Linux (GNUStep)

### Full Release Success
- [ ] EPUB support
- [ ] All platforms (macOS, iOS, Windows, Linux)
- [ ] Complete vocabulary management
- [ ] SRS review system
- [ ] Statistics tracking
- [ ] Settings and onboarding

---

## 🔗 Resources

### Documentation
- [GNUStep Documentation](http://www.gnustep.org/resources/documentation/)
- [WinObjC Documentation](https://github.com/microsoft/WinObjC)
- [SmallStep Framework](../SmallStep/README.md)

### Word Lists
- [SUBTLEX frequency lists](https://www.ugent.be/pp/experimentele-psychologie/en/research/documents/subtlexus)
- [OpenSubtitles frequency lists](https://github.com/hermitdave/FrequencyWords)

### Design Inspiration
- Apple Books
- Kindle
- Moon+ Reader
- Duolingo (for learning UX)

---

## 📝 Implementation Status Summary

### ✅ Completed
- Core models (Language, Book, Vocabulary, Reader)
- Core services (Parser, Translation, Storage, Export, Manager)
- SmallStep cross-platform layer
- Basic Linux UI (Library window)
- GNUStep compatibility fixes
- Database schema

### 🔶 In Progress
- EPUB parsing (structure ready, needs ZIP/XML library)
- Linux UI (Library screen basic implementation)
- Vocabulary UI
- Enhanced tokenization

### ⏳ Not Started
- Reader screen UI
- Vocabulary screen UI
- Statistics screen UI
- Settings screen UI
- macOS/iOS/Windows UI implementations
- Onboarding flow
- SRS review UI
- EPUB full support

---

## 🌍 Supported Languages (28+)

| Language | Code | Flag | RTL |
|----------|------|------|-----|
| English | en | 🇬🇧 | - |
| Spanish | es | 🇪🇸 | - |
| French | fr | 🇫🇷 | - |
| German | de | 🇩🇪 | - |
| Italian | it | 🇮🇹 | - |
| Portuguese | pt | 🇵🇹 | - |
| Russian | ru | 🇷🇺 | - |
| Greek | el | 🇬🇷 | - |
| Dutch | nl | 🇳🇱 | - |
| Polish | pl | 🇵🇱 | - |
| Turkish | tr | 🇹🇷 | - |
| Japanese | ja | 🇯🇵 | - |
| Chinese | zh | 🇨🇳 | - |
| Korean | ko | 🇰🇷 | - |
| Arabic | ar | 🇵🇸 | ✅ |
| Hebrew | he | 🇮🇱 | ✅ |
| + 12 more... | | | |

---

## 🎯 Next Steps

### Immediate Priorities
1. **Complete EPUB Parsing** - Add ZIP/XML parsing library
2. **Finish Linux UI** - Complete Library, Reader, Vocabulary, Statistics screens
3. **Implement macOS UI** - AppKit-based interface
4. **Implement iOS UI** - UIKit-based interface
5. **Implement Windows UI** - WinObjC-based interface

### Short-term Goals
- Full vocabulary management UI
- SRS review system UI
- Statistics tracking and display
- Settings and onboarding

### Long-term Goals
- Performance optimizations
- Enhanced EPUB support
- Frequency-based word selection
- Advanced tokenization
- Unit and integration tests

---

*Last Updated: January 2026*
