import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/trip_models.dart';
import '../data/sample_trip.dart';
import '../utils/category_helpers.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen> {
  final MapController _mapController = MapController();
  int? _selectedFilterDay; // null = Todos los días
  final Set<String> _disabledActivityIds = {};
  
  final Map<CategoryType, bool> _enabledCategories = {
    CategoryType.lodging: true,
    CategoryType.flight: true,
    CategoryType.transport: true,
    CategoryType.culture: true,
    CategoryType.dining: true,
    CategoryType.shopping: true,
    CategoryType.other: true,
  };

  List<Polyline> _roadTripPolylines = [];
  bool _isLoadingRoutes = false;

  @override
  void initState() {
    super.initState();
    _calculateOsrmRoutes();
  }

  // Consulta la ruta vial exacta de auto por carretera (Google Maps / OSRM)
  Future<void> _calculateOsrmRoutes() async {
    setState(() => _isLoadingRoutes = true);
    List<Polyline> fetchedPolylines = [];

    for (var day in sampleTripData) {
      if (_selectedFilterDay != null && day.dayNumber != _selectedFilterDay) continue;

      for (var act in day.activities) {
        if (_disabledActivityIds.contains(act.id)) continue;
        if (_enabledCategories[act.category] == false) continue;

        if (act.category == CategoryType.transport &&
            act.origin != null &&
            act.destination != null) {
          try {
            final url = Uri.parse(
              'https://router.project-osrm.org/route/v1/driving/'
              '${act.origin!.longitude},${act.origin!.latitude};'
              '${act.destination!.longitude},${act.destination!.latitude}'
              '?overview=full&geometries=geojson',
            );

            final response = await http.get(url).timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
                final coords = data['routes'][0]['geometry']['coordinates'] as List;
                List<LatLng> routePoints = coords
                    .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
                    .toList();

                fetchedPolylines.add(
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4.5,
                    color: const Color(0xFFEAB308),
                  ),
                );
              }
            }
          } catch (_) {
            // Fallback en línea recta discontinua si no hay conexión a la API OSRM
            fetchedPolylines.add(
              Polyline(
                points: [act.origin!, act.destination!],
                strokeWidth: 3.0,
                color: const Color(0xFFEAB308),
                isDotted: true,
              ),
            );
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _roadTripPolylines = fetchedPolylines;
        _isLoadingRoutes = false;
      });
    }
  }

  void _openGoogleMapsRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtener actividades filtradas
    List<MapEntry<int, ActivityItem>> allFilteredActivities = [];
    for (var day in sampleTripData) {
      if (_selectedFilterDay == null || day.dayNumber == _selectedFilterDay) {
        for (var act in day.activities) {
          if (_enabledCategories[act.category] == true) {
            allFilteredActivities.add(MapEntry(day.dayNumber, act));
          }
        }
      }
    }

    // Generar marcadores numerados para el mapa
    List<Marker> markers = [];
    int pinCounter = 1;

    for (var entry in allFilteredActivities) {
      final currentPinNumber = pinCounter++;
      final act = entry.value;
      final isHidden = _disabledActivityIds.contains(act.id);
      final loc = act.location ?? act.origin;

      if (loc != null && !isHidden) {
        final color = getCategoryColor(act.category);
        markers.add(
          Marker(
            point: loc,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                _showActivityDetailsDialog(context, act, currentPinNumber, entry.key);
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

    final activeCount = allFilteredActivities.where((e) => !_disabledActivityIds.contains(e.value.id)).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mapa Interactivo del Viaje', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtro Superior por Día
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Ver Todo'),
                      selected: _selectedFilterDay == null,
                      onSelected: (_) {
                        setState(() => _selectedFilterDay = null);
                        _calculateOsrmRoutes();
                      },
                      selectedColor: const Color(0xFFEEF2FF),
                      labelStyle: TextStyle(
                        color: _selectedFilterDay == null ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...sampleTripData.map(
                      (day) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text('Día ${day.dayNumber}'),
                          selected: _selectedFilterDay == day.dayNumber,
                          onSelected: (_) {
                            setState(() => _selectedFilterDay = day.dayNumber);
                            _calculateOsrmRoutes();
                          },
                          selectedColor: const Color(0xFFEEF2FF),
                          labelStyle: TextStyle(
                            color: _selectedFilterDay == day.dayNumber ? const Color(0xFF4F46E5) : const Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mapa Interactivo
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
                      PolylineLayer(polylines: _roadTripPolylines),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                  if (_isLoadingRoutes)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Calculando Ruta Auto...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Lista de Paradas e Interactividad
            Expanded(
              flex: 4,
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Cabecera del Listado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paradas en el Mapa ($activeCount / ${allFilteredActivities.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() => _disabledActivityIds.clear());
                                  _calculateOsrmRoutes();
                                },
                                child: const Text('Seleccionar Todas', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _disabledActivityIds.addAll(allFilteredActivities.map((e) => e.value.id));
                                  });
                                  _calculateOsrmRoutes();
                                },
                                child: const Text('Deseleccionar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lista de Elementos
                    Expanded(
                      child: allFilteredActivities.isEmpty
                          ? const Center(child: Text('No hay actividades con los filtros actuales.'))
                          : ListView.builder(
                              itemCount: allFilteredActivities.length,
                              itemBuilder: (context, index) {
                                final dayNum = allFilteredActivities[index].key;
                                final act = allFilteredActivities[index].value;
                                final isHidden = _disabledActivityIds.contains(act.id);
                                final pinNumber = index + 1;
                                final color = getCategoryColor(act.category);
                                final icon = getCategoryIcon(act.category);

                                return Container(
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    leading: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Checkbox(
                                          value: !isHidden,
                                          activeColor: const Color(0xFF4F46E5),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _disabledActivityIds.remove(act.id);
                                              } else {
                                                _disabledActivityIds.add(act.id);
                                              }
                                            });
                                            _calculateOsrmRoutes();
                                          },
                                        ),
                                        CircleAvatar(
                                          radius: 11,
                                          backgroundColor: color,
                                          child: Text(
                                            '$pinNumber',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    title: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('D$dayNum', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '$icon ${act.title}',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              decoration: isHidden ? TextDecoration.lineThrough : null,
                                              color: isHidden ? Colors.grey : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${act.timeStart} - ${act.timeEnd} • ${act.locationName ?? act.originName ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    trailing: (act.category == CategoryType.transport && act.origin != null && act.destination != null)
                                        ? IconButton(
                                            icon: const Icon(Icons.directions_car_rounded, color: Color(0xFFD97706), size: 20),
                                            onPressed: () => _openGoogleMapsRoute(act.origin!, act.destination!),
                                            tooltip: 'Ver Ruta en Google Maps',
                                          )
                                        : null,
                                    onTap: () {
                                      final target = act.location ?? act.origin;
                                      if (target != null) {
                                        _mapController.move(target, 13.5);
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
      ),
    );
  }

  void _showActivityDetailsDialog(BuildContext context, ActivityItem act, int pinNumber, int dayNum) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: getCategoryColor(act.category),
              child: Text('$pinNumber', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(act.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Horario: ${act.timeStart} - ${act.timeEnd} (Día $dayNum)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            if (act.locationName != null) ...[
              const SizedBox(height: 6),
              Text('Ubicación: ${act.locationName}', style: const TextStyle(fontSize: 12)),
            ],
            if (act.address != null) ...[
              const SizedBox(height: 4),
              Text('Dirección: ${act.address}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
            if (act.notes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                child: Text('Notas: ${act.notes}', style: const TextStyle(fontSize: 11)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}