# Xenolexia Objective-C — Remaining Implementation Plan

This plan lists what is still missing in **xenolexia-objc** to reach feature parity with **xenolexia-csharp** and the consolidated requirements. It is ordered by dependency and matches the C# implementation phases where applicable.

**Reference:** [docs/REQUIREMENTS_IMPLEMENTATION_STATUS.md](../docs/REQUIREMENTS_IMPLEMENTATION_STATUS.md), [xenolexia-csharp/IMPLEMENTATION_PLAN.md](../xenolexia-csharp/IMPLEMENTATION_PLAN.md)

---

## Current State (ObjC)

**Implemented:**
- **Core:** Models (Book, Vocabulary, Language, Reader), XLStorageService (books + vocabulary CRUD, due-for-review, recordReview via xenolexia-shared-c SM-2), XLExportService (CSV, Anki, JSON, spec-aligned), XLTranslationEngine, XLBookParserService (TXT full; EPUB structure), reading_sessions + preferences + word_list tables created.
- **Library (Linux):** XLLibraryWindowController (table view, search, import, sort, delete), XLBookDetailWindowController, open book → reader.
- **Reader (Linux):** XLReaderWindowController — load chapters, processBook (TranslationEngine), display processed content with foreign-word styling, click on foreign word → NSAlert popup (original + translation, "Save to Vocabulary" / "I Knew This" / Close), delegate `readerDidRequestSaveWord`; progress bar and chapter navigation; theme/font applied; windowWillClose calls updateProgress + readerDidClose. **Gaps:** Progress not persisted to DB (TODO in code); no reading session start/end; no preferences/session API used.

**Missing (high level):**
1. Storage API for preferences, sessions, and statistics.
2. Reader: persist progress on close; start/end reading session; words revealed/saved counts; load reader settings from preferences.
3. Vocabulary window (list, search, filter, edit, delete, export UI).
4. Review window (flashcards, SM-2 grading: Again/Hard/Good/Easy/Already Knew).
5. Settings window and onboarding flow.
6. Statistics window.
7. Library: full EPUB parsing; optional grid view and book cards with cover.

---

## Phase 0: Storage API (Preferences, Sessions, Statistics)

**Goal:** Expose in XLStorageService the same capabilities as C# IStorageService for preferences, reading sessions, and statistics. Tables already exist; only the API is missing.

### 0.1 Preferences API

- **XLStorageService** (and protocol): Add methods:
  - `getPreferencesWithDelegate:` → read from `preferences` table (keys e.g. `source_lang`, `target_lang`, `proficiency`, `word_density`, `reader_theme`, `reader_font_size`, `onboarding_done`, etc.); map to a **XLUserPreferences** (or equivalent) model; return via delegate.
  - `savePreferences:delegate:` → write key/value pairs into `preferences` (INSERT OR REPLACE).
- **Model:** Add or reuse **XLUserPreferences** with: defaultSourceLanguage, defaultTargetLanguage, defaultProficiencyLevel, defaultWordDensity, readerSettings (XLReaderSettings), hasCompletedOnboarding, notificationsEnabled, dailyGoal. Reuse **XLReaderSettings** from Reader.h.

**Deliverables:** Callers can load and save user preferences; keys and values match C#/spec (snake_case keys, lowercase lang/status where applicable).

### 0.2 Reading Sessions API

- **XLStorageService:** Add methods:
  - `startReadingSessionForBookId:delegate:` → INSERT into `reading_sessions` (id, book_id, started_at = now ms, ended_at = NULL, words_revealed = 0, words_saved = 0); return session id via delegate.
  - `endReadingSessionWithId:wordsRevealed:wordsSaved:delegate:` → UPDATE set ended_at = now, words_revealed, words_saved.
  - (Optional) `getActiveSessionForBookId:delegate:` → SELECT where book_id = ? AND ended_at IS NULL ORDER BY started_at DESC LIMIT 1.
- **XLReadingSession** already exists in Reader.h; ensure it matches DB (id, bookId, startedAt, endedAt, wordsRevealed, wordsSaved, duration).

