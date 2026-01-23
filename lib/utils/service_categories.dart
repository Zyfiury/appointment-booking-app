import 'package:flutter/material.dart';

class ServiceCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<String> subcategories;

  const ServiceCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.subcategories,
  });
}

class ServiceCategories {
  // 2-level category structure with subcategories
  static const Map<String, ServiceCategory> categories = {
    'Barber': ServiceCategory(
      name: 'Barber',
      icon: Icons.content_cut,
      color: Color(0xFF06C167), // Green
      subcategories: [
        'Haircut',
        'Skin Fade',
        'Beard Trim',
        'Line-up',
        'Buzz Cut',
        'Taper',
        'Shave',
      ],
    ),
    'Hair Salon': ServiceCategory(
      name: 'Hair Salon',
      icon: Icons.face,
      color: Color(0xFF7B68EE), // Purple
      subcategories: [
        'Haircut',
        'Color',
        'Highlights',
        'Perm',
        'Extensions',
        'Treatment',
        'Styling',
      ],
    ),
    'Beauty': ServiceCategory(
      name: 'Beauty',
      icon: Icons.spa,
      color: Color(0xFFFFB800), // Yellow
      subcategories: [
        'Nails',
        'Lashes',
        'Brows',
        'Facial',
        'Makeup',
        'Waxing',
        'Threading',
      ],
    ),
    'Massage': ServiceCategory(
      name: 'Massage',
      icon: Icons.hot_tub,
      color: Color(0xFF14B8A6), // Teal
      subcategories: [
        'Deep Tissue',
        'Sports',
        'Swedish',
        'Thai',
        'Hot Stone',
        'Prenatal',
        'Reflexology',
      ],
    ),
    'Fitness': ServiceCategory(
      name: 'Fitness',
      icon: Icons.fitness_center,
      color: Color(0xFF2563EB), // Blue
      subcategories: [
        'Personal Training',
        'Yoga',
        'Pilates',
        'Nutrition',
        'Group Class',
        'Consultation',
      ],
    ),
    'Medical': ServiceCategory(
      name: 'Medical',
      icon: Icons.medical_services,
      color: Color(0xFFE63946), // Red
      subcategories: [
        'General Checkup',
        'Consultation',
        'Vaccination',
        'Lab Test',
        'Follow-up',
      ],
    ),
    'Dermatology': ServiceCategory(
      name: 'Dermatology',
      icon: Icons.healing,
      color: Color(0xFFFF6B35), // Orange
      subcategories: [
        'Acne Treatment',
        'Skin Analysis',
        'Mole Check',
        'Laser Treatment',
        'Chemical Peel',
      ],
    ),
    'Dental': ServiceCategory(
      name: 'Dental',
      icon: Icons.medical_services_outlined,
      color: Color(0xFF06B6D4), // Cyan
      subcategories: [
        'Cleaning',
        'Teeth Whitening',
        'Filling',
        'Root Canal',
        'Checkup',
        'Orthodontics',
      ],
    ),
    'Therapy': ServiceCategory(
      name: 'Therapy',
      icon: Icons.psychology,
      color: Color(0xFF9333EA), // Purple
      subcategories: [
        'Individual',
        'Couples',
        'Group',
        'Consultation',
        'Assessment',
      ],
    ),
    'Other': ServiceCategory(
      name: 'Other',
      icon: Icons.more_horiz,
      color: Color(0xFF6B7280), // Gray
      subcategories: [],
    ),
  };

  static ServiceCategory getCategory(String categoryName) {
    return categories[categoryName] ?? categories['Other']!;
  }

  static List<String> getAllCategoryNames() {
    return categories.keys.toList();
  }

  static List<String> getSubcategories(String categoryName) {
    return categories[categoryName]?.subcategories ?? [];
  }

  static bool isKnownCategory(String categoryName) {
    return categories.containsKey(categoryName);
  }

  static String? findCategoryForSubcategory(String subcategory) {
    for (var entry in categories.entries) {
      if (entry.value.subcategories.contains(subcategory)) {
        return entry.key;
      }
    }
    return null;
  }
}
