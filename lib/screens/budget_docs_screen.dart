import 'package:flutter/material.dart';

class BudgetAndDocsScreen extends StatelessWidget {
  const BudgetAndDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos & Presupuesto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
            title: Text('Pasajes de Vuelo Iberia.pdf'),
            subtitle: Text('Confirmación de reserva y tiquetes'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.description_rounded, color: Colors.blue),
            title: Text('Contrato Alquiler Motorhome.pdf'),
            subtitle: Text('Indie Campers Malpensa'),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.verified_user_rounded, color: Colors.green),
            title: Text('Seguro Médico Internacional.pdf'),
            subtitle: Text('Póliza de viaje válida en Europa'),
          ),
        ],
      ),
    );
  }
}