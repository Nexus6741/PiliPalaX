# Design Document: Search Box Persistence Fix

## Overview

This design addresses the search box disappearing issue on the HomePage. The root cause is the use of `StreamController<bool>` for managing search bar visibility, which doesn't properly maintain state across navigation events. The solution replaces the stream-based approach with GetX's reactive state management (`RxBool`), providing more reliable and predictable state persistence.

## Architecture

### Current Architecture Issues

1. **StreamController State Loss**: The `searchBarStream` in `HomeController` uses a broadcast stream that doesn't guarantee state persistence when the HomePage is rebuilt after navigation
2. **StreamBuilder Initialization**: The `StreamBuilder` in `CustomAppBar` has `initialData: true`, but the stream may not emit the correct value after navigation
3. **State Management Inconsistency**: The app uses GetX for most state management, but the search bar uses streams, creating inconsistency

### Proposed Architecture

Replace the stream-based visibility control with GetX reactive state management:

```
HomeController
├── showSearchBar: RxBool (replaces searchBarStream)
├── hideSearchBar: bool (configuration from settings)
└── onInit(): Initialize showSearchBar based on hideSearchBar setting

CustomAppBar
├── Uses Obx() instead of StreamBuilder
└── Reacts to showSearchBar.value changes
```

## Components and Interfaces

### Modified Components

#### 1. HomeController

**Changes**:
- Remove: `StreamController<bool> searchBarStream`
- Add: `RxBool showSearchBar = true.obs`
- Update `onInit()`: Initialize `showSearchBar` based on `hideSearchBar` setting
- Remove stream disposal in `onClose()`

**Interface**:
```dart
class HomeController extends GetxController {
  // Remove
  // late final StreamController<bool> searchBarStream;
  
  // Add
  late RxBool showSearchBar;
  
  @override
  void onInit() {
    super.onInit();
    // ... existing code ...
    
    // Initialize search bar visibility
    showSearchBar = (!hideSearchBar).obs;
  }
  
  // Remove onClose() if it only disposes the stream
}
```

#### 2. CustomAppBar (in HomePage)

**Changes**:
- Replace `StreamBuilder` with `Obx`
- Remove `stream` parameter from constructor
- Directly observe `ctr.showSearchBar.value`

**Interface**:
```dart
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final HomeController ctr;

  const CustomAppBar({
    super.key,
    this.height = kToolbarHeight,
    required this.ctr,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedOpacity(
      opacity: ctr.showSearchBar.value ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        curve: Curves.easeInOutCubicEmphasized,
        duration: const Duration(milliseconds: 500),
        height: ctr.showSearchBar.value ? 52 : 0,
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
        child: SearchBarAndUser(ctr: ctr),
      ),
    ));
  }
}
```

#### 3. HomePage

**Changes**:
- Remove `stream` variable
- Remove stream initialization in `initState()`
- Update `CustomAppBar` instantiation to remove `stream` parameter

**Interface**:
```dart
class _HomePageState extends State<HomePage> {
  final HomeController _homeController = Get.put(HomeController());
  
  @override
  void initState() {
    super.initState();
    // Remove: stream = _homeController.searchBarStream.stream;
  }
  
  @override
  Widget build(BuildContext context) {
    // ... existing code ...
    
    CustomAppBar(
      // Remove: stream parameter
      ctr: _homeController,
    ),
  }
}
```

## Data Models

No new data models are required. The change involves replacing a `StreamController<bool>` with `RxBool`, both representing boolean visibility state.

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Search bar visibility initialization

*For any* HomePage initialization with hideSearchBar setting set to false, the showSearchBar state should be initialized to true

**Validates: Requirements 2.1**

### Property 2: Navigation persistence

*For any* navigation sequence from HomePage to one or more external pages (video, search, topic, etc.) and back to HomePage, the showSearchBar state should remain true when hideSearchBar is false

**Validates: Requirements 1.1, 1.3, 3.3, 3.5**

### Property 3: Rebuild restoration

*For any* HomePage rebuild event (including after navigation), the search bar visibility should be true by default when hideSearchBar is false

**Validates: Requirements 1.4**

### Property 4: Controller lifecycle persistence

*For any* HomeController dispose and recreate cycle, the showSearchBar state should be reinitialized to true when hideSearchBar is false

**Validates: Requirements 2.3**

### Property 5: Tab switching preservation

*For any* sequence of tab switches on HomePage, the showSearchBar state should remain unchanged from its initial value

**Validates: Requirements 3.1**

### Property 6: App lifecycle persistence

*For any* app background and foreground cycle, the showSearchBar state should maintain its value before the app was backgrounded

**Validates: Requirements 3.4**

## Error Handling

### Potential Issues and Mitigations

1. **GetX Controller Not Found**
   - **Issue**: If `Get.put(HomeController())` is called multiple times, it might create multiple instances
   - **Mitigation**: Use `Get.find<HomeController>()` in child widgets instead of `Get.put()`
   - **Fallback**: The existing `Get.put()` call with default behavior should work correctly

2. **Obx Rebuild Performance**
   - **Issue**: Excessive rebuilds if showSearchBar changes frequently
   - **Mitigation**: The search bar visibility only changes on scroll (if hideSearchBar is true) or initialization, so performance impact is minimal
   - **Monitoring**: No special monitoring needed as Obx is optimized for this use case

