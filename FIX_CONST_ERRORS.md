# Fixing Const Evaluation Errors

Due to the new dynamic theme system, widgets using `const` with `AppTheme` properties need to be updated.

## Quick Fix Options:

### Option 1: Remove `const` keyword
Find: `const Text(..., style: TextStyle(color: AppTheme.primaryColor))`
Replace: `Text(..., style: TextStyle(color: AppTheme.primaryColor))`

### Option 2: Use Theme.of(context) (Recommended for dynamic theming)
Find: `AppTheme.primaryColor`
Replace: `Theme.of(context).colorScheme.primary`

Find: `AppTheme.textPrimary`  
Replace: `Theme.of(context).colorScheme.onSurface`

Find: `AppTheme.textSecondary`
Replace: `Theme.of(context).colorScheme.onSurface.withOpacity(0.7)`

Find: `AppTheme.errorColor`
Replace: `Theme.of(context).colorScheme.error`

Find: `AppTheme.darkGradient`
Replace: Use `Consumer<ThemeProvider>` to get current theme colors and create gradient

## Files needing updates:
- All auth screens (login, register, forgot_password, reset_password)
- All customer screens (dashboard, search, map, payment, etc.)
- All provider screens
- Settings screens
- Widgets (appointment_card, etc.)

## Quick Script to Remove Const:
You can use find/replace in your IDE:
- Find: `const ` (with space)
- Replace: ` ` (just space)
- Then manually review each instance

The theme system is working correctly - these are just compile-time const errors that need to be resolved.
