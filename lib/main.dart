import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ViajeSyncApp());
}

class ViajeSyncApp extends StatelessWidget {
  const ViajeSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Itinerario de Viaje',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          surface: const Color(0xFFF8FAFC),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const ItineraryMapScreen(),
    );
  }
}

enum ActivityType { lodging, flight, transport, dining, shopping, culture, other }

class ActivityItem {
  final String id;
  final String title;
  final String timeStart;
  final String timeEnd;
  final ActivityType type;
  final String? locationName;
  final LatLng? location;
  final LatLng? origin;
  final LatLng? destination;
  final String? originName;
  final String? destinationName;

  ActivityItem({
    required this.id,
    required this.title,
    required this.timeStart,
    required this.timeEnd,
    required this.type,
    this.locationName,
    this.location,
    this.origin,
    this.destination,
    this.originName,
    this.destinationName,
  });
}

class DayItinerary {
  final int dayNumber;
  final String dateStr;
  final List<ActivityItem> activities;

  DayItinerary({
    required this.dayNumber,
    required this.dateStr,
    required this.activities,
  });
}

class ItineraryMapScreen extends StatefulWidget {
  const ItineraryMapScreen({super.key});

  @override
  State<ItineraryMapScreen> createState() => _ItineraryMapScreenState();
}

class _ItineraryMapScreenState extends State<ItineraryMapScreen> {
  final MapController _mapController = MapController();
  int? selectedDay; // null = Ver Todo
  final Set<String> _disabledActivityIds = {};
  List<Polyline> _routePolylines = [];
  bool _isLoadingRoutes = false;

  // Ejemplo de itinerario integrado
  final List<DayItinerary> _itinerary = [
    DayItinerary(
      dayNumber: 1,
      dateStr: 'Día 1 - Milán',
      activities: [
        ActivityItem(
          id: 'a1',
          title: 'Vuelo IB0671 MAD - Milán',
          timeStart: '07:30',
          timeEnd: '09:40',
          type: ActivityType.flight,
          locationName: 'Aeropuerto Malpensa',
          location: const LatLng(45.6301, 8.7255),
        ),
        ActivityItem(
          id: 'a2',
          title: 'Retiro Motorhome',
          timeStart: '14:30',
          timeEnd: '18:00',
          type: ActivityType.other,
          locationName: 'Indie Campers Milan Malpensa',
          location: const LatLng(45.6210, 8.7180),
        ),
        ActivityItem(
          id: 'a3',
          title: 'Viaje a Camping Agriturismo',
          timeStart: '18:00',
          timeEnd: '22:00',
          type: ActivityType.transport,
          originName: 'Indie Campers Milan',
          destinationName: 'Agriturismo Revena',
          origin: const LatLng(45.6210, 8.7180),
          destination: const LatLng(45.5480, 10.5420),
        ),
        ActivityItem(
          id: 'a4',
          title: 'Alojamiento en Agriturismo Revena',
          timeStart: '22:00',
          timeEnd: '23:59',
          type: ActivityType.lodging,
          locationName: 'Agriturismo Revena Camping',
          location: const LatLng(45.5480, 10.5420),
        ),
      ],
    )
  ];

  @override
  void initState() {
    super.initState();
    _fetchOsrmRoutes();
  }

  // Consulta la ruta de auto vía OSRM (Google Maps / OpenStreetMap Car driving)
  Future<void> _fetchOsrmRoutes() async {
    setState(() => _isLoadingRoutes = true);
    List<Polyline> newPolylines = [];

    for (var day in _itinerary) {
      if (selectedDay != null && day.dayNumber != selectedDay) continue;

      for (var act in day.activities) {
        if (_disabledActivityIds.contains(act.id)) continue;

        if ((act.type == ActivityType.transport) &&
            act.origin != null &&
            act.destination != null) {
          try {
            final url = Uri.parse(
                'https://router.project-osrm.org/route/v1/driving/'
                '${act.origin!.longitude},${act.origin!.latitude};'
                '${act.destination!.longitude},${act.destination!.latitude}'
                '?overview=full&geometries=geojson');

            final response = await http.get(url).timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              final coords = data['routes'][0]['geometry']['coordinates'] as List;
              List<LatLng> points = coords
                  .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                  .toList();

              newPolylines.add(
                Polyline(
                  points: points,
                  strokeWidth: 4.5,
                  color: Colors.amber.shade700,
                ),
              );
            }
          } catch (_) {
            // Línea recta de respaldo si OSRM no responde
            newPolylines.add(
              Polyline(
                points: [act.origin!, act.destination!],
                strokeWidth: 3.0,
                color: Colors.amber.shade600,
                isDotted: true,
              ),
            );
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _routePolylines = newPolylines;
        _isLoadingRoutes = false;
      });
    }
  }

