# Xenolexia ObjC — Phased Plan for Feature Parity with Electron

This document outlines a **phased plan** to bring **xenolexia-objc** to **feature parity** with **xenolexia-typescript (Electron)**. The plan assumes Linux (GNUStep) as the primary target first; macOS/iOS/Windows can follow using the same Core and analogous UI.

---

## 1. Electron reference (feature set)

| Area | Electron (v1 complete) |
|------|------------------------|
| **Library** | Import from file, discover (Gutenberg, Standard Ebooks, Open Library), grid/list toggle, book detail modal (metadata, progress, Read/Delete). |
| **Reader** | Open book, chapter navigation, TOC; word replacement (TranslationEngine, density + proficiency); hover/tap-to-reveal; translation popup (original, context, Save to vocabulary); progress and session persistence; reader customization (theme, font, line spacing). |
| **Vocabulary** | List, search, filter, word detail modal, edit/delete, export (CSV, Anki, JSON); getDueForReview, recordReview (SM-2). |
| **Review** | Flashcard UI, SM-2 grading (Again/Hard/Good/Easy/Already Knew), “due today” count, load due from repository. |
| **Settings / Onboarding** | Language pair, proficiency, word density, daily goal; reader defaults (theme, font, spacing); first-run onboarding; persistence. |
| **Statistics** | Reading stats (books read, time, words learned, streaks, words revealed/saved today); “reading over time” bar chart (last 7 days). |
| **Polish** | Keyboard shortcuts (e.g. Ctrl+1–6 for tabs), window state persistence, system tray (Show/Hide, Quit), E2E tests. |
| **Core / Spec** | Schema (books, vocabulary, reading_sessions, preferences, word_list); export lowercase lang/status; SM-2. |

---

## 2. Current ObjC state vs Electron

| Area | ObjC today | Gap |
|------|------------|-----|
| **Library** | XLStorageService (books CRUD), XLBookParserService (TXT full; EPUB structure only); Linux Library window (table view, search, import, sort, delete, book detail). | EPUB full parsing (ZIP/XML); FB2/MOBI; **grid/list toggle**; **book cards with cover** (table only). |
| **Reader** | XLTranslationEngine, XLTranslationService; **no reader window**. | **Reader window**: chapter load, word replacement in UI, **tap/hover-to-reveal**, **translation popup**, **save to vocabulary**, **progress/session persistence**, **reader customization**. |
| **Vocabulary** | XLStorageService (vocabulary CRUD, getDueForReview, recordReview); XLExportService (CSV, Anki, JSON). **No vocabulary window.** | **Vocabulary window**: list, search, filter, edit/delete, export UI, “due today” header. |
| **Review** | Backend (getDueForReview, recordReview) ready. **No review UI.** | **Review window**: flashcard UI, SM-2 grading (Again/Hard/Good/Easy/Already Knew). |
| **Settings / Onboarding** | **Not started.** | **Settings window**: language pair, proficiency, density, reader defaults, daily goal; persistence. **Onboarding**: first-run flow (welcome, language pair, proficiency, density, Get started); skip. |
| **Statistics** | **No statistics window.** | **Statistics window**: reading stats (books read, time, words learned, streaks, today); “reading over time” chart (last 7 days). |
| **Polish** | — | Keyboard shortcuts, window state persistence, system tray (if supported on GNUStep). |
| **Core / Spec** | SQLite schema, SM-2 via xenolexia-shared-c, export spec-aligned. | None for parity; optional: per-day stats API for chart. |

**Conclusion:** Core backend (storage, export, SM-2, translation engine) is in place. Gaps are **Reader UI**, **Vocabulary UI**, **Review UI**, **Settings**, **Onboarding**, **Statistics UI**, **Library enhancements** (grid/list, optional EPUB/FB2/MOBI), and **Polish**.

---

## 3. Phased plan

Phases are ordered by **dependency**: Reader depends on Library; Vocabulary/Review benefit from Reader (save-from-reader); Settings/Onboarding and Statistics can be built in parallel once Core is used by UI.

---

### Phase 1: Reader (Phase 4 in PLAN.md)

