import 'package:flutter/material.dart';

/// Comprehensive input validators for the app
class Validators {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Password validation with strength check
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  /// Simple password validation (for less strict cases)
  static String? simplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Phone number validation
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove common formatting characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Phone number must contain only digits';
    }
    
    // Check length (10-15 digits is reasonable)
    if (cleaned.length < 10 || cleaned.length > 15) {
      return 'Phone number must be between 10 and 15 digits';
    }
    
    return null;
  }

  /// Name validation
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Required field validation
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Price validation
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    final priceValue = double.tryParse(value);
    if (priceValue == null) {
      return 'Please enter a valid number';
    }
    
    if (priceValue < 0) {
      return 'Price cannot be negative';
    }
    
    if (priceValue > 100000) {
      return 'Price seems too high. Please verify.';
    }
    
    return null;
  }

  /// Duration validation
  static String? duration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
    }
    
    final durationValue = int.tryParse(value);
    if (durationValue == null) {
      return 'Please enter a valid number';
    }
    
    if (durationValue < 15) {
      return 'Duration must be at least 15 minutes';
    }
    
    if (durationValue > 480) {
      return 'Duration cannot exceed 8 hours (480 minutes)';
    }
    
    if (durationValue % 15 != 0) {
      return 'Duration must be in 15-minute increments';
    }
    
    return null;
  }

  /// Date validation (not in past)
  static String? futureDate(DateTime? value) {
    if (value == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(value.year, value.month, value.day);
    
    if (selected.isBefore(today)) {
      return 'Cannot select a date in the past';
    }
    
    // Check if date is too far in future (1 year limit)
    final maxDate = today.add(const Duration(days: 365));
    if (selected.isAfter(maxDate)) {
      return 'Cannot book more than 1 year in advance';
    }
    
    return null;
  }

  /// Time slot validation
  static String? timeSlot(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time slot is required';
    }
    
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return 'Invalid time format';
    }
    
    return null;
  }

  /// Description validation
  static String? description(String? value, {int minLength = 10, int maxLength = 500}) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    if (value.length < minLength) {
      return 'Description must be at least $minLength characters';
    }
    
    if (value.length > maxLength) {
      return 'Description must be less than $maxLength characters';
    }
    
    return null;
  }

  /// Capacity validation
  static String? capacity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Capacity is required';
    }
    
    final capacityValue = int.tryParse(value);
    if (capacityValue == null) {
      return 'Please enter a valid number';
    }
    
    if (capacityValue < 1) {
      return 'Capacity must be at least 1';
    }
    
    if (capacityValue > 100) {
      return 'Capacity cannot exceed 100';
    }
    
    return null;
  }

  /// URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL (starting with http:// or https://)';
    }
    
    return null;
  }

  /// Password match validation
  static String? passwordMatch(String? value, String? otherPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != otherPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}
