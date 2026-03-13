# Comprehensive Dark Mode Update

This file contains the pattern to apply dark mode to all screens.

## Standard Dark Mode Pattern

```dart
// At the beginning of build method, add:
final isDark = Theme.of(context).brightness == Brightness.dark;
final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
final textColor = isDark ? Colors.white : Colors.black;
final subtextColor = isDark ? Colors.grey[400] : Colors.grey[600];
final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
```

## Replace Pattern in All Screens

### 1. Cards
```dart
// Before:
Card(
  child: ...
)

// After:
Card(
  color: cardColor,
  child: ...
)
```

### 2. Text (Primary)
```dart
// Before:
Text('Something', style: TextStyle(fontSize: 16))

// After:
Text('Something', style: TextStyle(fontSize: 16, color: textColor))
```

### 3. Text (Secondary/Grey)
```dart
// Before:
Text('Something', style: TextStyle(color: Colors.grey))

// After:
Text('Something', style: TextStyle(color: subtextColor))
```

### 4. Icons (Grey)
```dart
// Before:
Icon(Icons.something, color: Colors.grey)

// After:
Icon(Icons.something, color: subtextColor)
```

### 5. Containers with Background
```dart
// Before:
Container(color: Colors.white, ...)

// After:
Container(color: cardColor, ...)
```

### 6. Borders
```dart
// Before:
border: Border.all(color: Colors.grey[300]!)

// After:
border: Border.all(color: borderColor)
```

### 7. Dividers
```dart
// Before:
Divider()

// After:
Divider(color: isDark ? Colors.grey[700] : null)
```

## Screens to Update

### Customer Screens
- [ ] multi_order_checkout_screen.dart
- [x] multi_order_flow_screen.dart
- [x] customer_dashboard.dart
- [x] cart_screen.dart (partial)
- [x] my_orders_screen.dart

### Restaurant Screens
- [x] restaurant_dashboard.dart
- [x] menu_management_screen.dart
- [x] restaurant_orders_screen.dart
- [x] restaurant_settings_screen.dart

### Delivery Screens
- [x] delivery_partner_dashboard.dart
- [x] available_deliveries_screen.dart
- [x] my_deliveries_screen.dart
- [x] delivery_earnings_screen.dart

### Admin Screens
- [ ] admin_dashboard.dart

## Quick Commands for Each File

For manual updates, search and replace:
1. `Colors.white` in Container/Card → `cardColor`
2. `color: Colors.grey` → `color: subtextColor`
3. `Colors.grey[300]` → `borderColor`
4. Add `color: textColor` to all Text widgets without explicit color
5. Add `color: cardColor` to all Cards

## Testing Checklist
- [ ] Toggle dark mode in device settings
- [ ] Check all text is readable
- [ ] Verify cards stand out from background
- [ ] Ensure icons are visible
- [ ] Test all screens in both modes