**Deliverables:** Reader (and later Statistics) can start/end sessions and record words revealed/saved.

### 0.3 Update Book (Progress Persistence)

- **XLStorageService:** Ensure `saveBook:delegate:` (or equivalent update) is used to persist progress. Reader currently has "TODO: Save to storage service" in `updateProgress` and on window close — call existing save book API with updated progress, currentChapter, currentLocation when chapter changes and when window closes.

**Deliverables:** Closing the reader or changing chapter persists book progress to the database.

### 0.4 Statistics API

- **XLStorageService:** Add method:
  - `getReadingStatsWithDelegate:` → aggregate from `reading_sessions` and `vocabulary`: total books read (COUNT DISTINCT book_id from ended sessions), total reading time (SUM of (ended_at - started_at)/1000), total words learned (COUNT from vocabulary WHERE status = 'learned'), current streak (consecutive days with ≥1 ended session from most recent backward), longest streak, words revealed/saved today (SUM where date(ended_at) = today). Return **XLReadingStats** (already in Reader.h).
- **XLReadingStats** already has: totalBooksRead, totalReadingTime, totalWordsLearned, currentStreak, longestStreak, averageSessionDuration, wordsRevealedToday, wordsSavedToday.

**Deliverables:** Statistics window can display all stats from storage.

---

## Phase 1: Reader Completion (Progress, Session, Settings)

**Goal:** Wire the existing reader to the new storage API so that progress is saved, sessions are recorded, and reader appearance can be driven by preferences.

### 1.1 Persist Progress on Exit / Chapter Change

- **XLReaderWindowController:** In `updateProgress` and in `windowWillClose`, call XLStorageService save book (update book) with current progress, currentChapter, currentLocation, lastReadAt so the book row is updated.
- Ensure **XLLinuxApp** (or whoever opens the reader) has access to storage and passes the same XLBook instance so updates are visible after close.

**Deliverables:** Closing the reader or switching chapter saves progress; reopening the book restores position.

### 1.2 Reading Session (Start/End, Words Revealed/Saved)

- **XLReaderWindowController:** On open (after book/chapters loaded), call `startReadingSessionForBookId:delegate:` and keep the session id. Increment a local “words revealed” count when showing the translation popup; increment “words saved” when user taps “Save to Vocabulary”. On window close, call `endReadingSessionWithId:wordsRevealed:wordsSaved:delegate:` with those counts.
- **Delegate:** If using a single delegate for storage, extend it or use a dedicated callback for session start/end completion.

**Deliverables:** Each reader open/close creates or updates a reading session with words revealed/saved.

### 1.3 Reader Settings from Preferences

- On opening the reader (or app startup), load preferences via `getPreferencesWithDelegate:` and apply **XLReaderSettings** (theme, fontFamily, fontSize, lineHeight, margins) to the reader window. **XLReaderWindowController** already has `_settings` and `applyReaderSettings`; set `_settings` from prefs.ReaderSettings (or merge with defaults) before first paint.
- Optional: Settings button in reader could open a small “reader settings” panel or the main Settings window; saving preferences there will apply on next reader open (or, if feasible, live update).

**Deliverables:** Reader appearance (theme, font, spacing) is driven by stored preferences.

---

## Phase 2: Vocabulary Window

**Goal:** Dedicated window/screen to list, search, filter, edit, delete vocabulary items and export (CSV, Anki, JSON). Backend (CRUD, search, export) already exists.

### 2.1 Vocabulary List Window (Linux)

- **XLVocabularyWindowController** (new): Window with NSTableView (or equivalent) bound to a list of XLVocabularyItem. Columns: source word, target word, source lang, target lang, status, book title (optional), added date. Load list via `getAllVocabularyItemsWithDelegate:` (or with search/filter).
- **Search:** Text field; on change call `searchVocabularyWithQuery:delegate:` and refresh table.
- **Filter:** Optional filter by status (new, learning, review, learned) and/or by book.
- **Sort:** Optional sort by date, word, status.

### 2.2 Edit / Delete