3. **Settings Change During Runtime**
   - **Issue**: If hideSearchBar setting changes while app is running
   - **Mitigation**: The setting is only read during `onInit()`, which is acceptable behavior
   - **Enhancement**: Could add a listener to update showSearchBar when setting changes (not required for this fix)

## Testing Strategy

### Unit Testing

Unit tests will verify:
1. HomeController initializes showSearchBar correctly based on hideSearchBar setting
2. showSearchBar value persists across simulated navigation events
3. CustomAppBar correctly observes showSearchBar changes

Example unit test structure:
```dart
test('HomeController initializes showSearchBar to true when hideSearchBar is false', () {
  // Setup: Mock settings with hideSearchBar = false
  // Execute: Create HomeController instance
  // Verify: showSearchBar.value == true
});

test('showSearchBar remains true after navigation simulation', () {
  // Setup: Create HomeController with showSearchBar = true
  // Execute: Simulate navigation by rebuilding widget tree
  // Verify: showSearchBar.value == true
});
```

### Integration Testing

Integration tests will verify:
1. Search bar remains visible after navigating to video details and back
2. Search bar remains visible after clicking tag → search results → back
3. Search bar visibility persists across tab switches
4. Search bar responds correctly to scroll events (if hideSearchBar is true)

Example integration test structure:
```dart
testWidgets('Search bar persists after video tag navigation', (tester) async {
  // Setup: Launch app and navigate to HomePage
  // Execute: 
  //   1. Verify search bar is visible
  //   2. Navigate to video details
  //   3. Click a tag to open search results
  //   4. Navigate back to HomePage
  // Verify: Search bar is still visible
});
```

### Property-Based Testing

Property-based tests will verify the correctness properties defined above. We'll use the `test` package with custom generators for navigation sequences.

**Testing Library**: Dart's built-in `test` package with custom property testing utilities

**Configuration**: Each property test will run a minimum of 100 iterations

**Test Tagging**: Each property-based test will include a comment with the format:
`// Feature: search-box-persistence, Property {number}: {property_text}`

Example property test structure:
```dart
// Feature: search-box-persistence, Property 2: Search bar visibility persistence across navigation
test('Property: Search bar persists across random navigation sequences', () {
  for (int i = 0; i < 100; i++) {
    // Generate random navigation sequence
    // Execute navigation
    // Verify showSearchBar.value == true at end
  }
});
```

### Manual Testing Checklist

1. **Basic Navigation**
   - [ ] Open app → verify search bar visible
   - [ ] Navigate to video → back → verify search bar visible
   - [ ] Navigate to search → back → verify search bar visible

2. **Tag Navigation (Original Bug)**
   - [ ] Open video details
   - [ ] Click normal tag → search results
   - [ ] Back to HomePage → verify search bar visible
   - [ ] Click topic tag → topic page
   - [ ] Back to HomePage → verify search bar visible
   - [ ] Click BGM tag → music page
   - [ ] Back to HomePage → verify search bar visible

3. **Tab Switching**
   - [ ] Switch between tabs → verify search bar remains visible
   - [ ] Navigate away and back → switch tabs → verify search bar visible

4. **Settings Integration**
   - [ ] Enable "hide search bar on scroll" → verify scroll behavior works
   - [ ] Disable "hide search bar on scroll" → verify search bar always visible

5. **Edge Cases**
   - [ ] Rapid navigation (back/forward quickly) → verify search bar stable
   - [ ] App background/foreground → verify search bar visible
   - [ ] Rotate device (if applicable) → verify search bar visible

## Implementation Notes

### Migration Steps

1. **Update HomeController**
   - Add `late RxBool showSearchBar;`
   - Initialize in `onInit()`: `showSearchBar = (!hideSearchBar).obs;`
   - Remove `searchBarStream` declaration and initialization
   - Remove stream disposal in `onClose()` if present

2. **Update CustomAppBar**
   - Remove `stream` parameter from constructor
   - Replace `StreamBuilder` with `Obx`
   - Update opacity and height to use `ctr.showSearchBar.value`

3. **Update HomePage**
   - Remove `stream` variable declaration
   - Remove stream initialization in `initState()`
   - Update `CustomAppBar` instantiation to remove `stream` parameter

### Backward Compatibility

This change is internal to the HomePage and doesn't affect any public APIs. No backward compatibility concerns.

### Performance Considerations

- **Obx Performance**: Obx widgets are highly optimized and only rebuild when observed values change
- **Memory**: Removing StreamController reduces memory overhead slightly
- **Rebuild Frequency**: Search bar visibility changes are infrequent (only on init or scroll), so performance impact is negligible

### Code Quality

- **Consistency**: Aligns with existing GetX patterns used throughout the app
- **Simplicity**: Reduces code complexity by removing stream management
- **Maintainability**: Easier to understand and debug reactive state vs. streams

## Future Enhancements

1. **Dynamic Settings Update**: Add listener to update showSearchBar when hideSearchBar setting changes at runtime
2. **Animation Improvements**: Consider adding more sophisticated show/hide animations
3. **State Persistence**: Consider persisting search bar visibility state across app restarts (if desired)
4. **Accessibility**: Ensure search bar visibility changes are announced to screen readers

