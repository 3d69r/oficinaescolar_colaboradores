import 'package:flutter/material.dart';

// Asegúrate de importar tu modelo de Boleta Encabezado
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 

class PreparatoriaCalificacionesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  // Claves de solo lectura (Promedio)
  final List<String> readonlyKeys; 
  
  // Color distintivo para Preparatoria (ej. Naranja)
  final Color headerColor = Colors.orange.shade800; 

   PreparatoriaCalificacionesWidget({
    super.key,
    required this.alumnos,
    required this.estructura,
    required this.buildGradeCell,
    required this.readonlyKeys, 
  });
  
  static const double GRADE_CELL_WIDTH = 120.0;
  static const double NAME_CELL_WIDTH = 300.0;


  @override
  Widget build(BuildContext context) {
    if (alumnos.isEmpty) {
      return const Center(
        child: Text('No se encontraron alumnos asignados a este curso.'),
      );
    }

    final List<Map<String, dynamic>> headers = _getDynamicHeaders();
    final List<String> allSubHeaderKeys = headers.expand((h) => h['subHeaders'] as List<String>).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.0),
        ),
        child: Column(
          children: [
            // Cabecera
            _buildHeaderRow(headers),
            
            // Filas de Alumnos
            ...List.generate(alumnos.length, (index) {
              final alumno = alumnos[index];
              return _buildAlumnoRow(alumno, allSubHeaderKeys, index.isEven);
            }),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE ENCABEZADOS DINÁMICOS PARA PREPARATORIA ---

  List<Map<String, dynamic>> _getDynamicHeaders() {
    final List<Map<String, dynamic>> headers = [];
    
    // 1. Procesar Encabezados de Periodo (P1, P2, P3) con Sub-Relaciones
    // La clave 'encabezados' debe contener todos los títulos (P1, P2, P3, Promedio, etc.)
    estructura.encabezados.forEach((key, value) {
      
      // Asumimos que los encabezados que tienen una 'relación' asociada son anidados
      final String? relationString = estructura.relaciones[key]; 

      if (relationString != null && relationString.isNotEmpty) {
         // Encabezado ANIDADO (Ej: P1 -> parcial_1)
        final List<String> subHeaders = relationString
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => s.trim())
            .toList();

        headers.add({
          'header': value, 
          'subHeaders': subHeaders, 
        });
      } else {
        // Encabezado SIMPLE (Ej: Promedio, Evaluación Ordinaria)
        // Usaremos el 'key' (ej. 'P4', 'EO') como su propia sub-clave de dato.
         headers.add({
          'header': value, // Ej: Promedio
          'subHeaders': [key], // Ej: [P4] si 'P4' es la clave de dato del promedio
        });
      }
    });

    // 2. Comentarios/Observaciones (Si existen por separado)
    if (estructura.comentarios.isNotEmpty) {
      final String commentKey = estructura.comentarios.keys.first;
      final String commentValue = estructura.comentarios.values.first;
        
      headers.add({
        'header': commentValue, 
        'subHeaders': [commentKey], 
      });
    }
    
    return headers;
  }
  
  // --- CONSTRUCCIÓN DE LA CABECERA ---
  
  Widget _buildHeaderRow(List<Map<String, dynamic>> headers) {
    final double headerHeight = 50.0;
    
    // Determinamos si todos los encabezados son simples para ajustar la altura de la columna ALUMNO
    final bool allSimple = headers.every((h) => (h['subHeaders'] as List).length <= 1);
    final double alumnoHeaderHeight = allSimple ? headerHeight : headerHeight * 2;

    return IntrinsicHeight(
      child: Row(
        children: [
          // Celda fija para el Nombre del Alumno
          _buildHeaderCell('ALUMNO', width: NAME_CELL_WIDTH, height: alumnoHeaderHeight, color: headerColor),

          // Encabezados Dinámicos
          ...headers.map((header) {
            final subHeaders = header['subHeaders'] as List<String>;
            
            // Si tiene más de un sub-encabezado o el encabezado del alumno es doble, anidamos
            if (subHeaders.length > 1 || !allSimple) {
              return Column(
                children: [
                  // Encabezado Principal (Ej: P1, PROMEDIO)
                  _buildHeaderCell(
                    header['header'].toString().toUpperCase(), 
                    width: subHeaders.length * GRADE_CELL_WIDTH, 
                    height: headerHeight, 
                    color: headerColor,
                  ),
                  // Sub-Encabezado (Ej: PARCIAL 1, CALIFICACIÓN FINAL)
                  Row(
                    children: subHeaders.map((subHeaderKey) {
                      final String displayText = subHeaderKey.replaceAll('_', ' ').toUpperCase();
                      
                      final Color subHeaderColor = readonlyKeys.contains(subHeaderKey) 
                          ? Colors.black.withOpacity(0.9) 
                          : headerColor.withOpacity(0.8);

                      return _buildHeaderCell(
                        displayText, 
                        width: GRADE_CELL_WIDTH, 
                        height: headerHeight, 
                        color: subHeaderColor,
                      );
                    }).toList(),
                  ),
                ],
              );
            } else {
              // Si es un encabezado simple (solo un sub-encabezado), lo mostramos en una sola fila
               final String subHeaderKey = subHeaders.first;
               subHeaderKey.replaceAll('_', ' ').toUpperCase();
               
               // Usamos la altura completa para el encabezado simple
               final Color subHeaderColor = readonlyKeys.contains(subHeaderKey) 
                   ? Colors.black.withOpacity(0.9) 
                   : headerColor;

              return _buildHeaderCell(
                header['header'].toString().toUpperCase(), 
                width: GRADE_CELL_WIDTH, 
                height: alumnoHeaderHeight, 
                color: subHeaderColor,
              );
            }
          }).toList(),
        ],
      ),
    );
  }


  // --- CONSTRUCCIÓN DE LAS FILAS DE DATOS ---

  Widget _buildAlumnoRow(
    Map<String, dynamic> alumno, 
    List<String> allSubHeaderKeys, 
    bool isEven,
  ) {
    final Color rowColor = isEven ? Colors.grey.shade200 : Colors.white;
    final String alumnoId = alumno['id_alumno'] as String? ?? '';

    final String primerNombre = alumno['primer_nombre'] as String? ?? '';
    final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
    final String nombreCompleto = '$primerNombre $apellidoPat'.trim().replaceAll(RegExp(r'\s+'), ' '); 

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Celda del Nombre del Alumno
          Container(
            width: NAME_CELL_WIDTH,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: rowColor,
              border: Border.all(color: Colors.black, width: 1.0),
            ),
            child: Text(
              nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          
          // 2. Celdas de Calificación Dinámicas (Editable o Solo Lectura)
          ...allSubHeaderKeys.map((key) {
            
            if (readonlyKeys.contains(key)) {
              // Si es Promedio/Campo Calculado: Celda de SOLO LECTURA
              final String calculatedValue = alumno[key]?.toString() ?? '-';
              return _buildReadonlyCell(calculatedValue, GRADE_CELL_WIDTH, rowColor);
            } else {
              // Si es Parcial/Campo Editable: Celda EDITABLE
              return _buildGradeCellAsContainer(buildGradeCell(alumnoId, key), GRADE_CELL_WIDTH, rowColor);
            }
          }).toList(),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES (Reusados de los widgets anteriores) ---

  Widget _buildGradeCellAsContainer(DataCell dataCell, double width, Color color) {
    final Widget cellContent = dataCell.child; 
    
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 50.0),
      padding: EdgeInsets.zero, 
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        color: color,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: cellContent, 
      ),
    );
  }

  Widget _buildReadonlyCell(String value, double width, Color color) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 50.0),
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.0),
        color: color.withOpacity(0.8),
      ),
      child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ),
    );
  }
  
  Widget _buildHeaderCell(String text, {required double width, required double height, required Color color}) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.0),
          color: color,
        ),
        padding: const EdgeInsets.all(6.0),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}