- **Edit:** Double-click or “Edit” button opens a sheet/panel to edit source word, target word, context sentence; call `saveVocabularyItem:delegate:` on save.
- **Delete:** “Delete” button or context menu; confirm then call `deleteVocabularyItemWithId:delegate:` and refresh list.

### 2.3 Export

- **Export:** Button “Export” with submenu or panel: CSV, Anki, JSON. Use **XLExportService** (already implemented); choose file path (e.g. NSSavePanel) and write file.
- **Due count:** Optional: show “Due today: N” in window title or toolbar using `getVocabularyDueForReviewWithLimit:delegate:` (count only).

**Deliverables:** User can open Vocabulary window, see all saved words, search/filter, edit/delete, and export in all three formats.

---

## Phase 3: Review Window (SRS Flashcards)

**Goal:** Window that fetches due items, shows one card at a time (front = target word, back = source word + context), and records SM-2 grades (Again, Hard, Good, Easy, Already Knew). Backend (getDueForReview, recordReview) already exists.

### 3.1 Review Window Controller

- **XLReviewWindowController** (new): Window with:
  - **Stats:** “Due today: N”, “Reviewed: M” (N from initial load count, M incremented each time user grades).
  - **Card area:** Show current item’s target word (front). Button “Show answer” or tap to flip.
  - **Back:** Show source word and context sentence (if any).
  - **Grade buttons:** Again (0), Hard (1), Good (3), Easy (4), Already Knew (5). Each calls `recordReviewForItemId:quality:delegate:` then advances to next item; if queue empty, fetch next batch with `getVocabularyDueForReviewWithLimit:delegate:`.
- **No cards due:** When load returns zero items, show message “No cards due right now” and hide card/buttons.

### 3.2 Navigation

- Add a “Review” menu item or toolbar button in the main app (XLLinuxApp) that opens **XLReviewWindowController**. Optionally show due count in menu (e.g. “Review (5)”).

**Deliverables:** User can open Review, see due count, flip card, grade with SM-2; session is tracked (reviewed count); backend unchanged.

---

## Phase 4: Settings Window

**Goal:** Screen to view and edit user preferences (language pair, proficiency, word density, reader defaults, daily goal, notifications). Persist via `savePreferences:delegate:`.

### 4.1 Settings Window Controller

- **XLSettingsWindowController** (new): Form with:
  - **Language pair:** Source language popup, target language popup (use Language enum / display names).
  - **Proficiency:** Popup (Beginner, Intermediate, Advanced).
  - **Word density:** Slider or number (e.g. 0.1–0.5).
  - **Reader defaults:** Theme (Light/Dark/Sepia), font family, font size, line height (and margins if desired).
  - **Daily goal:** Minutes (number field).
  - **Notifications:** Checkbox.
  - **Buttons:** “Save” (call `savePreferences:delegate:`), “Reset to defaults” (fill with defaults then save).
- On show, load current preferences via `getPreferencesWithDelegate:` and populate fields.

**Deliverables:** User can open Settings, change preferences, save; reader and app use these defaults (reader on next open, or live if wired).

---

## Phase 5: Onboarding Flow

**Goal:** First run shows a welcome/onboarding flow; after completion (or skip), set hasCompletedOnboarding and optionally save preferences, then show main UI.

### 5.1 Onboarding Window / Steps

- **XLOnboardingWindowController** (new) or a single window with step views:
  - **Steps:** (1) Welcome + short explanation, (2) Source language, (3) Target language, (4) Proficiency, (5) Word density, (6) “Get started”.
  - **Skip:** “Skip” or “I’ll do this later” sets hasCompletedOnboarding = YES and saves default preferences, then closes onboarding.
  - **Get started:** Collect current step values into XLUserPreferences, set hasCompletedOnboarding = YES, call savePreferences, then close onboarding and show main app (library).
- **App startup:** After app launch, call `getPreferencesWithDelegate:`; if `hasCompletedOnboarding == NO`, show onboarding window (or overlay) instead of library; when onboarding completes, show library (and optionally vocabulary/review/settings in menu).

**Deliverables:** First launch shows onboarding; completion or skip persists and subsequent launches skip onboarding.

---

## Phase 6: Statistics Window

