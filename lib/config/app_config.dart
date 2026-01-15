/// App Configuration
/// Centralized configuration for production vs development
class AppConfig {
  // App Information
  static const String appName = 'Bookly';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.example.appointment_booking_app';

  // Environment
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  
  // API Configuration
  // IMPORTANT: After deploying your backend, update this URL
  // Example: 'https://bookly-api.railway.app/api'
  // Example: 'https://bookly-api.render.com/api'
  static String get apiBaseUrl {
    // Get from environment variable or use default
    // You can set this via: --dart-define=API_URL=https://your-api.com/api
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    
    // Default production URL (update this after deployment)
    if (isProduction) {
      return 'https://your-api-url.com/api'; // TODO: Replace with your production URL
    }
    
    // Development - will use automatic detection in ApiService
    return '';
  }

  // Stripe Configuration
  static String get stripePublishableKey {
    if (isProduction) {
      return 'pk_live_YOUR_PRODUCTION_KEY'; // TODO: Replace with production key
    }
    return 'pk_test_YOUR_TEST_KEY'; // TODO: Replace with test key
  }

  // Google Maps
  static const String googleMapsApiKey = 'AIzaSyD8MxsP_0XEll578wlse8IMuLK-z5VmcwY';

  // Privacy & Legal
  static const String privacyPolicyUrl = 'https://yourdomain.com/privacy'; // TODO: Replace
  static const String termsOfServiceUrl = 'https://yourdomain.com/terms'; // TODO: Replace
  static const String supportEmail = 'support@yourdomain.com'; // TODO: Replace

  // Feature Flags
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePushNotifications = true;
}