**Status: Implemented.** Reader window, chapter content with word replacement, click-to-reveal, translation popup (original + context + Save / I Knew This), save to vocabulary with context, progress and session persistence, reader customization from preferences.

**Goal:** Reader window with chapter content, word replacement, tap/hover-to-reveal, translation popup, save to vocabulary, progress and session persistence, reader customization.

| Step | Task | Notes |
|------|------|--------|
| 1.1 | **Reader window** | Implement or complete **XLReaderWindowController** (Linux/GNUStep): window with chapter content area. Load book and chapter list from XLBookParserService / XLStorageService. |
| 1.2 | **Chapter content + word replacement** | Use **XLTranslationEngine** to process chapter text (density + proficiency). Render processed content with foreign words styled distinctly (e.g. underline, color). |
| 1.3 | **Tap/hover-to-reveal** | On click or hover of a foreign word, show translation popup (original word, optional context). Use hit-testing or attributed string with custom views; on Linux consider NSTextView with clickable ranges or WebView with injected script. |
| 1.4 | **Translation popup** | Popup/tooltip: original word, context sentence, **Save to vocabulary** button, optional “I knew this”. Save calls XLStorageService addVocabulary; track “revealed” for session stats. |
| 1.5 | **Progress and session** | On chapter change: persist current chapter, position, progress (XLStorageService updateBook). On reader open: start reading session (startSession); on close: end session with words revealed/saved (endSession). |
| 1.6 | **Reader customization** | Reader theme (light/dark/sepia), font family, font size, line spacing. Load/save from preferences (or Settings when implemented); apply in reader view. |

**Exit criteria:** User can open a book from Library, read chapter content with foreign words styled, tap/hover to see original and save to vocabulary; progress and session are persisted; reader appearance can be customized.

**Dependencies:** Library window (existing), XLBookParserService (TXT; EPUB optional), XLTranslationEngine, XLStorageService.

---

### Phase 2: Vocabulary window

**Status: Implemented.** Vocabulary window with list, search, filter, edit/delete, export UI, "due today" header, and Review button.

**Goal:** Vocabulary window with list, search, filter, edit/delete, export UI, and “due today” header.

| Step | Task | Notes |
|------|------|--------|
| 2.1 | **Vocabulary window** | Implement or complete **XLVocabularyWindowController** (Linux): window with table or list of vocabulary items. Load via XLStorageService getVocabulary (or equivalent). |
| 2.2 | **List + search/filter** | Display source word, target word, status, book, date. Search box to filter by source/target text. Optional filter by status (new, learning, review, learned) and/or book. |
| 2.3 | **Edit/delete** | Row or detail view: edit source/target/context; delete word. Call XLStorageService updateVocabulary, deleteVocabulary. |
| 2.4 | **Export UI** | Button or menu: export as CSV, Anki, or JSON. Use **XLExportService**; choose format and file path (platform file dialog). |
| 2.5 | **“Due today” header** | Show count of items due for review (getVocabularyDueForReview or equivalent count). Link or button to open Review window. |

**Exit criteria:** User can open Vocabulary window, see all saved words, search/filter, edit/delete, export to CSV/Anki/JSON, and see “due today” count.

**Dependencies:** XLStorageService, XLExportService (existing).

---

### Phase 3: Review window

**Status: Implemented.** Review window with flashcard UI, SM-2 grading (Again/Hard/Good/Easy/Already Knew), due count, and "No cards due" state.

**Goal:** Review window with flashcard UI and SM-2 grading (Again/Hard/Good/Easy/Already Knew).

| Step | Task | Notes |
|------|------|--------|
| 3.1 | **Review window** | Implement or complete **XLReviewWindowController** (Linux): window with flashcard area (front/back). |
| 3.2 | **Load due items** | On show or refresh: call XLStorageService getVocabularyDueForReviewWithLimit; display first item as “front” (e.g. target word). |
| 3.3 | **Flip card** | Button or tap: show “back” (source word, context). |
| 3.4 | **Grading buttons** | Buttons: Again, Hard, Good, Easy, Already Knew. Map to quality (e.g. 0–5); call XLStorageService recordReviewForItemId with quality. Advance to next card; when none left, show “No cards due” or similar. |
| 3.5 | **Due count** | Display “Due today: N” (and optionally “Reviewed: M” in session). |

