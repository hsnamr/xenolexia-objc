# Xenolexia Objective-C - Work Plan

## Current Status Summary

### ✅ Completed
- Phase 0: Project Setup
- Phase 1: Core Models & Services
- Phase 3: Translation Engine
- Phase 2 (Partial): Library Screen UI (basic implementation)

### 🔶 In Progress
- Phase 2: Library Screen (import blocked by GNUStep block support)
- Phase 5: Vocabulary Manager (structure ready, UI pending)

### ⏳ Not Started
- Phase 4: Reader Screen ⭐ **NEXT PRIORITY**
- Phase 6: Settings & Onboarding
- Phase 7: Platform-Specific UI (macOS/iOS/Windows)
- Phase 8: Polish & Testing
- Phase 9: Release Preparation

## Implementation Priority

### Phase 1: GNUStep Compatibility (Blocking Issue)
**Status**: Required before Reader Screen
**Goal**: Enable book import functionality on Linux/GNUStep

**Tasks**:
1. Add delegate-based methods to `XLManager` for GNUStep compatibility
   - `importBookAtPath:delegate:` (delegate-based alternative to block-based)
   - `processBook:delegate:` (delegate-based alternative)
   - `translateWord:delegate:` (delegate-based alternative)
   - Create `XLManagerDelegate` protocol
2. Update `XLLibraryWindowController` to use delegate-based import
3. Test book import on Linux/GNUStep

**Estimated Time**: 2-3 hours

### Phase 2: Reader Screen Implementation (Primary Goal)
**Status**: Not Started
**Goal**: Implement the core reading experience with foreign word interaction

**Tasks**:

#### 2.1 Basic Reader Window
- [ ] Create `XLReaderWindowController` (Linux/GNUStep)
- [ ] Implement scrollable text view for book content
- [ ] Load and display processed chapter content
- [ ] Implement chapter navigation (prev/next buttons)
- [ ] Chapter list/sidebar for navigation
- [ ] Progress tracking (scroll position + chapter)
- [ ] Auto-save reading position

#### 2.2 Content Processing Integration
- [ ] Integrate with `XLTranslationEngine` to process chapters
- [ ] Display processed content with foreign words marked
- [ ] Handle chapter loading and caching
- [ ] Support for TXT format (EPUB later)

#### 2.3 Foreign Word Interaction ⭐
- [ ] Style foreign words distinctly (underline, color, etc.)
- [ ] Click detection on foreign words
- [ ] Translation popup component:
  - Original word display
  - Translation display
  - Context sentence
  - Proficiency level badge
  - "Save to vocabulary" button
  - "I knew this" button
- [ ] Visual feedback on word interaction
- [ ] Popup positioning and dismissal

#### 2.4 Reader Customization (Basic)
- [ ] Font size adjustment (slider or buttons)
- [ ] Font family selection (Serif, Sans-serif)
- [ ] Line spacing control
- [ ] Theme selection (Light, Dark, Sepia)
- [ ] Settings persistence

#### 2.5 Reading Statistics
- [ ] Track reading session start/end
- [ ] Track time spent reading
- [ ] Count words revealed
- [ ] Count words saved to vocabulary
- [ ] Session summary display

**Estimated Time**: 8-12 hours

### Phase 3: Vocabulary Screen
**Status**: Partially Completed (structure ready)
**Goal**: Complete vocabulary management UI

**Tasks**:
1. Create `XLVocabularyWindowController` (Linux/GNUStep)
2. List all saved words with filtering
3. Search functionality
4. Edit/delete words
5. Export functionality (already implemented in service)
6. Stats header with due count

**Estimated Time**: 4-6 hours

### Phase 4: Settings Screen
**Status**: Not Started
**Goal**: User preferences and configuration

**Tasks**:
1. Create `XLSettingsWindowController` (Linux/GNUStep)
2. Language pair configuration
3. Proficiency level adjustment
4. Word density slider
5. Reader appearance defaults
6. Data export/backup

**Estimated Time**: 3-4 hours

## Technical Considerations

### GNUStep Compatibility
- **No Blocks**: All async operations must use delegate pattern
- **No Modern Objective-C**: Avoid nullable, generics, modern syntax
- **Use retain**: Instead of strong
- **Use objectAtIndex**: Instead of subscripting
- **Keep SmallStep**: All file operations through SmallStep

### Cross-Platform Strategy
- **Core Logic**: Keep in `Core/` directory (shared)
- **UI Implementation**: Platform-specific in `Platform/<platform>/`
- **SmallStep**: Use for all platform-specific operations
- **Design**: Make UI implementations similar but platform-appropriate

### Architecture Decisions
1. **Reader Content**: Use `NSTextView` with attributed strings for styling
2. **Foreign Word Detection**: Use `NSTextView` click detection with character ranges
3. **Translation Popup**: Use `NSPanel` or custom view overlay
4. **Chapter Navigation**: Sidebar or dropdown menu
5. **Settings Storage**: Use `NSUserDefaults` (works on GNUStep)

## Next Steps (Immediate)

1. **Add GNUStep-compatible delegate methods to XLManager** (1-2 hours)
2. **Fix book import in Library screen** (30 minutes)
3. **Implement Reader Screen - Basic** (4-6 hours)
   - Window controller
   - Content display
   - Chapter navigation
   - Progress tracking
4. **Implement Foreign Word Interaction** (3-4 hours)
   - Styling
   - Click detection
   - Translation popup
5. **Add Reader Customization** (2-3 hours)
   - Font settings
   - Theme selection

**Total Estimated Time for Next Phase**: 10-15 hours

## Success Criteria

### MVP (Minimum Viable Product)
- [ ] Can import a TXT book
- [ ] Can open book in reader
- [ ] Can see processed content with foreign words
- [ ] Can click foreign words to see translation
- [ ] Can save words to vocabulary
- [ ] Reading position is saved
- [ ] Works on Linux (GNUStep)

### Phase 4 Complete
- [ ] All MVP criteria met
- [ ] Reader customization works
- [ ] Reading statistics tracked
- [ ] Smooth user experience
- [ ] No crashes on common operations

---

*Generated: January 26, 2026*
