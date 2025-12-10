# Implementation Plan

- [x] 1. Update HomeController to use RxBool for search bar visibility


  - Replace `StreamController<bool> searchBarStream` with `RxBool showSearchBar`
  - Initialize `showSearchBar` in `onInit()` based on `hideSearchBar` setting
  - Remove stream disposal code if present in `onClose()`
  - _Requirements: 2.1, 2.3_

- [ ]* 1.1 Write property test for HomeController initialization
  - **Property 1: Search bar visibility initialization**
  - **Validates: Requirements 2.1**

- [ ]* 1.2 Write property test for controller lifecycle
  - **Property 4: Controller lifecycle persistence**
  - **Validates: Requirements 2.3**



- [ ] 2. Update CustomAppBar to use Obx instead of StreamBuilder
  - Remove `stream` parameter from CustomAppBar constructor
  - Replace `StreamBuilder` with `Obx` widget
  - Update opacity and height to observe `ctr.showSearchBar.value`
  - _Requirements: 1.4, 2.2, 2.5_

- [x]* 2.1 Write property test for rebuild restoration


  - **Property 3: Rebuild restoration**
  - **Validates: Requirements 1.4**


- [ ] 3. Update HomePage to remove stream initialization
  - Remove `stream` variable declaration from `_HomePageState`
  - Remove stream initialization in `initState()`
  - Update `CustomAppBar` instantiation to remove `stream` parameter
  - _Requirements: 1.1, 1.2, 1.3_

- [ ]* 3.1 Write property test for navigation persistence
  - **Property 2: Navigation persistence**
  - **Validates: Requirements 1.1, 1.3, 3.3, 3.5**

- [ ]* 3.2 Write property test for tab switching
  - **Property 5: Tab switching preservation**
  - **Validates: Requirements 3.1**

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ]* 5. Write integration tests for navigation scenarios
  - Test video tag navigation (original bug scenario)
  - Test topic tag navigation
  - Test BGM tag navigation
  - Test search navigation
  - _Requirements: 1.1, 1.2, 1.3, 3.3_

- [ ]* 6. Write property test for app lifecycle
  - **Property 6: App lifecycle persistence**
  - **Validates: Requirements 3.4**

- [ ] 7. Manual testing and verification
  - Test all navigation scenarios from manual testing checklist
  - Verify search bar remains visible after tag clicks
  - Verify tab switching doesn't affect search bar
  - Verify scroll behavior still works with hideSearchBar setting
  - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.2, 3.3_