**Exit criteria:** User can open Review window, see due cards, flip to back, grade with SM-2 buttons, and proceed until no cards due.

**Dependencies:** XLStorageService (getDueForReview, recordReview) and xenolexia-shared-c SM-2 (existing).

---

### Phase 4: Settings and Onboarding

**Status: Implemented.** Settings window (language pair, proficiency, density, reader defaults, daily goal) with persistence; onboarding flow (welcome, source/target language, proficiency, word density, Get started, Skip); onboarding gate on launch; Reader applies prefs when processing chapters and when opening Settings from Reader.

**Goal:** Settings window (language pair, proficiency, density, reader defaults, daily goal) and first-run onboarding; persistence.

| Step | Task | Notes |
|------|------|--------|
| 4.1 | **Settings window** | Implement or complete **XLSettingsWindowController** (Linux): form with language pair (source/target), proficiency level, word density, reader defaults (theme, font, line spacing), daily goal. |
| 4.2 | **Persistence** | Load/save preferences via XLStorageService (preferences table or equivalent). Apply reader defaults when opening Reader; apply language/density when processing content. |
| 4.3 | **Onboarding window** | Implement or complete **XLOnboardingWindowController**: first-run flow — welcome, select source language, target language, proficiency, word density, “Get started”. Skip button. |
| 4.4 | **Onboarding gate** | On app launch: if “onboarding completed” not set in preferences, show onboarding window first; on completion set flag and show main (Library) window. |

**Exit criteria:** User can change settings and see them persist; first-run user sees onboarding and can complete or skip.

**Dependencies:** XLStorageService preferences (existing or extend schema).

---

### Phase 5: Statistics window

**Status: Implemented.** Statistics window with reading stats and 7-day "reading over time" bar chart (getWordsRevealedByDay).

**Goal:** Statistics window with reading stats and “reading over time” chart (last 7 days).

| Step | Task | Notes |
|------|------|--------|
| 5.1 | **Statistics window** | Implement or complete **XLStatisticsWindowController** (Linux): display books read, total reading time, words learned, current/longest streak, words revealed/saved today, average session. |
| 5.2 | **Stats from storage** | Use XLStorageService (and reading_sessions/vocabulary) to compute or expose: total books, reading time, words learned (e.g. status=learned count), streaks, today’s revealed/saved. Add session statistics API if not present. |
| 5.3 | **“Reading over time” chart** | Last 7 days: words revealed per day. Add per-day query to storage (e.g. getWordsRevealedByDay lastDays) or derive from reading_sessions; display as bar chart (simple view or custom draw). |

**Exit criteria:** User can open Statistics window and see aggregate stats and a 7-day “reading over time” chart.

**Dependencies:** XLStorageService (existing; possibly extend with getWordsRevealedByDay or equivalent).

---

### Phase 6: Library enhancements (optional for parity)

**Status: Implemented.** Grid/list toggle and book cards with cover already present; library view mode (grid vs list) persisted via getLibraryViewMode/saveLibraryViewMode. EPUB full parsing and FB2/MOBI deferred.

**Goal:** Grid/list toggle and book cards with cover; optionally full EPUB and FB2/MOBI.

| Step | Task | Notes |
|------|------|--------|
| 6.1 | **Grid/list toggle** | Add view mode (grid vs list) to Library window; list = current table; grid = card layout with cover placeholder, title, author, progress. Persist preference if desired. |
| 6.2 | **Book cards with cover** | In grid mode, show cover image (or placeholder) per book; reuse metadata from XLBook. |
| 6.3 | **EPUB full parsing** (optional) | Add ZIP/XML parsing for EPUB (extract, parse OPF/NCX, chapters). Use in XLBookParserService so EPUB books can be opened in Reader. |
| 6.4 | **FB2/MOBI** (optional) | If desired, add parsers for FB2 and MOBI; otherwise defer. |

**Exit criteria:** User can switch Library between table and grid; grid shows book cards with cover; optionally EPUB (and FB2/MOBI) import and read.

**Dependencies:** Existing Library window; XLBookParserService; cover path in Book model.

---

### Phase 7: Polish (optional)

