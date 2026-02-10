# DDx Psychiatry -- iOS Architecture Document

> Design specification for a Skyrim-themed psychiatric differential diagnosis quest-tracker app
> built with SwiftUI, SwiftData, and atmospheric dark UI.
>
> **This is a design document only. No Swift source files are produced here.**

---

## Table of Contents

1. [Xcode Project Structure](#1-xcode-project-structure)
2. [SwiftUI View Hierarchy](#2-swiftui-view-hierarchy)
3. [Data Models (SwiftData)](#3-data-models-swiftdata)
4. [Visual Style Mapping -- Skyrim to iOS](#4-visual-style-mapping----skyrim-to-ios)
5. [Color Asset Definitions](#5-color-asset-definitions)
6. [Sound Integration Points](#6-sound-integration-points)
7. [Haptic Feedback Mapping](#7-haptic-feedback-mapping)
8. [Navigation Flow Diagram](#8-navigation-flow-diagram)

---

## 1. Xcode Project Structure

Every file that must exist in the Xcode project, grouped by purpose.

```
DDxPsychiatry/
│
├── App/
│   └── DDxPsychiatryApp.swift              // @main entry point, ModelContainer setup, audio session config
│
├── Models/
│   ├── Quest.swift                          // @Model -- primary diagnosis/quest entity
│   ├── Objective.swift                      // @Model -- individual diagnostic criterion / sub-task
│   └── QuestCategory.swift                  // enum QuestCategory: String, Codable, CaseIterable
│
├── Stores/
│   └── QuestStore.swift                     // @Observable -- business logic, filtering, sorting, completion
│
├── Views/
│   ├── ContentView.swift                    // Root TabView (3 tabs)
│   │
│   ├── QuestList/
│   │   ├── QuestListView.swift             // NavigationStack + sectioned List + .searchable
│   │   └── QuestRow.swift                  // Single row: title, category badge, status indicator
│   │
│   ├── QuestDetail/
│   │   ├── QuestDetailView.swift           // Full quest breakdown with objectives checklist
│   │   └── ObjectiveRow.swift              // Single objective row with completion state
│   │
│   ├── QuestForm/
│   │   └── QuestFormView.swift             // Sheet: create / edit quest with form fields
│   │
│   ├── Archive/
│   │   └── ArchiveView.swift               // NavigationStack + List of completed quests
│   │
│   └── Profile/
│       └── ProfileView.swift               // Stats, streaks, settings, sound/haptic toggles
│
├── Components/
│   ├── SkyrimSectionHeader.swift           // ALL-CAPS, wide tracking, warm off-white section header
│   ├── QuestStatusBadge.swift              // Colored diamond marker for quest state
│   ├── XPLabel.swift                       // Sparkles icon + XP amount in gold
│   ├── ProgressRing.swift                  // Circular progress for objectives (n of m)
│   ├── AtmosphericBackground.swift         // ZStack layer: dark fill + ultraThinMaterialDark + optional fog Canvas
│   └── DiamondMarker.swift                 // Small filled diamond (active quest indicator)
│
├── Theme/
│   ├── SkyrimTheme.swift                   // Central design token file: colors, fonts, spacings, tracking values
│   ├── SkyrimFont+Extensions.swift         // Font modifiers: .skyrimTitle, .skyrimBody, .skyrimCaption with tracking
│   └── SkyrimButtonStyle.swift             // Custom ButtonStyle with stone-tap haptic + dim animation
│
├── Audio/
│   ├── SoundManager.swift                  // Singleton: preloads .caf files, plays on request, respects silent mode
│   └── SoundEvent.swift                    // enum SoundEvent mapping logical events to .caf filenames
│
├── Haptics/
│   └── HapticManager.swift                 // Centralized haptic triggers, pairs with SoundManager calls
│
├── Utilities/
│   ├── AccessibilityHelpers.swift          // VoiceOver labels, dynamic type helpers, reduce-motion checks
│   └── DateFormatters.swift                // Shared date formatting for due dates and timestamps
│
├── Resources/
│   └── Sounds/
│       ├── menu_open.caf                   // 400ms stone scrape + wind whoosh
│       ├── menu_close.caf                  // 250ms reverse stone settle
│       ├── nav_click.caf                   // 60ms soft stone click
│       ├── select_confirm.caf              // 100ms click + metal ring
│       ├── back_cancel.caf                 // 80ms dampened thud
│       ├── quest_start.caf                 // 2.5s rising strings + horn swell
│       ├── quest_complete.caf              // 3s brass fanfare + choir chord
│       ├── objective_new.caf              // 500ms ascending bell chime
│       ├── objective_done.caf             // 300ms positive sparkle chime
│       ├── quest_failed.caf               // 1.5s descending minor strings
│       └── ambient_loop.caf              // 10s quiet wind + stone room (loopable)
│
└── Assets.xcassets/
    ├── AppIcon.appiconset/                 // App icon (dark, minimal, diamond motif)
    ├── AccentColor.colorset/               // #C8A84E (gold) -- light & dark variants
    ├── Colors/
    │   ├── SkyrimBackground.colorset/      // #111111
    │   ├── SkyrimSurface.colorset/         // #1A1A1A @ 85% opacity
    │   ├── SkyrimPrimary.colorset/         // #E8E8E0
    │   ├── SkyrimSecondary.colorset/       // #8B8B83
    │   ├── SkyrimDimmed.colorset/          // #666660
    │   ├── SkyrimAccentGold.colorset/      // #C8A84E
    │   ├── SkyrimMapGold.colorset/         // #D4A831
    │   ├── SkyrimDivider.colorset/         // #333330
    │   ├── SkyrimSectionHeader.colorset/   // #D4D4CC
    │   └── SkyrimHighlight.colorset/       // #FFFFFF @ 15% opacity
    └── Images/
        └── (reserved for any decorative assets)
```

**Total files**: ~30 Swift source files + 11 audio assets + 11 color sets.

---

## 2. SwiftUI View Hierarchy

The hierarchy follows Apple HIG strictly: TabView at root, NavigationStack inside each tab, List as the primary collection, and detail views via navigationDestination.

### Hierarchy Tree

```
DDxPsychiatryApp (@main)
└── WindowGroup
    └── ContentView
        └── TabView (3 tabs, iOS 18 Tab API)
            │
            ├── Tab("Quests", systemImage: "list.bullet.clipboard")
            │   └── NavigationStack(path: $questPath)
            │       └── QuestListView
            │           ├── .navigationTitle("JOURNAL")  [.large, custom tracking]
            │           ├── .searchable(text:, prompt: "Search quests")
            │           ├── .searchScopes (All / Active / Completed)
            │           ├── .toolbar
            │           │   ├── ToolbarItem(.topBarTrailing) -> "+" button -> .sheet { QuestFormView }
            │           │   └── ToolbarItem(.topBarTrailing) -> Menu (Sort / Filter)
            │           ├── List(.insetGrouped)
            │           │   ├── Section("MAIN QUESTS")   [SkyrimSectionHeader style]
            │           │   │   └── ForEach -> QuestRow
            │           │   ├── Section("SIDE QUESTS")
            │           │   │   └── ForEach -> QuestRow
            │           │   ├── Section("DAILY TASKS")
            │           │   │   └── ForEach -> QuestRow
            │           │   └── Section("MISCELLANEOUS")
            │           │       └── ForEach -> QuestRow
            │           └── .navigationDestination(for: Quest.self)
            │               └── QuestDetailView(quest:)
            │                   ├── ScrollView
            │                   │   ├── Quest title    [.title, ALL CAPS, wide tracking]
            │                   │   ├── Divider         [SkyrimDivider color]
            │                   │   ├── Description     [.body, SkyrimSecondary]
            │                   │   ├── Section "OBJECTIVES"
            │                   │   │   └── ForEach -> ObjectiveRow
            │                   │   │       ├── Status icon (circle / checkmark.circle.fill)
            │                   │   │       └── Objective text
            │                   │   └── XPLabel (sparkles + reward)
            │                   ├── .toolbar
            │                   │   ├── "Set Active" button
            │                   │   └── Edit (pencil) -> .sheet { QuestFormView(editing:) }
            │                   └── .sensoryFeedback triggers
            │
            ├── Tab("Archive", systemImage: "archivebox")
            │   └── NavigationStack(path: $archivePath)
            │       └── ArchiveView
            │           ├── .navigationTitle("COMPLETED")
            │           ├── List(.insetGrouped)
            │           │   └── Sections by category -> QuestRow (dimmed style)
            │           └── .navigationDestination(for: Quest.self)
            │               └── QuestDetailView(quest:)  [read-only mode]
            │
            └── Tab("Profile", systemImage: "person.crop.circle")
                └── NavigationStack
                    └── ProfileView
                        ├── .navigationTitle("CHARACTER")
                        ├── Stats section (total quests, completion rate, XP)
                        ├── ProgressRing (overall progress)
                        └── Settings section
                            ├── Toggle: Sound effects
                            ├── Toggle: Haptic feedback
                            └── Toggle: Ambient background sound
```

### iPad Adaptation

On iPad (regular horizontal size class), `ContentView` switches from `TabView` to `NavigationSplitView`:

```
NavigationSplitView
├── Sidebar: Category list (Main Quests, Side Quests, Daily, Misc, Archive, Profile)
├── Content: QuestListView (filtered by selected category)
└── Detail: QuestDetailView (selected quest)
```

This collapse is handled automatically by checking `@Environment(\.horizontalSizeClass)` in `ContentView`.

### Sheet Presentations

| Trigger | Presentation | Content |
|---------|-------------|---------|
| "+" toolbar button on QuestListView | `.sheet(isPresented:)` | `NavigationStack { QuestFormView }` with Cancel + Save toolbar buttons |
| "Edit" toolbar button on QuestDetailView | `.sheet(item:)` | `NavigationStack { QuestFormView(editing: quest) }` with Cancel + Save |
| Long-press "Delete" on QuestRow | `.alert(isPresented:)` | Destructive confirmation dialog |
| Long-press context menu on QuestRow | `.contextMenu` | Edit, Set Active, Archive, Delete |
| "Complete Quest" confirmation | `.confirmationDialog` | Confirm completion with XP reward preview |

---

## 3. Data Models (SwiftData)

### QuestCategory Enum

```
enum QuestCategory: String, Codable, CaseIterable, Identifiable
    cases:
        - mainQuest        (display: "MAIN QUESTS",    icon: "shield.lefthalf.filled")
        - sideQuest        (display: "SIDE QUESTS",    icon: "signpost.right")
        - dailyTask        (display: "DAILY TASKS",    icon: "sun.max")
        - miscellaneous    (display: "MISCELLANEOUS",  icon: "scroll")

    properties:
        - id: String  (rawValue)
        - displayName: String
        - icon: String (SF Symbol name)
        - sortOrder: Int (for deterministic section ordering)
```

### Quest Model (@Model)

```
@Model
class Quest

    properties:
        - id: UUID                          (default: UUID(), unique)
        - title: String                     (quest/diagnosis display name)
        - questDescription: String          (detailed description text)
        - category: QuestCategory           (enum, determines list section)
        - isComplete: Bool                  (default: false)
        - isActive: Bool                    (default: false; only one quest active at a time)
        - isFailed: Bool                    (default: false)
        - xpReward: Int                     (default: 0)
        - dueDate: Date?                    (optional deadline)
        - createdAt: Date                   (default: .now)
        - completedAt: Date?               (set when isComplete toggled true)
        - objectives: [Objective]           (one-to-many relationship, cascade delete)

    computed properties:
        - isOverdue: Bool                   (dueDate != nil && dueDate < .now && !isComplete)
        - progress: Double                  (completed objectives / total objectives, 0.0...1.0)
        - completedObjectivesCount: Int
        - totalObjectivesCount: Int
        - statusLabel: String               ("Active" / "Completed" / "Failed" / "In Progress")

    conformances:
        - Identifiable (via id)
        - Hashable (for NavigationPath)
```

### Objective Model (@Model)

```
@Model
class Objective

    properties:
        - id: UUID                          (default: UUID(), unique)
        - text: String                      (objective description / diagnostic criterion)
        - isComplete: Bool                  (default: false)
        - isFailed: Bool                    (default: false)
        - sortOrder: Int                    (manual ordering within a quest)
        - quest: Quest?                     (inverse relationship, back-reference)

    computed properties:
        - statusIcon: String                (SF Symbol: "circle" / "checkmark.circle.fill" / "xmark.circle")
        - displayStyle: ObjectiveDisplayStyle  (enum: .active, .completed, .failed)

    conformances:
        - Identifiable (via id)
```

### ModelContainer Configuration

```
App-level setup:
    .modelContainer(for: [Quest.self, Objective.self])

    - Automatic schema migration via SwiftData
    - Stored in default app container (Documents/)
    - No CloudKit sync in v1 (future consideration)
```

### @Query Usage in Views

| View | Query | Sort | Filter |
|------|-------|------|--------|
| QuestListView | `@Query var quests: [Quest]` | `\Quest.createdAt`, descending | `isComplete == false` |
| ArchiveView | `@Query var completed: [Quest]` | `\Quest.completedAt`, descending | `isComplete == true` |
| QuestDetailView | N/A (quest passed via navigation) | N/A | N/A |
| ProfileView | `@Query var allQuests: [Quest]` | none | none (used for aggregate stats) |

---

## 4. Visual Style Mapping -- Skyrim to iOS

This section maps Skyrim's dark, atmospheric, text-driven quest journal aesthetic onto native SwiftUI components and Apple HIG patterns.

### 4.1 Background Treatment

| Skyrim Element | iOS Implementation |
|----------------|-------------------|
| Blurred, darkened game world behind menus | `ZStack` base layer: `Color("SkyrimBackground").ignoresSafeArea()` overlaid with `.ultraThinMaterial` set to dark color scheme via `.preferredColorScheme(.dark)` |
| No solid panels or cards | `List` with `.listStyle(.plain)` and `.listRowBackground(Color.clear)` -- rows float on the dark surface |
| Vignette at screen edges | `RadialGradient` overlay: center clear, edges `Color.black.opacity(0.3)` |
| Subtle fog/mist particles | `Canvas` view with animated translucent circles drifting slowly; disabled when `accessibilityReduceMotion` is true |
| No visible scrollbar | `.scrollIndicators(.hidden)` on List/ScrollView |

### 4.2 Typography Mapping

Skyrim uses Futura Condensed with wide letter-spacing. On iOS, we use SF Pro with `.tracking()` to capture the same airy, ethereal feel while remaining system-native for accessibility.

| Skyrim Usage | SwiftUI Font | Modifiers | Tracking | Transform |
|--------------|-------------|-----------|----------|-----------|
| Menu titles ("JOURNAL") | `.largeTitle` | `.fontWeight(.medium)` | `+3.0` | `.textCase(.uppercase)` |
| Section headers ("MAIN QUESTS") | `.subheadline` | `.fontWeight(.medium)`, `.foregroundStyle(Color("SkyrimSectionHeader"))` | `+2.5` | `.textCase(.uppercase)` |
| Quest name in list | `.headline` | `.foregroundStyle(Color("SkyrimPrimary"))` | `+1.5` | Title case (as-is) |
| Quest name in detail | `.title` | `.fontWeight(.medium)`, `.foregroundStyle(Color("SkyrimPrimary"))` | `+2.0` | `.textCase(.uppercase)` |
| Quest description body | `.body` | `.foregroundStyle(Color("SkyrimSecondary"))` | `+0.5` | Sentence case (as-is) |
| Objective text | `.body` | Active: `SkyrimPrimary`; Completed: `SkyrimDimmed` + `.strikethrough` | `+0.3` | Sentence case |
| Metadata (date, category) | `.caption` | `.foregroundStyle(Color("SkyrimSecondary"))` | `+1.0` | As-is |
| XP reward label | `.caption` | `.fontWeight(.bold)`, `.foregroundStyle(Color("SkyrimAccentGold"))` | `+1.0` | As-is |

Key principle: **hierarchy through opacity, not weight**. Same font family, different brightness levels (SkyrimPrimary -> SkyrimSecondary -> SkyrimDimmed) create the Skyrim-like visual hierarchy.

### 4.3 List Row Styling

| Skyrim Behavior | iOS Implementation |
|-----------------|-------------------|
| Text-only rows, no icons in list | QuestRow uses only text labels; SF Symbols used sparingly (diamond marker for active quest, not decorative) |
| Selected row has subtle white glow | `.listRowBackground()` with `Color("SkyrimHighlight")` (#FFFFFF @ 15%) on selected/highlighted state |
| Active quest marked with diamond | Leading `Image(systemName: "diamond.fill")` in `Color("SkyrimAccentGold")` only for the active quest |
| Completed quests dimmed | `.foregroundStyle(Color("SkyrimDimmed"))` + `.strikethrough` on quest title |
| Thin horizontal dividers | `Divider().overlay(Color("SkyrimDivider"))` between sections; `.listRowSeparatorTint(Color("SkyrimDivider"))` |
| Wide margins, content at 60-70% width | `.contentMargins(.horizontal, 20, for: .scrollContent)` + padding in rows |

### 4.4 Material and Surface Usage

| Surface | Material | Notes |
|---------|----------|-------|
| App background (behind all content) | `Color("SkyrimBackground")` (#111111) with `.ignoresSafeArea()` | Base layer |
| List/scroll content overlay | `.ultraThinMaterial` with `.preferredColorScheme(.dark)` | Creates the Skyrim blur-over-dark effect |
| Navigation bar | `.toolbarBackground(.ultraThinMaterial, for: .navigationBar)` | Consistent atmospheric bar |
| Tab bar | `.toolbarBackground(.ultraThinMaterial, for: .tabBar)` | Matches navigation bar |
| Sheet backgrounds | `.presentationBackground(.ultraThinMaterial)` | Forms float on dark blur |
| Context menu preview | Default system behavior | Apple handles preview styling |

### 4.5 Animation Guidelines

| Action | Animation | Duration | Reduce Motion Alternative |
|--------|-----------|----------|--------------------------|
| Menu/sheet open | `.easeOut` fade + slight scale (0.97 -> 1.0) | 300ms | Instant appear (no animation) |
| Menu/sheet close | `.easeIn` fade + slight scale (1.0 -> 0.97) | 200ms | Instant disappear |
| Quest completion | `symbolEffect(.bounce)` on checkmark icon | System default | No bounce, instant state change |
| Row selection | `.easeInOut` opacity shift on background | 150ms | Instant highlight |
| Category expand/collapse | `.spring(response: 0.3)` | 300ms | Instant |
| Fog particles (AtmosphericBackground) | Continuous `withAnimation(.linear(duration: 8).repeatForever)` | N/A | Disabled entirely |

---

## 5. Color Asset Definitions

All colors are defined in `Assets.xcassets/Colors/`. Since the app is permanently dark-themed (`.preferredColorScheme(.dark)`), both the "Any Appearance" and "Dark" variants use the same values. A "Light" variant is provided only for system contexts that may momentarily render in light mode (e.g., share sheets).

### Primary Palette

| Asset Name | Hex (Dark/Primary) | Hex (Light Fallback) | RGB | Opacity | Usage |
|------------|--------------------|-----------------------|-----|---------|-------|
| `SkyrimBackground` | `#111111` | `#111111` | 17, 17, 17 | 100% | App-wide base background |
| `SkyrimSurface` | `#1A1A1A` | `#1A1A1A` | 26, 26, 26 | 85% | Card/surface overlay, blurred backdrop tint |
| `SkyrimPrimary` | `#E8E8E0` | `#1A1A1A` | 232, 232, 224 | 100% | Primary text, selected items, active quest names |
| `SkyrimSecondary` | `#8B8B83` | `#6B6B63` | 139, 139, 131 | 100% | Secondary text, unselected items, descriptions |
| `SkyrimDimmed` | `#666660` | `#999990` | 102, 102, 96 | 100% | Completed/inactive text, disabled states |
| `SkyrimSectionHeader` | `#D4D4CC` | `#333330` | 212, 212, 204 | 100% | Section header text (brighter than body) |
| `SkyrimDivider` | `#333330` | `#CCCCCC` | 51, 51, 48 | 100% | Thin separator lines, dividers |
| `SkyrimHighlight` | `#FFFFFF` | `#000000` | 255, 255, 255 | 15% | Row selection glow, hover state |

### Accent and Status Colors

| Asset Name | Hex | RGB | Usage |
|------------|-----|-----|-------|
| `AccentColor` (global) | `#C8A84E` | 200, 168, 78 | App-wide accent: buttons, links, toggles, interactive tint |
| `SkyrimAccentGold` | `#C8A84E` | 200, 168, 78 | Active quest diamond, XP labels, reward highlights |
| `SkyrimMapGold` | `#D4A831` | 212, 168, 49 | Map/location markers, premium indicators |
| `QuestStatusActive` | `#C8A84E` | 200, 168, 78 | Active quest badge |
| `QuestStatusComplete` | `#4CAF50` | 76, 175, 80 | Completed quest checkmark (system green analog) |
| `QuestStatusFailed` | `#CF6679` | 207, 102, 121 | Failed quest indicator (muted red, not harsh) |
| `QuestStatusOverdue` | `#E8943A` | 232, 148, 58 | Overdue warning (warm orange) |

### Color Contrast Notes

- `SkyrimPrimary` (#E8E8E0) on `SkyrimBackground` (#111111) = contrast ratio ~14.5:1 (exceeds WCAG AAA)
- `SkyrimSecondary` (#8B8B83) on `SkyrimBackground` (#111111) = contrast ratio ~5.2:1 (exceeds WCAG AA)
- `SkyrimDimmed` (#666660) on `SkyrimBackground` (#111111) = contrast ratio ~3.3:1 (meets WCAG AA for large text only; acceptable because dimmed text is always supplementary, never the sole information carrier)
- `SkyrimAccentGold` (#C8A84E) on `SkyrimBackground` (#111111) = contrast ratio ~6.8:1 (exceeds WCAG AA)
- Provide High Contrast alternates in Asset Catalog for users with "Increase Contrast" enabled (bump SkyrimSecondary to #A0A098, SkyrimDimmed to #808078)

---

## 6. Sound Integration Points

Every view and interaction that triggers a sound, mapped to the specific `.caf` file from the sound set.

### 6.1 Sound-to-View Mapping

| View / Component | User Action | Sound File | Duration | Notes |
|-----------------|-------------|------------|----------|-------|
| **ContentView** | App launches (first appearance) | `menu_open.caf` | 400ms | Play once on initial load; not on subsequent tab switches |
| **ContentView** | App goes to background | `menu_close.caf` | 250ms | Play via `scenePhase` observer |
| **QuestListView** | Tap a quest row (push detail) | `select_confirm.caf` | 100ms | Click + metal ring on navigation push |
| **QuestListView** | Scroll through quest rows | *no sound* | -- | Scrolling is silent to avoid fatigue (differs from Skyrim's per-item click) |
| **QuestListView** | Switch section/category scope | `nav_click.caf` | 60ms | Soft stone click when changing search scope |
| **QuestListView** | Pull-to-refresh (if implemented) | `nav_click.caf` | 60ms | Subtle stone click on pull threshold |
| **QuestDetailView** | Appears (navigation push) | *no sound* | -- | select_confirm already played on row tap |
| **QuestDetailView** | Tap "Set Active" button | `select_confirm.caf` | 100ms | Confirming action |
| **QuestDetailView** | Toggle objective complete | `objective_done.caf` | 300ms | Positive sparkle chime per objective |
| **QuestDetailView** | All objectives completed (auto-complete quest) | `quest_complete.caf` | 3s | Triumphant fanfare, delayed 200ms after last objective |
| **QuestFormView** | Sheet appears (create new) | `menu_open.caf` | 400ms | Stone scrape on sheet presentation |
| **QuestFormView** | Tap "Save" (new quest created) | `quest_start.caf` | 2.5s | Rising orchestral swell for new quest |
| **QuestFormView** | Tap "Cancel" (dismiss sheet) | `back_cancel.caf` | 80ms | Dampened thud |
| **QuestRow** | Swipe-to-complete (leading swipe) | `quest_complete.caf` | 3s | Full fanfare on quest completion |
| **QuestRow** | Swipe-to-delete (trailing swipe, confirmed) | `quest_failed.caf` | 1.5s | Somber descending minor strings |
| **ArchiveView** | Tap archived quest row | `select_confirm.caf` | 100ms | Same as active list |
| **ProfileView** | No specific sounds | -- | -- | Profile is a quiet settings screen |
| **AtmosphericBackground** | Always (while app is foregrounded) | `ambient_loop.caf` | 10s loop | Very quiet (10-15% volume), looped; togglable in Profile settings |

### 6.2 Sound Playback Rules

1. **Silent mode**: All sounds respect the hardware silent switch via `.ambient` audio session category.
2. **Mix with others**: Sounds never interrupt the user's music (`.mixWithOthers` option).
3. **Preloading**: All 11 sound files are preloaded into `AVAudioPlayer` instances at app launch via `SoundManager.preload()`.
4. **User preference**: A "Sound Effects" toggle in ProfileView enables/disables all non-ambient sounds. An "Ambient Sound" toggle controls the background loop independently.
5. **Reduce Motion**: When `accessibilityReduceMotion` is true, quest fanfares (`quest_start`, `quest_complete`) are shortened or replaced with a simple chime (`objective_done`).
6. **No overlapping fanfares**: If a fanfare is playing and a new one is triggered, the previous one fades out over 200ms before the new one starts.

---

## 7. Haptic Feedback Mapping

Every haptic trigger, paired with its corresponding sound (when applicable) and SwiftUI API.

### 7.1 Haptic-to-Interaction Mapping

| Interaction | Haptic Type | SwiftUI API | Paired Sound | Intensity |
|-------------|-------------|-------------|--------------|-----------|
| **Quest completed** (swipe or auto-complete) | Notification: Success | `.sensoryFeedback(.success, trigger: quest.isComplete)` | `quest_complete.caf` | Strong -- this is the primary reward moment |
| **Objective toggled complete** | Impact: Light | `.sensoryFeedback(.impact(weight: .light), trigger: objective.isComplete)` | `objective_done.caf` | Light -- satisfying but not heavy for repeated use |
| **New quest saved** | Notification: Success | `.sensoryFeedback(.success, trigger: questCreatedTrigger)` | `quest_start.caf` | Medium -- positive confirmation |
| **Quest deleted (confirmed)** | Notification: Warning | `.sensoryFeedback(.warning, trigger: questDeletedTrigger)` | `quest_failed.caf` | Medium -- cautionary |
| **Quest failed** | Notification: Error | `.sensoryFeedback(.error, trigger: quest.isFailed)` | `quest_failed.caf` | Medium-strong -- negative outcome |
| **Toggle quest active status** | Selection | `.sensoryFeedback(.selection, trigger: quest.isActive)` | `select_confirm.caf` | Light -- selection change |
| **Search scope change** | Selection | `.sensoryFeedback(.selection, trigger: searchScope)` | `nav_click.caf` | Light -- picker-like |
| **Swipe action threshold reached** | Impact: Medium | `.sensoryFeedback(.impact(weight: .medium), trigger: swipeTrigger)` | none | Medium -- physical snap |
| **Drag-to-reorder pickup** | Impact: Light | Via UIKit impact generator in drag delegate | none | Light -- object lift |
| **Drag-to-reorder drop** | Impact: Medium | Via UIKit impact generator in drag delegate | `nav_click.caf` | Medium -- object placement |
| **Error (failed save, network)** | Notification: Error | `.sensoryFeedback(.error, trigger: errorTrigger)` | none | Strong -- attention required |
| **Tab bar tap** | Selection | `.sensoryFeedback(.selection, trigger: selectedTab)` | none | Light -- standard iOS tab behavior |

### 7.2 Haptic Design Principles

1. **Sound + haptic pairing**: Major events (quest complete, quest start, quest fail) always combine sound + haptic for multi-sensory feedback. The haptic fires at the exact moment of state change; the sound plays its full duration.
2. **Graduated intensity**: Objective complete (light) < New quest (medium) < Quest complete (strong). Intensity escalates with significance.
3. **No haptic fatigue**: Scrolling, passive viewing, and background updates produce no haptics. Only user-initiated actions trigger feedback.
4. **User preference**: A "Haptic Feedback" toggle in ProfileView enables/disables all haptics. When disabled, `.sensoryFeedback` calls are gated by a boolean check.
5. **Reduce Motion respect**: Haptics still fire even when Reduce Motion is on (haptics are not motion), but they are never the sole feedback mechanism -- always paired with visual state change.

---

## 8. Navigation Flow Diagram

Text-based diagram showing every screen transition, the trigger, and the transition type.

```
                                ┌──────────────────────────────────┐
                                │         DDxPsychiatryApp         │
                                │  (@main, ModelContainer setup)   │
                                └──────────────┬───────────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────────┐
                                │          ContentView             │
                                │     TabView (3 tabs below)       │
                                └──┬───────────┬───────────────┬───┘
                                   │           │               │
                    ┌──────────────┘           │               └──────────────┐
                    ▼                          ▼                              ▼
        ┌───────────────────┐    ┌──────────────────────┐      ┌──────────────────────┐
        │   Tab 1: QUESTS   │    │   Tab 2: ARCHIVE     │      │   Tab 3: PROFILE     │
        │  NavigationStack  │    │   NavigationStack     │      │   NavigationStack     │
        └────────┬──────────┘    └──────────┬───────────┘      └──────────┬───────────┘
                 │                          │                              │
                 ▼                          ▼                              ▼
        ┌───────────────────┐    ┌──────────────────────┐      ┌──────────────────────┐
        │  QuestListView    │    │    ArchiveView        │      │    ProfileView        │
        │  (sectioned List) │    │  (completed quests)   │      │  (stats + settings)   │
        │  + .searchable    │    │                        │      │                        │
        │  + toolbar        │    │                        │      │                        │
        └──┬────┬───────────┘    └──────────┬───────────┘      └────────────────────────┘
           │    │                            │
           │    │  ┌─── "+" button ──────────┼──────────────┐
           │    │  │    (toolbar)            │              │
           │    │  ▼                         │              │
           │    │ ┌──────────────────┐       │              │
           │    │ │  .sheet MODAL    │       │              │
           │    │ │  QuestFormView   │       │              │
           │    │ │  (Create New)    │       │              │
           │    │ │                  │       │              │
           │    │ │  [Cancel] [Save] │       │              │
           │    │ └──────────────────┘       │              │
           │    │                            │              │
           │    │  ┌── "Edit" (context) ─┐   │              │
           │    │  ▼                     │   │              │
           │    │ ┌──────────────────┐   │   │              │
           │    │ │  .sheet MODAL    │   │   │              │
           │    │ │  QuestFormView   │   │   │              │
           │    │ │  (Edit Existing) │   │   │              │
           │    │ │                  │   │   │              │
           │    │ │  [Cancel] [Save] │   │   │              │
           │    │ └──────────────────┘   │   │              │
           │    │                        │   │              │
           │    │                        │   │              │
    ┌──────┘    └────────────────────────┘   │              │
    │ tap row                                │ tap row      │
    ▼                                        ▼              │
┌──────────────────────────┐    ┌──────────────────────────┐│
│    QuestDetailView       │    │    QuestDetailView        ││
│    (PUSH transition)     │    │    (PUSH, read-only)      ││
│                          │    │                            ││
│  ┌────────────────────┐  │    └──────────────────────────┘│
│  │ QUEST TITLE        │  │                                │
│  │ ──────────────     │  │                                │
│  │ Description...     │  │                                │
│  │                    │  │                                │
│  │ OBJECTIVES:        │  │                                │
│  │  ✓ Objective 1     │  │                                │
│  │  ● Objective 2     │  │                                │
│  │  ○ Objective 3     │  │                                │
│  │                    │  │                                │
│  │ [SET ACTIVE] [EDIT]│  │                                │
│  └────────────────────┘  │                                │
│                          │                                │
│  "Edit" toolbar ─────────┼── .sheet { QuestFormView }     │
│                          │                                │
│  "Delete" (context) ─────┼── .alert { confirm delete }    │
│                          │                                │
│  "Complete" (action) ────┼── .confirmationDialog          │
│                          │    { confirm + XP preview }    │
│                          │                                │
│  Back (auto swipe-back)──┼── POP to QuestListView         │
└──────────────────────────┘                                │
                                                            │
```

### Transition Types Summary

| From | To | Trigger | Transition | Sound | Haptic |
|------|----|---------|------------|-------|--------|
| ContentView | QuestListView | Tab tap | Tab switch (instant) | -- | `.selection` |
| ContentView | ArchiveView | Tab tap | Tab switch (instant) | -- | `.selection` |
| ContentView | ProfileView | Tab tap | Tab switch (instant) | -- | `.selection` |
| QuestListView | QuestDetailView | Tap quest row | Push (slide from right) | `select_confirm.caf` | -- |
| QuestDetailView | QuestListView | Back button / swipe-back | Pop (slide from left) | -- | -- |
| QuestListView | QuestFormView | "+" button | Sheet (slide up) | `menu_open.caf` | -- |
| QuestFormView | QuestListView | "Cancel" | Sheet dismiss (slide down) | `back_cancel.caf` | -- |
| QuestFormView | QuestListView | "Save" | Sheet dismiss (slide down) | `quest_start.caf` | `.success` |
| QuestDetailView | QuestFormView | "Edit" button | Sheet (slide up) | `menu_open.caf` | -- |
| QuestDetailView | (self) | Toggle objective | In-place update | `objective_done.caf` | `.impact(.light)` |
| QuestDetailView | (self) | All objectives done | In-place update + celebration | `quest_complete.caf` | `.success` |
| QuestRow | (self) | Leading swipe complete | In-place update | `quest_complete.caf` | `.success` |
| QuestRow | .alert | Trailing swipe delete | Alert overlay | -- | `.impact(.medium)` |
| .alert | QuestListView | Confirm delete | Row removal animation | `quest_failed.caf` | `.warning` |
| ArchiveView | QuestDetailView | Tap archived quest | Push (slide from right) | `select_confirm.caf` | -- |

---

## Appendix A: Design Tokens Quick Reference

For use in `SkyrimTheme.swift` -- a central reference for all design values.

```
COLORS (Asset Catalog names):
    SkyrimBackground        #111111     100%
    SkyrimSurface           #1A1A1A      85%
    SkyrimPrimary           #E8E8E0     100%
    SkyrimSecondary         #8B8B83     100%
    SkyrimDimmed            #666660     100%
    SkyrimSectionHeader     #D4D4CC     100%
    SkyrimDivider           #333330     100%
    SkyrimHighlight         #FFFFFF      15%
    SkyrimAccentGold        #C8A84E     100%
    SkyrimMapGold           #D4A831     100%
    AccentColor             #C8A84E     100%

TYPOGRAPHY TRACKING:
    largeTitle              +3.0
    sectionHeader           +2.5
    title (detail view)     +2.0
    headline (list row)     +1.5
    caption (metadata)      +1.0
    body (description)      +0.5
    objective text          +0.3

SPACING:
    compact                 4pt
    default                 8pt
    standard (padding)      16pt
    large                   20pt
    extraLarge              32pt
    listRowVerticalPadding  4pt
    sectionSpacing          24pt

MATERIAL:
    primary surface         .ultraThinMaterial (dark scheme)
    navigation bar          .ultraThinMaterial (dark scheme)
    tab bar                 .ultraThinMaterial (dark scheme)
    sheet background        .ultraThinMaterial (dark scheme)

ANIMATION DURATIONS:
    menuOpen                300ms   .easeOut
    menuClose               200ms   .easeIn
    rowHighlight            150ms   .easeInOut
    categoryExpand          300ms   .spring(response: 0.3)
    fogParticles            8000ms  .linear.repeatForever

MIN TAP TARGET:             44 x 44 pt
```

## Appendix B: Accessibility Checklist

- [ ] All text uses semantic font styles (`.headline`, `.body`, etc.) -- never fixed sizes
- [ ] `@ScaledMetric` used for icon sizes and custom spacing
- [ ] Every QuestRow has `.accessibilityElement(children: .combine)` with descriptive label
- [ ] VoiceOver custom actions provided for swipe-to-complete and swipe-to-delete
- [ ] `.accessibilityValue` on quest rows reports "N of M objectives complete"
- [ ] Fog particle animation disabled when `accessibilityReduceMotion` is true
- [ ] Quest fanfares shortened/silenced when Reduce Motion is on
- [ ] All status colors (gold, green, red) paired with icons and text labels
- [ ] High Contrast color variants provided in Asset Catalog
- [ ] Minimum 44x44pt tap targets on all interactive elements
- [ ] Tested at Dynamic Type sizes xSmall through accessibility5
- [ ] Tested in both VoiceOver and Switch Control

---

*Architecture document prepared for DDx Psychiatry iOS application. All design decisions reference Apple Human Interface Guidelines (iOS 18), Skyrim visual research, and Skyrim sound design research. This document specifies architecture only -- no Swift implementation files are included.*
