# Fix Appointment Type Error

## Problem
The Flutter app is showing an error:
```
type '_Map<String, dynamic>' is not a subtype of type 'List<dynamic>'
```

This happens when trying to load appointments.

## Root Cause
The backend API can return appointments in different formats:
1. **Plain list** (when no pagination): `[{...}, {...}]`
2. **Paginated response** (when pagination params provided): `{ data: [...], pagination: {...} }`
3. **Error object**: `{ error: "..." }`

The Flutter app was expecting only a list, causing a type mismatch when it received an object.

## Solution Applied

### Updated `AppointmentService.getAppointments()`

The service now handles all response formats:

1. **Checks for error objects**: If response contains `error` key, throws exception
2. **Handles paginated responses**: Extracts `data` array from paginated responses
3. **Validates list format**: Ensures final data is a list before parsing
4. **Enhanced logging**: Added debug prints to help diagnose issues
5. **Better error messages**: More descriptive errors for debugging

### Code Changes

**File**: `appointment_booking_app/lib/services/appointment_service.dart`

- Added response type detection
- Handles both plain lists and paginated responses
- Better error handling and logging
- Validates data structure before parsing

## Testing

1. **Run the app**: `flutter run`
2. **Check logs**: Look for debug prints showing response type
3. **Test appointments**: Should now load without type errors

## Expected Behavior

- ✅ Empty appointments: Returns empty list `[]`
- ✅ Appointments list: Returns list of appointments
- ✅ Paginated response: Extracts and returns data array
- ✅ Error response: Shows clear error message

## Debug Information

The service now logs:
- Response type received
- Whether pagination was detected
- Number of appointments parsed
- Any parsing errors

Check Flutter console for these debug messages.