**Status: Implemented.** Main menu with Ctrl+1..5 (Library, Vocabulary, Review, Settings, Statistics) and Quit; Library window frame saved to ~/.xenolexia/window_state.plist and restored on launch; system tray (Show/Hide, Quit) on macOS only—N/A on GNUStep/Linux.

**Goal:** Keyboard shortcuts, window state persistence, system tray (if supported).

| Step | Task | Notes |
|------|------|--------|
| 7.1 | **Keyboard shortcuts** | Global shortcuts to switch context (e.g. Library, Vocabulary, Review, Settings, Statistics). On Linux/GNUStep, use NSMenu key equivalents or window-level key handlers. |
| 7.2 | **Window state persistence** | Save main window position, size, maximized state to preferences or file; restore on next launch. |
| 7.3 | **System tray** | If GNUStep/AppKit supports tray icon: add icon, menu “Show/Hide”, “Quit”. Otherwise document as N/A on Linux. |

**Exit criteria:** Shortcuts work; window state restores; tray present where supported.

---

### Phase 8: Testing and documentation (optional)

**Goal:** Smoke test checklist and optional E2E/automated tests.

| Step | Task | Notes |
|------|------|--------|
| 8.1 | **Smoke test checklist** | Create **docs/SMOKE_TEST_CHECKLIST.md** (Linux): launch, onboarding, library import, reader, vocabulary, review, export, settings, statistics. |
| 8.2 | **E2E or manual test** | Document how to run a full pass; add automated UI tests if feasible on GNUStep. |

**Exit criteria:** Checklist exists and is runnable; release can be validated manually (or via E2E).

---

## 4. Suggested order and effort

| Phase | Description | Effort | Suggested order |
|-------|-------------|--------|------------------|
| **1** | Reader (window, content, reveal, popup, save, progress, session, customization) | High | First |
| **2** | Vocabulary window (list, search, filter, edit, delete, export, due header) | Medium | Second |
| **3** | Review window (flashcards, SM-2 grading) | Medium | Third |
| **4** | Settings and Onboarding | Medium | Fourth |
| **5** | Statistics window (stats + chart) | Medium | Fifth |
| **6** | Library enhancements (grid/list, cards, optional EPUB/FB2/MOBI) | Medium–High | Sixth |
| **7** | Polish (shortcuts, window state, tray) | Low–Medium | Seventh |
| **8** | Smoke test checklist and optional E2E | Low | Last |

**Critical path:** Phase 1 (Reader) unblocks the full “read → save → review” flow; Phases 2–5 complete feature parity with Electron for core flows. Phases 6–8 are enhancements and polish.

**Rough total (Phases 1–5):** on the order of 2–4 months for one developer, depending on GNUStep/AppKit familiarity and EPUB/WebView choices. Phase 6 (EPUB full) can add 2–4 weeks if done in ObjC.

---

## 5. Out of scope for this plan

- **macOS/iOS/Windows UI:** This plan focuses on **Linux (GNUStep)** parity with Electron. Once Linux is complete, macOS (AppKit), iOS (UIKit), and Windows (WinObjC) can be added as separate platform phases reusing Core and mirroring the same screens.
- **Discovery (online sources):** Electron has “discover” (Gutenberg, Standard Ebooks, Open Library). ObjC can add the same in a later phase; not required for minimum parity if “import from file” is sufficient initially.
- **Frequency-based word selection:** Optional enhancement; not required for Electron parity.

---

## 6. References

- **Electron feature set:** `xenolexia-typescript/electron-app/PLAN.md`, `electron-app/docs/SMOKE_TEST_CHECKLIST.md`
- **ObjC current plan:** `xenolexia-objc/PLAN.md` (Phases 4, 5, 6, 7)
- **Requirements comparison:** repo root `docs/REQUIREMENTS_IMPLEMENTATION_STATUS.md`
- **Monorepo roadmap:** `docs/ROADMAP.md`

---

*This plan is for bringing xenolexia-objc (Linux/GNUStep) to feature parity with xenolexia-typescript (Electron). After Phases 1–5, ObjC will match Electron on Reader, Vocabulary, Review, Settings, Onboarding, and Statistics; Phase 6 adds Library grid/list and optional formats; Phases 7–8 add polish and testing.*
