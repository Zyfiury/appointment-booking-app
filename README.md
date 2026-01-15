# Appointment Booking Mobile App

A professional Flutter mobile application for booking appointments with service providers. This app allows customers to book appointments and enables providers to manage their services and appointments.

## Features

### For Customers:
- User registration and authentication
- Browse available service providers
- Book appointments with date and time selection
- View and manage personal appointments
- Cancel appointments

### For Service Providers:
- Provider registration and authentication
- Create and manage services (with pricing, duration, categories)
- View all appointments
- Confirm, cancel, or mark appointments as completed
- Dashboard with appointment statistics

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **Dio** - HTTP client for API calls
- **Shared Preferences** - Local storage
- **Material Design 3** - Modern UI design

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Backend server running on `http://localhost:5000`

## Installation & Setup

### Step 1: Install Dependencies

```bash
cd appointment_booking_app
flutter pub get
```

### Step 2: Run the Backend Server

Make sure your backend server is running:
```bash
cd ../server
npm run dev
```

The server should be running on `http://localhost:5000`

### Step 3: Run the Flutter App

**For Android:**
```bash
flutter run
```

**For iOS (Mac only):**
```bash
flutter run
```

**For Web:**
```bash
flutter run -d chrome
```

**For Windows:**
```bash
flutter run -d windows
```

## API Configuration

The app automatically detects the platform and uses the appropriate base URL:
- **Android Emulator**: `http://10.0.2.2:5000/api`
- **iOS Simulator**: `http://localhost:5000/api`
- **Web**: `http://localhost:5000/api`
- **Physical Device**: Use your computer's IP address (e.g., `http://192.168.1.100:5000/api`)

To change the API URL, edit `lib/services/api_service.dart`.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── appointment.dart
│   ├── service.dart
│   └── provider.dart
├── services/                 # API services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── appointment_service.dart
│   └── service_service.dart
├── providers/               # State management
│   └── auth_provider.dart
├── screens/                 # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── customer/
│   │   ├── dashboard_screen.dart
│   │   ├── book_appointment_screen.dart
│   │   └── my_appointments_screen.dart
│   └── provider/
│       ├── provider_dashboard_screen.dart
│       └── manage_services_screen.dart
├── widgets/                 # Reusable widgets
│   ├── appointment_card.dart
│   └── loading_overlay.dart
└── theme/                   # App theme
    └── app_theme.dart
```

## Usage Guide

### For Customers:

1. **Register/Login**: Create an account or login with existing credentials
2. **Book Appointment**: 
   - Navigate to "Book Appointment"
   - Select a provider
   - Choose a service
   - Pick a date and time
   - Add optional notes
   - Confirm booking
3. **Manage Appointments**: View all your appointments and cancel if needed

### For Service Providers:

1. **Register/Login**: Create a provider account
2. **Manage Services**: 
   - Go to "Manage Services"
   - Add services with name, description, duration, price, and category
   - Edit or delete existing services
3. **Manage Appointments**:
   - View all appointments in the dashboard
   - Confirm pending appointments
   - Mark appointments as completed
   - Cancel appointments if needed

## Building for Production

### Android APK:
```bash
flutter build apk --release
```

### Android App Bundle:
```bash
flutter build appbundle --release
```

### iOS:
```bash
flutter build ios --release
```

## Troubleshooting

### API Connection Issues

If you're running on a physical device:
1. Make sure your device and computer are on the same network
2. Find your computer's IP address
3. Update `baseUrl` in `lib/services/api_service.dart` to use your IP

### Android Emulator Issues

The app uses `10.0.2.2` for Android emulator, which is the special IP that maps to `localhost` on your host machine.

## License

MIT License