**Goal:** Display reading and vocabulary stats from **getReadingStatsWithDelegate:**.

### 6.1 Statistics Window Controller

- **XLStatisticsWindowController** (new): Window with labels and values for:
  - Total books read  
  - Total reading time (e.g. in minutes)  
  - Total words learned  
  - Current streak (days)  
  - Longest streak (days)  
  - Words revealed today  
  - Words saved today  
  - Average session duration (e.g. minutes)
- **Refresh:** Button to reload stats (call `getReadingStatsWithDelegate:` again).
- On show, load once (or on refresh).

**Deliverables:** User can open Statistics and see all stats; data comes from reading_sessions and vocabulary.

---

## Phase 7: Library Enhancements (Optional)

**Goal:** Improve library UX and format support; not required for parity with C# “current” feature set.

### 7.1 EPUB Full Parsing

- **XLBookParserService / XLEpubParser:** Implement full EPUB parsing (ZIP extraction, XML parsing for container, OPF, NCX/html) so chapter content is available for reading. C# uses VersOne.Epub; ObjC may use a small ZIP + XML parser or minimal dependency.
- **Deliverables:** EPUB books can be opened and read chapter-by-chapter like TXT.

### 7.2 Library UI Improvements

- **Grid view:** Optional grid of book cards (cover, title, progress) in addition to table view.
- **Book cards:** Show cover thumbnail if available (coverPath), title, author, progress %.
- **Format support:** FB2, MOBI (optional; lower priority).

---

## Implementation Order (Suggested)

| Order | Phase | Depends on |
|-------|--------|------------|
| 1 | **Phase 0** (Storage API: preferences, sessions, stats, update book) | None |
| 2 | **Phase 1** (Reader: persist progress, session, reader settings from prefs) | Phase 0 |
| 3 | **Phase 2** (Vocabulary window) | None (backend exists) |
| 4 | **Phase 3** (Review window) | None (backend exists) |
| 5 | **Phase 4** (Settings window) | Phase 0 |
| 6 | **Phase 5** (Onboarding) | Phase 0 |
| 7 | **Phase 6** (Statistics window) | Phase 0 |
| 8 | **Phase 7** (Library/EPUB enhancements) | Optional |

---

## Summary Checklist

- [ ] **Phase 0.1:** XLStorageService: getPreferences, savePreferences; XLUserPreferences model.
- [ ] **Phase 0.2:** XLStorageService: startReadingSession, endReadingSession, getActiveSessionForBook (optional).
- [ ] **Phase 0.3:** Reader: call save book on progress change and window close.
- [ ] **Phase 0.4:** XLStorageService: getReadingStats; use XLReadingStats.
- [ ] **Phase 1.1:** Reader: persist progress on close and chapter change.
- [ ] **Phase 1.2:** Reader: start/end reading session, track words revealed/saved.
- [ ] **Phase 1.3:** Reader: load reader settings from preferences.
- [ ] **Phase 2:** XLVocabularyWindowController: list, search, filter, edit, delete, export.
- [ ] **Phase 3:** XLReviewWindowController: flashcards, SM-2 grading, due/reviewed counts.
- [ ] **Phase 4:** XLSettingsWindowController: form, save/reset preferences.
- [ ] **Phase 5:** XLOnboardingWindowController: steps, skip, get started, hasCompletedOnboarding.
- [ ] **Phase 6:** XLStatisticsWindowController: display all stats, refresh.
- [ ] **Phase 7 (optional):** Full EPUB parsing; library grid/cards.

---

## Notes

- **Delegate vs blocks:** ObjC codebase uses delegates for async storage callbacks (GNUStep-friendly). New APIs should follow the same pattern (e.g. `getPreferencesWithDelegate:` with a method like `storageService:didGetPreferences:error:`).
- **C# parity:** After Phases 0–6, ObjC will match C# for: reader (progress, session, settings), vocabulary UI, review UI, settings, onboarding, statistics. Phase 7 aligns with optional C#/TypeScript enhancements.
- **Platform:** Plan is written for Linux (GNUStep); same Core APIs can be used by macOS/iOS/Windows UI when those are implemented.
