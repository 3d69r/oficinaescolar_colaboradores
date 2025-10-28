// pdf_viewer_screen.dart

import 'package:flutter/material.dart';
// Asegúrate de tener esta dependencia en tu pubspec.yaml
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; 

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String url;
  
  // ⭐️ Campo para recibir el objeto de colores (asumiendo que tiene .headerColor) ⭐️
  final dynamic colores; // Usa el tipo exacto (e.g., ColoresModel) si lo tienes

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.url,
    required this.colores, // Agregado al constructor
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          // 🛑 Usa el título formateado que se le pasa (ej: "Archivo 1")
          title, 
          style: const TextStyle(color: Colors.white), // Texto blanco para contraste
        ),
        // ⭐️ CAMBIO CLAVE: Usar el color del objeto colores.headerColor ⭐️
        foregroundColor: Colors.white,
        backgroundColor: colores.headerColor, 
        // Añadir elevación 0 y centrar el título es opcional, pero mejora la apariencia
        elevation: 0,
        centerTitle: true,
      ),
      body: SfPdfViewer.network(
        // Carga el PDF directamente desde la URL de la red
        url,
      ),
    );
  }
}