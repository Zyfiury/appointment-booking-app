# Notification Setup Guide

## ✅ What's Implemented

1. **Onboarding Flow** - Beautiful welcome screens for first-time users
2. **Settings Screen** - Complete settings with notification preferences
3. **Notification Service** - Local notifications for appointment reminders
4. **Auto Reminders** - Automatically schedules 24h and 2h reminders when booking

## 📱 Android Setup

### 1. Add Permissions to `android/app/src/main/AndroidManifest.xml`

Add these permissions inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

### 2. Create Notification Channel

The notification service automatically creates channels, but you can customize them in `lib/services/notification_service.dart`.

## 🍎 iOS Setup

### 1. Add to `ios/Runner/Info.plist`

Add these keys:

```xml
<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
<key>UIUserNotificationSettings</key>
<dict>
    <key>UIUserNotificationTypeAlert</key>
    <true/>
    <key>UIUserNotificationTypeBadge</key>
    <true/>
    <key>UIUserNotificationTypeSound</key>
    <true/>
</dict>
```

### 2. Request Permissions

The app will automatically request notification permissions on first launch.

## 🚀 How It Works

1. **When user books an appointment:**
   - Automatically schedules 24-hour reminder
   - Automatically schedules 2-hour reminder
   - Reminders are stored locally on device

2. **Notification Types:**
   - Appointment reminders (24h before, 2h before)
   - Booking confirmations (instant)
   - Cancellation alerts (instant)

3. **User Control:**
   - Users can enable/disable notifications in Settings
   - Separate toggles for push, email, and reminders
   - Settings are saved locally

## 🔔 Testing Notifications

To test notifications quickly, you can temporarily change the reminder time:

```dart
// In book_appointment_screen.dart, change:
reminderBefore: const Duration(minutes: 1), // Test with 1 minute
```

## 📝 Next Steps (Optional)

1. **Firebase Cloud Messaging (FCM)** - For push notifications from server
2. **Background Tasks** - Sync reminders when app is closed
3. **Rich Notifications** - Add images, actions, and more details
4. **Notification Actions** - Quick actions like "Reschedule" or "Cancel"

## ⚠️ Important Notes

- Notifications work even when app is closed
- Reminders are scheduled locally (no server needed)
- Users must grant notification permissions
- On Android 13+, runtime permission is required
