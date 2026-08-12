import 'package:flutter/material.dart';

class AudioGuideScreen extends StatelessWidget {
  const AudioGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audioguías & Tours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.headphones_rounded, size: 56, color: Color(0xFF4F46E5)),
              SizedBox(height: 12),
              Text('Audioguías Disponibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 6),
              Text(
                'Aquí se cargarán las audioguías descargables y relatos turísticos del viaje.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}