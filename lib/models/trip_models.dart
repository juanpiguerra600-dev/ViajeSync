import 'package:latlong2/latlong.dart';

enum CategoryType {
  lodging,
  flight,
  transport,
  culture,
  dining,
  shopping,
  other,
}

class ActivityItem {
  final String id;
  final String title;
  final String timeStart;
  final String timeEnd;
  final CategoryType category;
  final String? locationName;
  final String? address;
  final LatLng? location;
  final LatLng? origin;
  final LatLng? destination;
  final String? originName;
  final String? destinationName;
  final String? notes;
  final double? cost;

  ActivityItem({
    required this.id,
    required this.title,
    required this.timeStart,
    required this.timeEnd,
    required this.category,
    this.locationName,
    this.address,
    this.location,
    this.origin,
    this.destination,
    this.originName,
    this.destinationName,
    this.notes,
    this.cost,
  });
}

class DayItinerary {
  final int dayNumber;
  final String dateTitle;
  final List<ActivityItem> activities;

  DayItinerary({
    required this.dayNumber,
    required this.dateTitle,
    required this.activities,
  });
}