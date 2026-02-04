# Xenolexia-ObjC: FOSS Library Review

This document reviews the xenolexia-objc implementation and recommends replacing custom or fragile code with reputable FOSS C/C++/Objective-C libraries where appropriate.

---

## Already Using FOSS Libraries

| Area | Library | License | Notes |
|------|---------|---------|--------|
| **EPUB** | libzip + libxml2 | BSD / MIT | Core/Native XLEpubReader |
| **FB2** | libxml2 | MIT | Core/Native XLFB2Reader |
| **PDF** | MuPDF (optional) | AGPL | Core/Native XLPDFReader |
| **MOBI** | libmobi (optional) | LGPL | Core/Native XLMobiReader |
| **JSON export** | Foundation NSJSONSerialization | — | XLExportService |
| **SQLite** | FMDB + sqlite3 | MIT / Public domain | XLStorageService (FMDB) |
| **File system** | SmallStep (SSFileSystem) | — | Cross-platform paths and I/O |
| **SM-2** | In-house ObjC (XLSm2) | — | Small, spec-aligned; no need to replace |

---

## Recommendations (Prioritized)

### 1. **SQLite: Use proper `sqlite3.h` or FMDB** (High)

- **Current:** XLStorageService redeclares sqlite3 types and functions in the .m file (`#ifndef SQLITE_OK` block) for “GNUStep compatibility,” then uses raw `sqlite3_*` calls. This is brittle and duplicates the official API.
- **Options:**
  - **A.** Use the real `#import <sqlite3.h>` (or `#include`) and ensure the build has `-I` for the system SQLite headers (e.g. `libsqlite3-dev`). Prefer this if no GNUStep-specific issue exists.
  - **B.** **FMDB** (ObjC wrapper, MIT): Reduces boilerplate, improves readability, and centralizes error handling. Very widely used. Add FMDB as vendored source or SPM/CocoaPods and refactor XLStorageService to use `FMDatabase` / `FMResultSet`. Verify FMDB builds on GNUStep (Foundation + sqlite3 only).
- **Action:** Prefer fixing the include path to use real sqlite3; optionally adopt FMDB for a cleaner service layer.

### 2. **EPUB chapter content: HTML → plain text via libxml2** (High)

- **Current:** XLEpubParser `stringFromChapterData:` only decodes UTF-8 (or ISO Latin-1). EPUB chapters are often XHTML; raw markup is then used as “content” (e.g. for word counts or display).
- **Recommendation:** Use **libxml2** (already linked) to parse HTML and extract text (strip tags, resolve entities). Libxml2’s `htmlReadMemory` + a small recursive text-node walk is a standard, robust approach.
- **Action:** Add an HTML-to-text helper (e.g. in XLEpubParser or a small `XLHTMLToText` using libxml2) and use it when chapter data looks like HTML (e.g. contains `'<'` and `'>'`).

### 3. **Downloads: libcurl** (High)

- **Current:** DownloadService is a stub; comment says “NSURLSession with blocks not supported in GNUStep” and “would require delegate-based NSURLConnection.”
- **Recommendation:** Use **libcurl** (C, MIT-style license). It is the standard portable HTTP(S) library and works on Linux/GNUStep, macOS, and iOS. Implement the actual download (e.g. `curl_easy_*`) in a small C helper or ObjC wrapper that writes to a path.
- **Action:** Implement `DownloadService` using libcurl (system `-lcurl`); keep the same ObjC API (`downloadFrom:toDirectory:` or equivalent).

### 4. **CSV export: CHCSVParser / CHCSVWriter** (Medium)

- **Current:** XLExportService builds CSV manually with `escapeCSV:` and `appendFormat:`. Correct for the current spec but easy to get wrong with edge cases (embedded newlines, odd quotes, etc.).
- **Recommendation:** **CHCSVParser** (davedelong/CHCSVParser, ObjC): Provides CHCSVWriter for writing. Well-used, FOSS. Use it for CSV export so all escaping and formatting are handled by the library.
- **Action:** Add CHCSVParser (vendored or dependency) and replace manual CSV building in `exportToCSV:` with CHCSVWriter (or equivalent). Keep JSON as-is (NSJSONSerialization).

