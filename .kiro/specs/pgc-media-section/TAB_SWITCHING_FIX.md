# Tab Switching Fix - Independent Controller Instances

## Problem
When switching tabs in the influence index page (PageView + TabBar), the page was using a single shared controller instance for all tabs. This caused:
- Shared scroll controller state across tabs
- Shared loading state and data across tabs
- Filtering conditions not being independent per tab
- Scroll position not being maintained per tab

## Solution
Implemented separate controller instances for each tab:

### Changes Made

#### 1. `lib/pages/pgc_index/view.dart`
- **Removed**: Single `_controller` instance
- **Added**: 
  - `_mainController` for bangumi index (single tab, no PageView)
  - `_tabControllers` map to store separate controller instances for each media type tab
  - `_getTabController(int tabIndex)` method to get or create controller for a specific tab
  
- **Updated methods** to accept `PgcIndexController` parameter:
  - `_buildFilterWidget()` - now takes controller parameter
  - `_buildSortsWidget()` - now takes controller parameter
  - `_buildSortChip()` - now takes controller parameter
  - `_buildContentList()` - now takes controller parameter
  - `_buildListBody()` - now takes controller parameter

- **Updated `_buildMediaPage()`**:
  - Gets independent controller for each tab via `_getTabController()`
  - Each tab maintains its own state, scroll position, and filtering conditions

- **Updated `dispose()`**:
  - Properly cleans up all tab controllers from GetX

#### 2. `lib/pages/pgc_index/controller.dart`
- **Added**: `tag` property to identify controller instances in GetX

### Benefits
1. **Independent State**: Each tab maintains its own:
   - Scroll position
   - Loading state
   - Data list
   - Filtering conditions
   - Expand/collapse state

2. **Smooth Tab Switching**: Users can:
   - Switch between tabs without losing scroll position
   - Apply different filters to different tabs
   - See independent content for each media type

3. **Better Memory Management**: Controllers are properly tagged and cleaned up on page disposal

## Testing
- Tab switching should now be smooth with independent state per tab
- Scroll position should be maintained when switching tabs
- Filtering conditions should be independent per tab
- No shared state issues between tabs