  Color _getCategoryColor(ActivityType type) {
    switch (type) {
      case ActivityType.lodging:
        return const Color(0xFF0284C7);
      case ActivityType.flight:
        return const Color(0xFFEC4899);
      case ActivityType.transport:
        return const Color(0xFFEAB308);
      case ActivityType.dining:
        return const Color(0xFF10B981);
      case ActivityType.shopping:
        return const Color(0xFFF43F5E);
      case ActivityType.culture:
        return const Color(0xFF8B5CF6);
      case ActivityType.other:
      default:
        return const Color(0xFF4F46E5);
    }
  }

  String _getCategoryIcon(ActivityType type) {
    switch (type) {
      case ActivityType.lodging:
        return '🏨';
      case ActivityType.flight:
        return '✈️';
      case ActivityType.transport:
        return '🚗';
      case ActivityType.dining:
        return '🍽️';
      case ActivityType.shopping:
        return '🛒';
      case ActivityType.culture:
        return '🏛️';
      case ActivityType.other:
      default:
        return '📍';
    }
  }

  void _openGoogleMapsRoute(LatLng origin, LatLng destination) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<ActivityItem> visibleActivities = [];
    for (var day in _itinerary) {
      if (selectedDay == null || day.dayNumber == selectedDay) {
        visibleActivities.addAll(day.activities);
      }
    }

    // Generar pins de mapa numerados coincidiendo exactamente con la lista
    List<Marker> mapMarkers = [];
    int pinCounter = 1;

    for (var act in visibleActivities) {
      final currentPinNumber = pinCounter++;
      final isHidden = _disabledActivityIds.contains(act.id);
      final location = act.location ?? act.origin;

      if (location != null && !isHidden) {
        final color = _getCategoryColor(act.type);
        mapMarkers.add(
          Marker(
            point: location,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('#$currentPinNumber - ${act.title}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: Center(
                  child: Text(
                    '$currentPinNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Interactivo del Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Filtros de Día
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Ver Todo'),
                  selected: selectedDay == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => selectedDay = null);
                      _fetchOsrmRoutes();
                    }
                  },
                ),
                const SizedBox(width: 8),
                ..._itinerary.map(
                  (day) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('Día ${day.dayNumber}'),
                      selected: selectedDay == day.dayNumber,
                      onSelected: (selected) {
                        setState(() => selectedDay = selected ? day.dayNumber : null);
                        _fetchOsrmRoutes();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mapa Interactivo Flutter Map
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(45.6000, 9.5000),
                    initialZoom: 8.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.viajesync.app',
                    ),
                    PolylineLayer(polylines: _routePolylines),
                    MarkerLayer(markers: mapMarkers),
                  ],
                ),
                if (_isLoadingRoutes)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 8),
                          Text('Calculando Ruta...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de Paradas y Actividades con Opciones de Selección
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actividades (${visibleActivities.length - _disabledActivityIds.length}/${visibleActivities.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() => _disabledActivityIds.clear());
                                _fetchOsrmRoutes();
                              },
                              child: const Text('Mostrar Todo', style: TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _disabledActivityIds.addAll(visibleActivities.map((a) => a.id));
                                });
                                _fetchOsrmRoutes();
                              },
                              child: const Text('Ocultar Todo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visibleActivities.length,
                      itemBuilder: (context, index) {
                        final act = visibleActivities[index];
                        final isHidden = _disabledActivityIds.contains(act.id);
                        final color = _getCategoryColor(act.type);
                        final icon = _getCategoryIcon(act.type);
                        final pinNumber = index + 1;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                            color: isHidden ? Colors.grey.shade50 : Colors.white,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: !isHidden,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        _disabledActivityIds.remove(act.id);
                                      } else {
                                        _disabledActivityIds.add(act.id);
                                      }
                                    });
                                    _fetchOsrmRoutes();
                                  },
                                ),
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: color,
                                  child: Text(
                                    '$pinNumber',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              '$icon ${act.title}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: isHidden ? TextDecoration.lineThrough : null,
                                color: isHidden ? Colors.grey : Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${act.timeStart} - ${act.timeEnd} • ${act.locationName ?? act.originName ?? ''}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: (act.type == ActivityType.transport && act.origin != null && act.destination != null)
                                ? IconButton(
                                    icon: const Icon(Icons.directions_car, color: Colors.amber, size: 20),
                                    onPressed: () => _openGoogleMapsRoute(act.origin!, act.destination!),
                                    tooltip: 'Ver Ruta en Google Maps',
                                  )
                                : null,
                            onTap: () {
                              final loc = act.location ?? act.origin;
                              if (loc != null) {
                                _mapController.move(loc, 14);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
