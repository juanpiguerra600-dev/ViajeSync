import 'package:flutter/material.dart';

import 'screens/interactive_map_screen.dart';
import 'screens/daily_itinerary_screen.dart';
import 'screens/audio_guide_screen.dart';
import 'screens/budget_docs_screen.dart';

void main() {
  runApp(const ViajeSyncApp());
}

class ViajeSyncApp extends StatelessWidget {
  const ViajeSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViajeSync Plan - Itinerario & Mapa',
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
      home: const MainTabNavigation(),
    );
  }
}

class MainTabNavigation extends StatefulWidget {
  const MainTabNavigation({super.key});

  @override
  State<MainTabNavigation> createState() => _MainTabNavigationState();
}

class _MainTabNavigationState extends State<MainTabNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    InteractiveMapScreen(),
    DailyItineraryScreen(),
    AudioGuideScreen(),
    BudgetAndDocsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4F46E5),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Mapa Interactivo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.view_day_rounded),
              label: 'Itinerario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.headphones_rounded),
              label: 'Audioguías',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_open_rounded),
              label: 'Documentos',
            ),
          ],
        ),
      ),
    );
  }
}