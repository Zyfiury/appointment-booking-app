import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// AI Chatbot Service for Bookly
/// Provides intelligent help and support through AI-powered conversations
class ChatbotService {
  // OpenAI API configuration
  static const String _openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // FAQ database for quick responses (rule-based)
  static final Map<String, String> _faqDatabase = {
    'book appointment': 'To book an appointment: 1) Tap "Book Appointment" on the dashboard, 2) Search for a provider, 3) Select a service, 4) Choose date and time, 5) Confirm booking.',
    'cancel appointment': 'To cancel: Go to "My Appointments", find the appointment, tap on it, and select "Cancel Appointment".',
    'reschedule appointment': 'To reschedule: Go to "My Appointments", select the appointment, and choose "Reschedule" to pick a new date and time.',
    'payment': 'After booking, you\'ll be redirected to the payment screen. Enter your card details and complete the payment securely using Stripe.',
    'forgot password': 'Go to the login screen and tap "Forgot Password". Enter your email to receive a password reset link.',
    'change email': 'Go to Settings > Edit Profile to update your email address.',
    'update profile': 'Navigate to Settings > Edit Profile to update your name, phone, address, or profile picture.',
    'become provider': 'Register as a provider during signup, or contact support to convert your account to a provider account.',
    'add service': 'As a provider, go to "Manage Services" and tap the "+" button to add a new service with details like name, price, duration, and category.',
    'manage availability': 'Go to Provider Dashboard > Availability to set your working hours, breaks, and exceptions.',
    'refund': 'Refunds are processed according to the cancellation policy. Free cancellation is available if cancelled more than 24 hours in advance.',
    'cancellation policy': 'You can cancel for free if done more than 24 hours before the appointment. Late cancellations may incur a fee based on the provider\'s policy.',
    'review': 'After completing an appointment, go to "My Appointments", find the completed appointment, and tap "Review" to rate and comment.',
    'contact support': 'You can email us at ${AppConfig.supportEmail} or use this chat for instant help.',
    'privacy': 'Your data is secure and encrypted. We never share your personal information. View our Privacy Policy in Settings > Help & Support.',
    'security': 'We use industry-standard encryption and secure payment processing. Your data is protected.',
  };

  /// Get response from chatbot
  /// First checks FAQ database, then falls back to AI if needed
  static Future<String> getResponse(String userMessage, {String? apiKey}) async {
    try {
      // Normalize user message for FAQ matching
      final normalizedMessage = userMessage.toLowerCase().trim();
      
      // Check FAQ database first (fast, free)
      for (final entry in _faqDatabase.entries) {
        if (normalizedMessage.contains(entry.key)) {
          debugPrint('🤖 FAQ Match: ${entry.key}');
          return entry.value;
        }
      }
      
      // If no FAQ match and API key provided, use AI
      if (apiKey != null && apiKey.isNotEmpty) {
        return await _getAIResponse(userMessage, apiKey);
      }
      
      // Fallback response if no API key
      return _getFallbackResponse(userMessage);
    } catch (e) {
      debugPrint('❌ Chatbot error: $e');
      return 'I apologize, but I encountered an error. Please try rephrasing your question or contact support at ${AppConfig.supportEmail}';
    }
  }

  /// Get AI-powered response from OpenAI
  static Future<String> _getAIResponse(String userMessage, String apiKey) async {
    try {
      final response = await http.post(
        Uri.parse(_openAiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo', // or 'gpt-4' for better quality
          'messages': [
            {
              'role': 'system',
              'content': '''You are a helpful assistant for Bookly, an appointment booking app. 
              Help users with questions about booking appointments, managing their account, payments, 
              cancellations, and general app usage. Be friendly, concise, and helpful. 
              If you don't know something, suggest they contact support at ${AppConfig.supportEmail}.'''
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'] as String;
        debugPrint('🤖 AI Response received');
        return aiResponse.trim();
      } else {
        debugPrint('❌ OpenAI API error: ${response.statusCode}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      debugPrint('❌ AI API error: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  /// Fallback response when AI is unavailable
  static String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('book') || lowerMessage.contains('appointment')) {
      return 'To book an appointment, go to the dashboard and tap "Book Appointment". Need more help? Contact us at ${AppConfig.supportEmail}';
    } else if (lowerMessage.contains('cancel') || lowerMessage.contains('reschedule')) {
      return 'You can manage appointments in "My Appointments". For specific help, email us at ${AppConfig.supportEmail}';
    } else if (lowerMessage.contains('payment') || lowerMessage.contains('pay')) {
      return 'Payments are processed securely through Stripe. For payment issues, contact support at ${AppConfig.supportEmail}';
    } else {
      return 'I\'m here to help! For specific questions, please contact our support team at ${AppConfig.supportEmail} or check the FAQ section in Help & Support.';
    }
  }

  /// Get suggested questions for quick access
  static List<String> getSuggestedQuestions() {
    return [
      'How do I book an appointment?',
      'How do I cancel an appointment?',
      'How do I pay for an appointment?',
      'Can I reschedule my appointment?',
      'How do I leave a review?',
      'What is your cancellation policy?',
    ];
  }

  /// Check if message matches FAQ
  static bool isFAQMatch(String message) {
    final normalized = message.toLowerCase();
    return _faqDatabase.keys.any((key) => normalized.contains(key));
  }
}
