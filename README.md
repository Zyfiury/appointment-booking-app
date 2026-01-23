<<<<<<< HEAD
# Appointment Booking Application

A professional, full-stack appointment booking application similar to Booksy. This application allows customers to book appointments with service providers (doctors, consultants, etc.) and enables providers to manage their services and appointments.
=======
# Appointment Booking Mobile App

A professional Flutter mobile application for booking appointments with service providers. This app allows customers to book appointments and enables providers to manage their services and appointments.
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

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

<<<<<<< HEAD
### Backend:
- Node.js with Express
- TypeScript
- JSON file-based database (easily migratable to SQL/NoSQL)
- JWT authentication
- bcrypt for password hashing

### Frontend:
- React with TypeScript
- React Router for navigation
- Axios for API calls
- Modern CSS with responsive design

## Installation & Setup

### Prerequisites
- Node.js (v14 or higher)
- npm or yarn

### Step 1: Install Dependencies

Install server dependencies:
```bash
cd server
npm install
```

Install client dependencies:
```bash
cd client
npm install
```

### Step 2: Run the Application

**Terminal 1 - Start the backend server:**
```bash
cd server
npm run dev
```
Server will run on http://localhost:5000

**Terminal 2 - Start the frontend client:**
```bash
cd client
npm start
```
Frontend will run on http://localhost:3000

### Step 3: Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:5000
=======
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
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

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

<<<<<<< HEAD
## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (protected)

### Users
- `GET /api/users/providers` - Get all providers
- `GET /api/users/providers/:id` - Get provider by ID
- `GET /api/users/profile` - Get user profile (protected)
- `PATCH /api/users/profile` - Update user profile (protected)

### Services
- `GET /api/services` - Get all services (optional ?providerId query)
- `GET /api/services/:id` - Get service by ID
- `POST /api/services` - Create service (provider only)
- `PATCH /api/services/:id` - Update service (provider only)
- `DELETE /api/services/:id` - Delete service (provider only)

### Appointments
- `GET /api/appointments` - Get user's appointments (protected)
- `GET /api/appointments/:id` - Get appointment by ID (protected)
- `POST /api/appointments` - Create appointment (customer only)
- `PATCH /api/appointments/:id` - Update appointment (protected)
- `DELETE /api/appointments/:id` - Delete appointment (protected)

## Project Structure

```
cursor/
├── server/
│   ├── data/
│   │   ├── database.ts          # Database operations
│   │   └── db.json              # JSON database file (auto-generated)
│   ├── middleware/
│   │   └── auth.ts              # Authentication middleware
│   ├── routes/
│   │   ├── auth.ts              # Authentication routes
│   │   ├── appointments.ts      # Appointment routes
│   │   ├── users.ts             # User routes
│   │   └── services.ts          # Service routes
│   ├── index.ts                 # Server entry point
│   ├── package.json
│   └── tsconfig.json
├── client/
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   ├── components/          # React components
│   │   ├── context/             # React context (Auth)
│   │   ├── pages/               # Page components
│   │   ├── services/            # API service
│   │   ├── App.tsx
│   │   └── index.tsx
│   ├── package.json
│   └── tsconfig.json
└── README.md
```

## Security Notes

- Passwords are hashed using bcrypt
- JWT tokens are used for authentication
- Protected routes require valid authentication
- Role-based access control for different user types

## Future Enhancements

- Email notifications for appointments
- Calendar view for appointments
- Recurring appointments
- Payment integration
- Reviews and ratings
- Advanced search and filtering
- Real-time notifications
- Database migration to PostgreSQL/MongoDB
=======
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
>>>>>>> 977022b4e2c96e2f5dbd2736064f2ea6e482d209

## License

MIT License
