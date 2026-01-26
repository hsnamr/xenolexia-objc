# EPUB Reading Implementation

## Overview

EPUB reading functionality has been implemented using **libzip** (C library) for ZIP extraction and **libxml2** (C library) for XML parsing. Both libraries are free, open-source, and cross-platform.

## Libraries Used

### libzip
- **License**: BSD 3-Clause
- **Website**: https://libzip.org/
- **Purpose**: Extract files from EPUB ZIP archives
- **Availability**: 
  - Linux: `libzip-dev` package
  - macOS: Available via Homebrew
  - Windows: Available via vcpkg

### libxml2
- **License**: MIT
- **Website**: http://www.xmlsoft.org/
- **Purpose**: Parse XML files (container.xml, OPF, HTML chapters)
- **Availability**: 
  - Linux: `libxml2-dev` package (usually pre-installed)
  - macOS: Pre-installed
  - Windows: Available via vcpkg

## Implementation Details

### Files Created

1. **XLEpubParser.h/m** - EPUB parser class
   - `parseEpubAtPath:error:` - Main parsing method
   - `extractFile:fromEpub:error:` - Extract file from ZIP
   - `getOpfPathFromContainer:error:` - Parse container.xml
   - `parseOpfFile:basePath:error:` - Parse OPF file
   - `parseChapterContent:error:` - Parse HTML/XHTML chapters

### EPUB Structure Handling

The parser handles the standard EPUB structure:

1. **META-INF/container.xml**
   - Locates the OPF file path
   - Handles EPUB 2 and EPUB 3 formats

2. **OPF File (package.opf)**
   - Extracts metadata (title, author, description, etc.)
   - Parses manifest (list of all files)
   - Parses spine (reading order)
   - Builds table of contents

3. **Chapter Files**
   - Extracts HTML/XHTML files from ZIP
   - Parses content (extracts body or full HTML)
   - Handles relative paths correctly
   - Counts words for statistics

### Features

✅ **EPUB 2 Support**
- Parses OPF files
- Extracts chapters from manifest/spine
- Basic TOC support

✅ **EPUB 3 Support**
- Parses nav.xhtml for TOC
- Handles modern EPUB structure

✅ **Error Handling**
- Comprehensive error reporting
- Graceful fallbacks
- Memory leak prevention

✅ **Cross-Platform**
- Works on Linux (GNUStep)
- Should work on macOS/iOS (with proper linking)
- Should work on Windows (with WinObjC)

## Build Configuration

### Linux (GNUStep)

The GNUmakefile has been updated to:
- Link against `-lzip` and `-lxml2`
- Include headers from `/usr/include/libzip` and `/usr/include/libxml2`
- Include all necessary service files

**Installation Requirements:**
```bash
sudo apt-get install libzip-dev libxml2-dev
```

### macOS/iOS

For Xcode projects, add:
- **Link Libraries**: `libzip` and `libxml2`
- **Header Search Paths**: Include libzip and libxml2 headers
- **Library Search Paths**: Point to library locations

### Windows (WinObjC)

Similar configuration needed:
- Link against libzip and libxml2
- Include proper header paths

## Usage

The EPUB parser is automatically used when importing EPUB files:

```objc
XLManager *manager = [XLManager sharedManager];
[manager importBookAtPath:@"/path/to/book.epub" delegate:delegate];
```

The parser:
1. Opens EPUB as ZIP archive
2. Reads container.xml to find OPF file
3. Parses OPF for metadata and manifest
4. Extracts chapters in reading order
5. Returns `XLParsedBook` with all chapters and metadata

## Limitations & Future Improvements

### Current Limitations

1. **TOC Parsing**
   - Basic support for EPUB 3 nav.xhtml
   - EPUB 2 toc.ncx not yet fully implemented
   - Nested TOC items need better handling

2. **Chapter Content**
   - Extracts body content or full HTML
   - Doesn't handle embedded images/resources yet
   - CSS styling not preserved

3. **Error Recovery**
   - Some EPUBs with non-standard structure may fail
   - Better error messages needed

### Future Improvements

1. **Enhanced TOC**
   - Full EPUB 2 toc.ncx support
   - Better nested structure handling
   - Chapter navigation from TOC

2. **Resource Handling**
   - Extract and handle images
   - Handle CSS files
   - Handle fonts

3. **Content Processing**
   - Better HTML cleaning
   - Preserve formatting
   - Handle footnotes/endnotes

4. **Performance**
   - Cache parsed OPF
   - Lazy chapter loading
   - Background processing

## Testing

To test EPUB parsing:

1. **Install Dependencies** (Linux):
   ```bash
   sudo apt-get install libzip-dev libxml2-dev
   ```

2. **Build Project**:
   ```bash
   cd Platform/Linux
   make
   ```

3. **Test with EPUB File**:
   - Import an EPUB file through the Library screen
   - Verify chapters are extracted correctly
   - Check metadata is parsed
   - Test reading in the Reader screen

## Known Issues

1. **Namespace Handling**
   - Some XPath expressions may need adjustment for different EPUB versions
   - Namespace-aware parsing could be improved

2. **Path Resolution**
   - Relative paths with `../` are handled but could be more robust
   - Some EPUBs use absolute paths that may not work

3. **Memory Management**
   - Uses manual memory management (retain/release)
   - Should be tested for leaks with Instruments/Valgrind

## Dependencies

- **libzip**: >= 1.0 (tested with 1.7+)
- **libxml2**: >= 2.9 (most systems have 2.9+)

## License Compatibility

Both libraries are compatible with the project's license:
- **libzip**: BSD 3-Clause (permissive)
- **libxml2**: MIT (permissive)

---

*Implementation Date: January 26, 2026*
