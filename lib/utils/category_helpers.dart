import 'package:flutter/material.dart';
import '../models/trip_models.dart';

Color getCategoryColor(CategoryType category) {
  switch (category) {
    case CategoryType.lodging:
      return const Color(0xFF0284C7);
    case CategoryType.flight:
      return const Color(0xFFEC4899);
    case CategoryType.transport:
      return const Color(0xFFEAB308);
    case CategoryType.culture:
      return const Color(0xFF8B5CF6);
    case CategoryType.dining:
      return const Color(0xFF10B981);
    case CategoryType.shopping:
      return const Color(0xFFF43F5E);
    case CategoryType.other:
    default:
      return const Color(0xFF4F46E5);
  }
}

String getCategoryIcon(CategoryType category) {
  switch (category) {
    case CategoryType.lodging:
      return '🏨';
    case CategoryType.flight:
      return '✈️';
    case CategoryType.transport:
      return '🚗';
    case CategoryType.culture:
      return '🏛️';
    case CategoryType.dining:
      return '🍽️';
    case CategoryType.shopping:
      return '🛒';
    case CategoryType.other:
    default:
      return '📍';
  }
}