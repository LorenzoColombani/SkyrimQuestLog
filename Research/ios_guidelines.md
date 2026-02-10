# Apple Human Interface Guidelines -- Quest Log / Task Tracker iOS App

> Compiled reference based on Apple's Human Interface Guidelines (HIG) through iOS 18 / 2025,
> tailored for building a quest-log / task-tracker application in SwiftUI.

---

## Table of Contents

1. [Navigation Patterns](#1-navigation-patterns)
2. [Lists & Collections](#2-lists--collections)
3. [Typography](#3-typography)
4. [Color System](#4-color-system)
5. [Layout](#5-layout)
6. [Components](#6-components)
7. [Accessibility](#7-accessibility)
8. [Haptics](#8-haptics)
9. [App Architecture](#9-app-architecture)
10. [SF Symbols](#10-sf-symbols)

---

## 1. Navigation Patterns

### Apple-Recommended Approach

Apple provides three primary navigation models for iOS apps:

| Pattern | SwiftUI API | Best For |
|---------|-------------|----------|
| **Hierarchical (push/pop)** | `NavigationStack` / `NavigationSplitView` | Drilling into content (quest list -> quest detail) |
| **Tab-based** | `TabView` | Top-level app sections (Quests, Journal, Profile) |
| **Modal (sheets)** | `.sheet()` / `.fullScreenCover()` | Self-contained tasks (create new quest, edit) |

#### NavigationStack (iOS 16+)

```swift
NavigationStack(path: $path) {
    QuestListView()
        .navigationDestination(for: Quest.self) { quest in
            QuestDetailView(quest: quest)
        }
}
```

- Use `NavigationStack` (not the deprecated `NavigationView`) for all hierarchical navigation.
- Bind to a `NavigationPath` or typed `[Quest]` path for programmatic navigation.
- Keep the navigation title visible; use `.navigationTitle()` with `.large` (default) for root views and `.inline` for child views.

#### NavigationSplitView (iPad / large screens)

```swift
NavigationSplitView {
    SidebarView()        // Quest categories
} content: {
    QuestListView()      // Quests in category
} detail: {
    QuestDetailView()    // Selected quest
}
```

- Automatically collapses to a single `NavigationStack` on iPhone.
- On iPad, shows sidebar + detail or three-column layout.
- Provides the list-detail pattern Apple recommends for content-browsing apps.

#### TabView (iOS 18+ floating tab bar)

```swift
TabView {
    Tab("Quests", systemImage: "list.bullet.clipboard") {
        QuestListView()
    }
    Tab("Archive", systemImage: "archivebox") {
        ArchiveView()
    }
    Tab("Profile", systemImage: "person.crop.circle") {
        ProfileView()
    }
}
```

- iOS 18 introduced a new floating tab bar style and `Tab` API. On iPad, the tab bar can transform into a sidebar.
- Limit to 5 or fewer top-level tabs.
- Each tab should represent a distinct, equally important section.
- Each tab maintains its own navigation state.
- The tab bar should always remain visible (except during full-screen experiences).

### Key Do's and Don'ts

**Do:**
- Use `NavigationStack` for all drill-down flows.
- Give every view a `.navigationTitle`.
- Use `.sheet()` for create/edit flows so the user can cancel easily.
- Support swipe-back gesture (it works automatically with NavigationStack).
- On iPad, use `NavigationSplitView` for a sidebar/detail experience.

**Don't:**
- Don't use `NavigationView` -- it is deprecated as of iOS 16.
- Don't nest `NavigationStack` inside `NavigationStack`. One stack per hierarchy.
- Don't hide the back button without providing an alternative.
- Don't put a TabView inside a NavigationStack (reverse the nesting: NavigationStack inside each Tab).

### Quest Log Application

- **Root**: `TabView` with tabs for Active Quests, Completed/Archive, and Settings/Profile.
- **Each tab wraps its own `NavigationStack`**.
- Tapping a quest pushes `QuestDetailView` onto the stack.
- "New Quest" presented as `.sheet(isPresented:)` with a form.
- On iPad: `NavigationSplitView` with quest categories in sidebar, quest list in content column, quest detail in detail column.

---

## 2. Lists & Collections

### Apple-Recommended Approach

SwiftUI `List` is the primary component for scrollable collections. Apple also offers `LazyVStack` inside `ScrollView` for custom layouts.

#### List Styles

| Style | Modifier | Use Case |
|-------|----------|----------|
| **Inset Grouped** | `.listStyle(.insetGrouped)` | Default iOS style. Grouped sections with rounded corners. Best for settings-like or categorized content. |
| **Plain** | `.listStyle(.plain)` | Edge-to-edge rows. Best for long homogeneous lists. |
| **Sidebar** | `.listStyle(.sidebar)` | Sidebar navigation on iPad. |
| **Grouped** | `.listStyle(.grouped)` | Legacy grouped style. |

#### Sections

```swift
List {
    Section("Main Quests") {
        ForEach(mainQuests) { quest in
            QuestRow(quest: quest)
        }
    }
    Section("Side Quests") {
        ForEach(sideQuests) { quest in
            QuestRow(quest: quest)
        }
    }
}
```

- Use `Section` with headers (and optional footers) to group related items.
- Section headers should be concise -- one or two words.

#### Swipe Actions

```swift
QuestRow(quest: quest)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
        Button(role: .destructive) {
            deleteQuest(quest)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    .swipeActions(edge: .leading, allowsFullSwipe: true) {
        Button {
            completeQuest(quest)
        } label: {
            Label("Complete", systemImage: "checkmark")
        }
        .tint(.green)
    }
```

- Trailing swipe (right-to-left) for destructive or secondary actions.
- Leading swipe (left-to-right) for positive/primary actions (e.g., complete a quest).
- `allowsFullSwipe: true` enables the quick full-swipe gesture for the primary action.
- Use `.tint()` to color swipe action buttons (red for delete, green for complete).

#### Search & Filtering

```swift
List { ... }
    .searchable(text: $searchText, prompt: "Search quests")
    .searchScopes($scope) {
        Text("All").tag(SearchScope.all)
        Text("Active").tag(SearchScope.active)
        Text("Completed").tag(SearchScope.completed)
    }
```

- Use `.searchable()` for the standard iOS search bar behavior.
- Search scopes (`.searchScopes`) provide segmented filter options beneath the search bar.
- For simple filtering without search, use a `Picker` in the toolbar or a segmented control.

### Key Do's and Don'ts

**Do:**
- Use `.insetGrouped` as your default list style on iPhone.
- Provide swipe actions for common operations (complete, delete, archive).
- Use `.searchable()` if the list can grow beyond ~20 items.
- Support multi-select with `List(selection:)` for batch operations.
- Use `@FetchRequest` or `.searchable` token-based filtering for large datasets.

**Don't:**
- Don't put heavy views in list rows (keep rows lightweight).
- Don't use custom scroll views when `List` provides the functionality you need.
- Don't make swipe actions the only way to access a feature -- provide alternatives in the detail view or context menu.
- Don't use more than 3 swipe action buttons per side.

### Quest Log Application

- **Inset grouped list** with sections: "Main Quests", "Side Quests", "Daily Quests".
- **Leading swipe**: Mark quest complete (green checkmark).
- **Trailing swipe**: Delete or archive quest.
- **Search bar** at top for filtering quests by name.
- **Search scopes or toolbar Picker**: Filter by status (All / Active / Completed) or category.

---

## 3. Typography

### Apple-Recommended Approach

Apple uses the **SF Pro** font family as the system font on iOS. All SwiftUI text styles map to SF Pro automatically and support Dynamic Type.

#### Recommended Text Styles

| Style | SwiftUI | Default Size | Use In Quest App |
|-------|---------|-------------|------------------|
| **Large Title** | `.largeTitle` | 34pt | Main screen headers (via `.navigationTitle`) |
| **Title** | `.title` | 28pt | Section headers, quest name in detail view |
| **Title 2** | `.title2` | 22pt | Sub-section headers |
| **Title 3** | `.title3` | 20pt | Card titles |
| **Headline** | `.headline` | 17pt semibold | Quest name in list row |
| **Body** | `.body` | 17pt | Quest description, main content |
| **Callout** | `.callout` | 16pt | Secondary descriptions |
| **Subheadline** | `.subheadline` | 15pt | Metadata (due date, category label) |
| **Footnote** | `.footnote` | 13pt | Timestamps, tertiary info |
| **Caption** | `.caption` | 12pt | Badges, tags, XP amounts |
| **Caption 2** | `.caption2` | 11pt | Fine print |

#### Dynamic Type

```swift
Text(quest.title)
    .font(.headline)  // Automatically scales with Dynamic Type
```

- **Always use semantic text styles** (`.headline`, `.body`, etc.) rather than fixed point sizes.
- If you must use a custom size, apply `.dynamicTypeSize()` or use `@ScaledMetric` to scale custom values.
- Test at the largest accessibility text sizes (AX1 through AX5).
- Use `Text.lineLimit(nil)` or appropriate line limits to handle varying text lengths at large sizes.

#### Font Weight & Emphasis

```swift
Text(quest.title)
    .font(.headline)           // Already semibold
Text(quest.xpReward)
    .font(.caption)
    .fontWeight(.bold)         // Extra emphasis
Text(quest.description)
    .font(.body)
    .foregroundStyle(.secondary)  // Reduced emphasis
```

- Use font weight to create visual hierarchy: bold/semibold for primary, regular for secondary, with color opacity for tertiary.
- Apple recommends no more than 2-3 distinct levels of typographic hierarchy per screen.

### Key Do's and Don'ts

**Do:**
- Use built-in text styles exclusively for all text.
- Support Dynamic Type at all sizes, including accessibility sizes.
- Use `@ScaledMetric` for any custom spacing or icon sizes tied to text.
- Test your layout at the smallest and largest Dynamic Type settings.

**Don't:**
- Don't use fixed font sizes (e.g., `.system(size: 14)`).
- Don't truncate critical information -- let text wrap or adapt layout.
- Don't mix too many font weights on a single screen.
- Don't use fonts smaller than Caption 2 (11pt at default size).

### Quest Log Application

- **Quest row**: `.headline` for title, `.subheadline` + `.secondary` for category/due date, `.caption` for XP reward badge.
- **Quest detail**: `.title` for quest name, `.body` for description, `.footnote` for timestamps.
- **Section headers**: Use the default `Section("Header")` styling (system-managed).

---

## 4. Color System

### Apple-Recommended Approach

iOS provides a comprehensive **semantic color system** that automatically adapts to Light Mode, Dark Mode, and accessibility settings.

#### System Colors

| Color | SwiftUI | Use |
|-------|---------|-----|
| **Label** | `.primary` | Primary text |
| **Secondary Label** | `.secondary` | Secondary text, subtitles |
| **Tertiary Label** | Color(.tertiaryLabel) | Disabled or hint text |
| **System Background** | Color(.systemBackground) | Primary background |
| **Secondary System Background** | Color(.secondarySystemBackground) | Cards, grouped list background |
| **Tertiary System Background** | Color(.tertiarySystemBackground) | Nested elements |
| **Separator** | Color(.separator) | Divider lines |
| **System Fill** | Color(.systemFill) | Filled controls |

#### Accent / Tint Colors

```swift
// Set app-wide accent color in Asset Catalog -> AccentColor
// Or per-view:
Button("Complete Quest") { ... }
    .tint(.green)
```

- Define your app's **accent color** in the Asset Catalog. This is used for buttons, links, toggles, and interactive elements throughout the app.
- The accent color should work well in both light and dark mode -- provide separate color values for each appearance.
- For a quest-tracker: consider a vibrant color (gold, teal, purple) that evokes achievement.

#### System Semantic Colors for Status

| Color | SwiftUI | Quest App Use |
|-------|---------|---------------|
| `.red` | `.red` | Failed/overdue quests, destructive actions |
| `.orange` | `.orange` | Warnings, quests due soon |
| `.yellow` | `.yellow` | XP/gold rewards, star ratings |
| `.green` | `.green` | Completed quests, success states |
| `.blue` | `.blue` | Default interactive elements, info |
| `.purple` | `.purple` | Rare/epic quest tier |
| `.pink` | `.pink` | Special events |

#### Dark Mode

```swift
// Automatic when using semantic colors:
Text(quest.title)
    .foregroundStyle(.primary)  // White in dark mode, black in light mode

// Custom colors -- always provide both variants:
// In Asset Catalog: set "Any Appearance" and "Dark" variants
```

- **Always use semantic/system colors** -- they adapt automatically.
- If defining custom colors, always provide Light and Dark variants in the Asset Catalog.
- Never use hardcoded `Color.black` or `Color.white` for text or backgrounds.
- Test all screens in both Light and Dark mode.

### Key Do's and Don'ts

**Do:**
- Use `.primary`, `.secondary`, `.tertiary` for text hierarchy.
- Use system background colors for all surfaces.
- Define custom colors in Asset Catalog with both appearance variants.
- Use semantic status colors (red = danger, green = success).
- Ensure 4.5:1 contrast ratio for normal text, 3:1 for large text.
- Support Increase Contrast accessibility setting.

**Don't:**
- Don't hardcode color literals (`Color(red:green:blue:)`) for UI elements.
- Don't use color as the only indicator of status (pair with icons/text for accessibility).
- Don't use saturated colors for large background areas -- use pastels or system fills.
- Don't assume white backgrounds or black text.

### Quest Log Application

- **Accent color**: A signature color (e.g., gold/amber or teal) set in Asset Catalog for interactive elements.
- **Quest priority/rarity**: System colors as badges -- green (common), blue (uncommon), purple (rare/epic), orange (legendary).
- **Status indicators**: Green checkmark for complete, red for overdue, orange for due soon.
- **All surfaces**: Use system background colors so Dark Mode works automatically.
- **XP and rewards**: Gold/yellow tint for reward-related UI.

---

## 5. Layout

### Apple-Recommended Approach

#### Safe Areas

```swift
// Content automatically respects safe areas in SwiftUI.
// To extend into safe areas (e.g., for a background):
Color.blue
    .ignoresSafeArea()
```

- SwiftUI views respect safe areas by default -- interactive content stays within safe areas.
- Only decorative elements (backgrounds, images) should use `.ignoresSafeArea()`.
- The status bar, home indicator, Dynamic Island, and rounded corners are all handled by safe areas.

#### Spacing & Padding

| Spacing | Value | Use |
|---------|-------|-----|
| **Compact** | 4pt | Between tightly related items (icon + label) |
| **Default** | 8pt | Standard gap between elements |
| **Standard** | 16pt | `.padding()` default, section spacing |
| **Large** | 20pt | Between sections in a form/detail view |
| **Extra Large** | 32pt+ | Major section breaks |

```swift
VStack(alignment: .leading, spacing: 8) {
    Text(quest.title).font(.headline)
    Text(quest.description).font(.body)
}
.padding()  // 16pt on all sides by default
```

- SwiftUI's default `.padding()` applies 16pt, matching Apple's standard margin.
- Use consistent spacing multiples (4, 8, 12, 16, 20, 24, 32).
- List rows have built-in padding -- don't add extra unless needed.

#### Adaptive Layouts

```swift
// Adapts based on available width:
ViewThatFits {
    HStack { /* Wide layout */ }
    VStack { /* Narrow layout */ }
}

// Or respond to size classes:
@Environment(\.horizontalSizeClass) var horizontalSizeClass
```

- Use `ViewThatFits` (iOS 16+) for views that should adapt their layout.
- Use `@Environment(\.horizontalSizeClass)` to switch between compact (iPhone) and regular (iPad) layouts.
- Use `Grid` and `GridRow` for aligned multi-column layouts.
- Use `LazyVGrid` / `LazyHGrid` for flowing grid layouts (e.g., quest cards).

#### Content Margins (iOS 17+)

```swift
.contentMargins(.horizontal, 20, for: .scrollContent)
```

- iOS 17 introduced `.contentMargins()` for fine-grained control over scroll view and list margins.

### Key Do's and Don'ts

**Do:**
- Use SwiftUI's default padding and spacing as your baseline.
- Use `@ScaledMetric` for spacing that should scale with Dynamic Type.
- Support both portrait and landscape orientations.
- Use `NavigationSplitView` to automatically adapt to iPad width.
- Test on the smallest (iPhone SE) and largest (iPhone Pro Max, iPad) screen sizes.

**Don't:**
- Don't use fixed frame sizes for text containers (they break with Dynamic Type).
- Don't place interactive elements closer than 44x44pt (minimum tap target).
- Don't ignore safe areas for interactive content.
- Don't use absolute positioning when stack-based layouts work.

### Quest Log Application

- **Quest list**: Standard `List` padding (automatic).
- **Quest detail view**: `.padding()` (16pt) around content within a `ScrollView`.
- **Quest cards (if using grid)**: `LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))])` for adaptive columns.
- **Minimum tap targets**: 44x44pt for all buttons, checkboxes, and interactive elements.
- **iPad**: `NavigationSplitView` with two or three columns.

---

## 6. Components

### Apple-Recommended Approach

#### Toolbars

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button("Add", systemImage: "plus") {
            showNewQuest = true
        }
    }
    ToolbarItem(placement: .topBarLeading) {
        EditButton()
    }
    ToolbarItem(placement: .bottomBar) {
        Text("\(quests.count) quests")
            .font(.caption)
    }
}
```

- Use `.toolbar` for navigation bar buttons and bottom bar content.
- Place primary actions in `.topBarTrailing` (right side).
- Use `.bottomBar` for status information or secondary actions.
- `ToolbarItemGroup(placement: .keyboard)` for input accessories.

#### Menus & Context Menus

```swift
// Long-press context menu
QuestRow(quest: quest)
    .contextMenu {
        Button("Edit", systemImage: "pencil") { ... }
        Button("Share", systemImage: "square.and.arrow.up") { ... }
        Divider()
        Button("Delete", systemImage: "trash", role: .destructive) { ... }
    } preview: {
        QuestPreviewCard(quest: quest)  // Rich preview on long-press
    }

// Pull-down menu on a button
Menu("Sort", systemImage: "arrow.up.arrow.down") {
    Picker("Sort Order", selection: $sortOrder) {
        Text("Date").tag(SortOrder.date)
        Text("Priority").tag(SortOrder.priority)
        Text("Name").tag(SortOrder.name)
    }
}
```

- Context menus appear on long-press and can include a preview.
- `Menu` creates a pull-down menu from a button tap -- ideal for sort/filter options.
- Use `Divider()` to separate groups within a menu.
- Mark destructive actions with `role: .destructive`.

#### Sheets & Full-Screen Covers

```swift
.sheet(isPresented: $showNewQuest) {
    NavigationStack {
        NewQuestForm()
            .navigationTitle("New Quest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNewQuest = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveQuest() }
                }
            }
    }
}
```

- Use `.sheet()` for creating or editing content (non-destructive, dismissible).
- Always wrap sheet content in its own `NavigationStack`.
- Include Cancel (`.cancellationAction`) and Save/Done (`.confirmationAction`) buttons.
- Sheets are dismissible via swipe-down by default -- this is expected behavior.
- Use `.interactiveDismissDisabled()` if the user has unsaved changes.
- Use `.fullScreenCover()` only for immersive experiences or when context must be entirely replaced.

#### Alerts & Confirmation Dialogs

```swift
.alert("Delete Quest?", isPresented: $showDeleteAlert) {
    Button("Delete", role: .destructive) { deleteQuest() }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("This action cannot be undone.")
}

// For multiple choices:
.confirmationDialog("Quest Actions", isPresented: $showActions) {
    Button("Complete Quest") { ... }
    Button("Archive Quest") { ... }
    Button("Delete Quest", role: .destructive) { ... }
}
```

- Use `.alert()` for critical confirmations (especially destructive actions).
- Use `.confirmationDialog()` (action sheet style) for choosing among multiple actions.
- Always include a Cancel option.
- Destructive buttons should use `role: .destructive` (displayed in red).

#### Badges

```swift
// Tab badge
Tab("Quests", systemImage: "list.bullet.clipboard") {
    QuestListView()
}
.badge(overdueCount)

// List row badge
Label("Side Quests", systemImage: "scroll")
    .badge(sideQuests.count)
```

- Badges display a count on tab bar items or list rows.
- Use badges sparingly -- only for actionable items requiring attention.
- Badge values should reflect current, real-time counts.

### Key Do's and Don'ts

**Do:**
- Use standard toolbar placements for consistent positioning.
- Provide context menus on list rows for quick actions.
- Use sheets for creation/editing flows with Cancel/Save.
- Use confirmation dialogs before destructive actions.
- Use badges to surface actionable counts.

**Don't:**
- Don't overload toolbars with too many buttons (2-3 max per side).
- Don't use alerts for non-critical information (use inline messaging instead).
- Don't put navigation actions in sheets (sheets are self-contained tasks).
- Don't use custom modal presentations when `.sheet()` or `.fullScreenCover()` suffice.

### Quest Log Application

- **Toolbar**: "+" button (top trailing) to add quest, `EditButton` (top leading) for reordering, `Menu` for sort/filter options.
- **Context menu on quest rows**: Edit, Share, Mark Complete, Delete.
- **Sheet**: New quest creation form, quest edit form.
- **Confirmation dialog**: "Complete Quest?" with XP reward preview.
- **Alert**: "Delete Quest?" with destructive confirmation.
- **Tab badges**: Count of overdue or new quests.

---

## 7. Accessibility

### Apple-Recommended Approach

Accessibility is not optional -- Apple expects all apps to support these features.

#### VoiceOver

```swift
QuestRow(quest: quest)
    .accessibilityElement(children: .combine)  // Combine child elements into one
    .accessibilityLabel("\(quest.title), \(quest.category), \(quest.status)")
    .accessibilityHint("Double tap to view quest details")
    .accessibilityAddTraits(.isButton)

// Custom actions replace swipe actions for VoiceOver:
    .accessibilityAction(named: "Complete Quest") { completeQuest(quest) }
    .accessibilityAction(named: "Delete Quest") { deleteQuest(quest) }
```

- Every interactive element needs an accessibility label.
- Use `.accessibilityElement(children: .combine)` to group related elements in list rows.
- Provide `.accessibilityHint()` for non-obvious interactions.
- Add `.accessibilityAction()` alternatives for swipe actions.
- Use `.accessibilityValue()` for progress indicators (e.g., "3 of 5 objectives complete").

#### Dynamic Type

```swift
@ScaledMetric(relativeTo: .body) var iconSize: CGFloat = 24

Image(systemName: "star.fill")
    .font(.system(size: iconSize))
```

- All text must scale with Dynamic Type (use semantic font styles).
- Use `@ScaledMetric` for custom sizes (icons, spacing) that should scale with text.
- Test at all sizes: `xSmall` through `accessibility5` (the full range).
- Layouts should adapt -- consider `AnyLayout` or `ViewThatFits` to switch from horizontal to vertical at large text sizes.

#### Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

withAnimation(reduceMotion ? nil : .spring()) {
    quest.isComplete.toggle()
}
```

- Check `accessibilityReduceMotion` and replace animations with instant transitions or simple fades.
- Never rely solely on animation to convey information.

#### Contrast

```swift
@Environment(\.colorSchemeContrast) var contrast
```

- Ensure all text meets WCAG AA contrast ratios (4.5:1 for body text, 3:1 for large text).
- System colors automatically increase contrast when the user enables "Increase Contrast" in Settings.
- Custom colors should provide high-contrast variants in the Asset Catalog.

#### Minimum Tap Targets

- All interactive elements must be at least **44x44 points**.
- Use `.frame(minWidth: 44, minHeight: 44)` or `.contentShape(Rectangle())` to expand hit areas.

### Key Do's and Don'ts

**Do:**
- Test the entire app with VoiceOver enabled.
- Support all Dynamic Type sizes including accessibility sizes.
- Respect `reduceMotion`, `reduceTransparency`, and `increaseContrast`.
- Provide accessibility labels for all images and icons.
- Use `.accessibilityAction()` as alternatives for gesture-based interactions.
- Group related information with `.accessibilityElement(children: .combine)`.

**Don't:**
- Don't convey information through color alone -- always pair with text or icons.
- Don't use thin fonts at small sizes (low contrast/legibility).
- Don't disable user interaction during animations.
- Don't create tap targets smaller than 44x44pt.
- Don't use `accessibilityHidden(true)` on informative content.

### Quest Log Application

- **Quest rows**: Combined accessibility element reading "Quest title, category, status, due date".
- **Custom rotor actions**: "Complete Quest", "Edit Quest", "Delete Quest" for VoiceOver users.
- **Progress**: Announce "3 of 5 objectives complete" via `.accessibilityValue`.
- **Status colors**: Always paired with icons (green checkmark, red exclamation) and text labels.
- **Large text**: Quest rows stack vertically when text size is accessibility-large.

---

## 8. Haptics

### Apple-Recommended Approach

iOS provides three haptic feedback generators:

| Generator | SwiftUI / UIKit | Use |
|-----------|-----------------|-----|
| **UIImpactFeedbackGenerator** | `.sensoryFeedback(.impact, ...)` | Physical interactions (button press, snap to position) |
| **UISelectionFeedbackGenerator** | `.sensoryFeedback(.selection, ...)` | Selection changes (picker, toggle) |
| **UINotificationFeedbackGenerator** | `.sensoryFeedback(.success/.warning/.error, ...)` | Outcomes (task complete, error) |

#### SwiftUI Sensory Feedback (iOS 17+)

```swift
Button("Complete Quest") {
    completeQuest()
}
.sensoryFeedback(.success, trigger: quest.isComplete)

Toggle("Active", isOn: $quest.isActive)
    .sensoryFeedback(.selection, trigger: quest.isActive)
```

#### When to Use Haptics

| Event | Feedback Type |
|-------|---------------|
| Quest completed | `.success` (notification) |
| Quest failed / overdue | `.error` (notification) |
| Quest deleted | `.warning` (notification) |
| Toggle or selection change | `.selection` |
| Swipe action triggered | `.impact(.medium)` |
| Pull to refresh triggered | `.impact(.light)` |
| Leveling up / milestone | `.success` followed by `.impact(.heavy)` |

### Key Do's and Don'ts

**Do:**
- Use haptics to reinforce meaningful actions (completing a quest is satisfying).
- Match haptic intensity to the significance of the action.
- Use `.success` for positive completions, `.error` for failures.
- Prepare feedback generators in advance (`.prepare()`) for time-sensitive responses.

**Don't:**
- Don't use haptics for every interaction (causes fatigue).
- Don't use heavy impacts for minor actions.
- Don't play haptics during background operations.
- Don't rely on haptics as the sole feedback mechanism.

### Quest Log Application

- **Quest completed**: `.success` haptic -- satisfying confirmation.
- **XP milestone / level up**: `.success` + optional `.impact(.heavy)` for emphasis.
- **Quest deleted**: `.warning` haptic.
- **Error (e.g., failed save)**: `.error` haptic.
- **Toggling quest status**: `.selection` haptic.
- **Reordering quests (drag)**: `.impact(.light)` on pickup, `.impact(.medium)` on drop.

---

## 9. App Architecture

### Apple-Recommended Approach

Apple recommends the following data flow patterns for SwiftUI apps:

#### Observable Framework (iOS 17+)

```swift
@Observable
class QuestStore {
    var quests: [Quest] = []
    var selectedQuest: Quest?

    func addQuest(_ quest: Quest) { ... }
    func completeQuest(_ quest: Quest) { ... }
}
```

- Use the `@Observable` macro (Observation framework, iOS 17+) instead of `ObservableObject` + `@Published`.
- `@Observable` provides more granular view updates (only re-renders when accessed properties change).
- Use `@State` for view-local state, `@Environment` for shared dependencies.

#### Data Flow Hierarchy

| Wrapper | Purpose | Scope |
|---------|---------|-------|
| `@State` | View-local mutable state | Single view |
| `@Binding` | Two-way reference to parent's state | Child view |
| `@Environment` | Shared dependency injection | App-wide / subtree |
| `@Observable` | Reference-type model objects | Shared models |
| `@Query` (SwiftData) | Database fetch | Persistent data |

#### SwiftData (iOS 17+)

```swift
@Model
class Quest {
    var title: String
    var questDescription: String
    var category: QuestCategory
    var priority: QuestPriority
    var isComplete: Bool
    var dueDate: Date?
    var xpReward: Int
    var objectives: [Objective]
    var createdAt: Date
    var completedAt: Date?
}

// In views:
@Query(sort: \Quest.dueDate)
var quests: [Quest]
```

- SwiftData is Apple's recommended persistence framework for SwiftUI apps (successor to Core Data).
- Use `@Model` for persistent types, `@Query` to fetch and observe data in views.
- The `ModelContainer` is configured at the app level and shared via the environment.

#### App Entry Point

```swift
@main
struct QuestLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Quest.self, Objective.self])
    }
}
```

### Key Do's and Don'ts

**Do:**
- Use `@Observable` (iOS 17+) for all model/store objects.
- Use SwiftData for persistence.
- Pass data through `@Environment` rather than long chains of init parameters.
- Keep views as thin as possible -- business logic in model/store objects.
- Use `@State` for UI-only state (e.g., `isShowingSheet`, `searchText`).

**Don't:**
- Don't use `@ObservedObject` / `@StateObject` / `@Published` in new iOS 17+ code (use `@Observable`).
- Don't put network or persistence logic directly in views.
- Don't create god objects -- split stores by domain (QuestStore, UserStore).
- Don't force unwrap optionals in views.

### Quest Log Application

- **`Quest` model**: SwiftData `@Model` with title, description, category, priority, due date, XP reward, objectives, status.
- **`QuestStore`**: `@Observable` class handling business logic (filtering, sorting, completion logic, XP calculations).
- **Environment injection**: `QuestStore` injected via `.environment()` at app root.
- **`@Query`**: Used in list views to fetch quests with sort descriptors and predicates.

---

## 10. SF Symbols

### Apple-Recommended Approach

SF Symbols is Apple's icon library with 5,000+ symbols. They are vector-based, scale with Dynamic Type, and support multiple rendering modes.

#### Rendering Modes

| Mode | Modifier | Description |
|------|----------|-------------|
| **Monochrome** | `.symbolRenderingMode(.monochrome)` | Single color (default) |
| **Hierarchical** | `.symbolRenderingMode(.hierarchical)` | Primary color with opacity layers |
| **Palette** | `.symbolRenderingMode(.palette)` | Custom colors per layer |
| **Multicolor** | `.symbolRenderingMode(.multicolor)` | Apple-defined colors |

#### Symbol Effects (iOS 17+)

```swift
Image(systemName: "checkmark.circle.fill")
    .symbolEffect(.bounce, value: quest.isComplete)

Image(systemName: "star.fill")
    .symbolEffect(.pulse, isActive: isHighlighted)
```

- `.bounce` -- momentary bounce when a value changes (quest completed).
- `.pulse` -- continuous pulsing (drawing attention to something).
- `.appear` / `.disappear` -- animated show/hide.
- `.replace` -- smooth transition between symbols.

#### Recommended Symbols for a Quest Log App

| Use Case | Symbol Name | Notes |
|----------|-------------|-------|
| **Quest / Task** | `list.bullet.clipboard` | Primary quest list icon |
| **Quest (alt)** | `scroll` | Thematic quest/scroll icon |
| **Checkbox empty** | `circle` | Incomplete objective |
| **Checkbox complete** | `checkmark.circle.fill` | Completed objective |
| **Quest complete** | `checkmark.seal.fill` | Quest completion badge |
| **Star / Rating** | `star.fill` / `star` | Priority or difficulty |
| **XP / Points** | `sparkles` | Experience points |
| **Trophy** | `trophy.fill` | Achievement / milestone |
| **Shield** | `shield.fill` | Defense / protection quest |
| **Sword** | `bolt.fill` | Attack / action quest |
| **Map** | `map` | Exploration quests |
| **Clock / Timer** | `clock` | Due date, time remaining |
| **Calendar** | `calendar` | Schedule, daily quests |
| **Flag** | `flag.fill` | Priority flag |
| **Flame** | `flame.fill` | Streak, urgency |
| **Archive** | `archivebox` | Completed/archived quests |
| **Add** | `plus` | Create new quest |
| **Edit** | `pencil` | Edit quest |
| **Delete** | `trash` | Delete quest |
| **Filter** | `line.3.horizontal.decrease.circle` | Filter quests |
| **Sort** | `arrow.up.arrow.down` | Sort options |
| **Search** | `magnifyingglass` | Search quests |
| **Settings** | `gearshape` | App settings |
| **Profile / Character** | `person.crop.circle` | User profile |
| **Level Up** | `arrow.up.circle.fill` | Level advancement |
| **Objective** | `target` | Sub-objectives |
| **Category: Main** | `shield.lefthalf.filled` | Main quests |
| **Category: Side** | `signpost.right` | Side quests |
| **Category: Daily** | `sun.max` | Daily quests |
| **Notification** | `bell.fill` | Reminders |
| **Progress** | `chart.bar.fill` | Statistics / progress |

#### Usage in SwiftUI

```swift
Label("New Quest", systemImage: "plus.circle.fill")

Image(systemName: "checkmark.circle.fill")
    .foregroundStyle(.green)
    .font(.title2)

// Variable value (iOS 16+) -- e.g., progress:
Image(systemName: "circle.dashed", variableValue: quest.progress)
```

### Key Do's and Don'ts

**Do:**
- Use SF Symbols as your primary icon set for consistency with iOS.
- Match symbol weight to the accompanying text weight.
- Use `.symbolRenderingMode(.hierarchical)` for richer icons with minimal effort.
- Use symbol effects sparingly for meaningful state changes.
- Use `Label("Text", systemImage: "icon")` for icon+text pairs (accessibility-friendly).

**Don't:**
- Don't use custom icons when an SF Symbol exists for the concept.
- Don't mix SF Symbols with a different icon set (visual inconsistency).
- Don't use overly complex symbol effects (distracting).
- Don't forget to check the SF Symbols app for the latest available symbols.

### Quest Log Application

- **Tab bar icons**: `list.bullet.clipboard` (Quests), `archivebox` (Archive), `person.crop.circle` (Profile).
- **Quest status**: `circle` (incomplete) -> `checkmark.circle.fill` (complete) with `.bounce` effect.
- **Priority flags**: `flag.fill` tinted by priority color.
- **XP display**: `sparkles` icon next to XP amount.
- **Category badges**: Themed symbols (shield for main, signpost for side, sun for daily).
- **Toolbar**: `plus` for add, `arrow.up.arrow.down` for sort, `line.3.horizontal.decrease.circle` for filter.

---

## Quick Reference: Complete Quest Row Example

```swift
struct QuestRow: View {
    let quest: Quest
    @ScaledMetric(relativeTo: .headline) private var iconSize: CGFloat = 24

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: quest.isComplete ? "checkmark.circle.fill" : "circle")
                .font(.system(size: iconSize))
                .foregroundStyle(quest.isComplete ? .green : .secondary)
                .symbolEffect(.bounce, value: quest.isComplete)

            // Quest info
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .font(.headline)
                    .strikethrough(quest.isComplete)
                    .foregroundStyle(quest.isComplete ? .secondary : .primary)

                HStack(spacing: 8) {
                    Label(quest.category.rawValue, systemImage: quest.category.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dueDate = quest.dueDate {
                        Label(dueDate.formatted(.relative(presentation: .named)),
                              systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(quest.isOverdue ? .red : .secondary)
                    }
                }
            }

            Spacer()

            // XP reward
            Label("\(quest.xpReward) XP", systemImage: "sparkles")
                .font(.caption.bold())
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Complete Quest") { /* toggle */ }
    }
}
```

---

## Quick Reference: Recommended Architecture Skeleton

```
QuestLogApp/
├── App/
│   └── QuestLogApp.swift            // @main, ModelContainer setup
├── Models/
│   ├── Quest.swift                  // @Model (SwiftData)
│   ├── Objective.swift              // @Model
│   └── QuestCategory.swift          // Enum
├── Stores/
│   └── QuestStore.swift             // @Observable business logic
├── Views/
│   ├── ContentView.swift            // TabView root
│   ├── QuestList/
│   │   ├── QuestListView.swift      // NavigationStack + List + .searchable
│   │   └── QuestRow.swift           // Individual row
│   ├── QuestDetail/
│   │   └── QuestDetailView.swift    // Full quest details
│   ├── QuestForm/
│   │   └── QuestFormView.swift      // Create/edit sheet
│   ├── Archive/
│   │   └── ArchiveView.swift        // Completed quests
│   └── Profile/
│       └── ProfileView.swift        // User stats, settings
├── Components/
│   ├── QuestStatusBadge.swift       // Reusable status indicator
│   ├── XPLabel.swift                // XP display component
│   └── ProgressRing.swift           // Circular progress
├── Utilities/
│   └── HapticManager.swift          // Centralized haptic feedback
└── Assets.xcassets/
    ├── AccentColor.colorset/        // App accent (light + dark)
    └── Custom colors/               // Rarity colors, etc.
```

---

## Summary of Critical HIG Principles

1. **Consistency**: Use standard iOS patterns (NavigationStack, TabView, List, sheets). Users already know how these work.
2. **Direct Manipulation**: Swipe actions, drag-to-reorder, and tap interactions should feel immediate and responsive.
3. **Feedback**: Every action should have clear visual + haptic feedback. Completing a quest should feel rewarding.
4. **Clarity**: Typography hierarchy, SF Symbols, and semantic colors make content scannable and understandable at a glance.
5. **Accessibility**: Support VoiceOver, Dynamic Type, Reduce Motion, and Increase Contrast from day one -- not as an afterthought.
6. **Adaptability**: Use responsive layouts that work on iPhone SE through iPad Pro, in both orientations, in Light and Dark mode.
7. **Deference**: The UI should highlight the user's content (their quests) -- not the chrome. Use system backgrounds, standard controls, and subtle styling.

---

*Reference: Apple Human Interface Guidelines (https://developer.apple.com/design/human-interface-guidelines/), SF Symbols (https://developer.apple.com/sf-symbols/), SwiftUI Documentation (https://developer.apple.com/documentation/swiftui/). Guidelines current through iOS 18 / WWDC 2024.*