### 5. **Translation backend: FOSS APIs** (Medium)

- **Current:** XLTranslationService delegates to TranslationService, which uses Microsoft Translate (MSTranslateAccessTokenRequester, MSTranslateVendor).
- **Recommendation:** Add support for a FOSS translation API (e.g. **LibreTranslate** or **Apertium**) as an alternative backend, configurable so users can choose FOSS when available.
- **Action:** Define a small translation-provider interface and implement one FOSS backend (e.g. LibreTranslate HTTP API) alongside the existing Microsoft path.

### 6. **Word frequency / tokenization** (Low)

- **Current:** XLTranslationEngine uses simple tokenization (NSCharacterSet split) and a density-based selection; comment says “frequency filtering would require a database.”
- **Recommendation:** For frequency-based selection, use **existing FOSS word-frequency lists** (e.g. standard lists per language as data files) rather than implementing from scratch. No need for a heavy NLP library for this use case.
- **Action:** Optional: add a small module that loads a frequency list (e.g. CSV/JSON) and filters `selectWordsToReplace` by rank when a list is available.

### 7. **DictionaryService / string cleanup** (Low)

- **Current:** NSUserDefaults plus simple string manipulation (remove symbols/punctuation via NSCharacterSet). Lightweight and adequate.
- **Recommendation:** Keep as-is. No need to introduce a library for this.

### 8. **Anki export** (Low)

- **Current:** Custom TSV format with a few header lines; straightforward string building.
- **Recommendation:** Keep as-is unless you need full Anki package (`.apkg`) generation, in which case you could look for an existing FOSS Anki library.

---

## Summary Table

| Component | Current | Recommended FOSS | Priority |
|-----------|---------|------------------|----------|
| SQLite | FMDB (done) | — | High ✓ |
| EPUB chapter text | libxml2 HTML→text (done) | — | High ✓ |
| HTTP download | libcurl (done) | — | High ✓ |
| CSV export | CHCSVWriter (done) | — | Medium ✓ |
| Translation | Microsoft + LibreTranslate (done) | — | Medium ✓ |
| Word frequency | None | FOSS word lists (data); optional | Low |
| JSON export | NSJSONSerialization | Keep | — |
| SM-2 | XLSm2 (in-house) | Keep (tiny, spec-aligned) | — |

---

## Implementation Status

- **HTML-to-text (libxml2):** Implemented in XLEpubParser. When chapter data looks like HTML (contains `<`/`>` in the first 2KB), it is parsed with libxml2 `htmlReadMemory` and text nodes are extracted; otherwise UTF-8/ISO Latin-1 decode is used.
- **DownloadService (libcurl):** Implemented. `downloadFrom:toDirectory:` uses libcurl (FOSS) to perform HTTP(S) download and write to a file in the given directory. Link with `-lcurl`.
- **SQLite (FMDB):** XLStorageService uses **FMDB** (FOSS, MIT) for all database access. FMDatabase/FMResultSet replace raw sqlite3_* calls. Build includes ThirdParty/fmdb and `-lsqlite3`.
- **CSV (CHCSVParser):** XLExportService uses **CHCSVWriter** (CHCSVParser, FOSS) for CSV export. Export builds CSV via `CHCSVWriter` with `outputStreamToMemory`, so escaping and formatting are handled by the library.
- **Translation (LibreTranslate):** XLTranslationService supports a FOSS backend via **XLLibreTranslateClient** (LibreTranslate HTTP API over libcurl). Set `translationBackend = XLTranslationBackendLibreTranslate` and optionally `libretranslateBaseURL` (default `https://libretranslate.com`) to use it; otherwise the legacy Microsoft path is used.
