import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
// Asegúrate de importar tu modelo de Boleta Encabezado
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 

class UniversidadCalificacionesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  // Para universidad, asumimos que no hay claves de solo lectura por defecto,
  // pero mantenemos la propiedad por consistencia.
  final List<String> readonlyKeys; 
  
   const UniversidadCalificacionesWidget({ 
    super.key,
    required this.alumnos,
    required this.estructura,
    required this.buildGradeCell,
    required this.readonlyKeys, 
  });
  
  // Ajustamos el ancho para los nombres ya que las columnas de calificación son pocas
  static const double GRADE_CELL_WIDTH = 150.0;
  static const double NAME_CELL_WIDTH = 280.0;


  @override
  Widget build(BuildContext context) {
    // ACCESO AL COLOR DINÁMICO
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;
    
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
            _buildHeaderRow(headers, dynamicHeaderColor),
            
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

  // --- LÓGICA DE ENCABEZADOS DINÁMICOS ---

  List<Map<String, dynamic>> _getDynamicHeaders() {
    final List<Map<String, dynamic>> headers = [];
    
    // 1. Encabezados principales
    estructura.encabezados.forEach((nombreHeader, claveRelacion) { 
      
      final String relationString = estructura.relaciones[claveRelacion] ?? nombreHeader; 
      
      final List<String> subHeaders = relationString
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => s.trim())
          .toList();

      if (subHeaders.isNotEmpty) {
          headers.add({
            'header': nombreHeader, // Ej: Calificación Final
            'subHeaders': subHeaders, // Ej: [calificacion_final, evalua_observaciones]
          });
      }
    });

    // 2. Comentarios/Observaciones
    if (estructura.comentarios.isNotEmpty) {
      final String commentKey = estructura.comentarios.keys.first;
      final String commentValue = estructura.comentarios.values.first;
        
      if (!headers.any((h) => (h['subHeaders'] as List<String>).contains(commentKey))) {
          headers.add({
            'header': commentValue, 
            'subHeaders': [commentKey], 
          });
      }
    }
    
    return headers;
  }
  
  // --- CONSTRUCCIÓN DE LA CABECERA ---
  
  Widget _buildHeaderRow(List<Map<String, dynamic>> headers, Color headerColor) {
    // Si solo hay un encabezado (ej. "Calificación") pero con MÚLTIPLES subHeaders, la altura del encabezado del alumno debe ser 2x.
    final bool needsDoubleHeight = headers.length == 1 && (headers.first['subHeaders'] as List<String>).length > 1;
    final double headerHeight = 50.0;
    
    return IntrinsicHeight(
      child: Row(
        children: [
          // Celda fija para el Nombre del Alumno
          _buildHeaderCell(
            'ALUMNO', 
            width: NAME_CELL_WIDTH, 
            height: needsDoubleHeight ? headerHeight * 2 : headerHeight, 
            color: headerColor 
          ),

          // Encabezados Dinámicos
          ...headers.map((header) {
            final subHeaders = header['subHeaders'] as List<String>;
            
            // Caso simple (no anidado)
            if (subHeaders.length == 1 && !needsDoubleHeight) {
                final String displayText = subHeaders.first.replaceAll('_', ' ').toUpperCase();
                return _buildHeaderCell(
                    displayText, 
                    width: GRADE_CELL_WIDTH, 
                    height: headerHeight, 
                    color: headerColor, 
                );
            }

            // Caso anidado (Licenciatura con calificacion_final y evalua_observaciones)
            return Column(
              children: [
                // Encabezado Principal (Ej: CALIFICACIÓN)
                _buildHeaderCell(
                  header['header'].toString().toUpperCase(), 
                  width: subHeaders.length * GRADE_CELL_WIDTH, 
                  height: headerHeight, 
                  color: headerColor, 
                ),
                // Sub-Encabezado (Ej: CALIFICACIÓN FINAL, EVALÚA OBSERVACIONES)
                Row(
                  children: subHeaders.map((subHeaderKey) {
                    final String displayText = subHeaderKey
                        .replaceAll('_', ' ')
                        .toUpperCase();
                    
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
          }).toList(),
        ],
      ),
    );
  }


  // --- CONSTRUCCIÓN DE LAS FILAS DE DATOS (CORREGIDO PARA HACER AMBOS EDITABLES) ---

  Widget _buildAlumnoRow(
    Map<String, dynamic> alumno, 
    List<String> allSubHeaderKeys, 
    bool isEven,
  ) {
    final Color rowColor = isEven ? Colors.grey.shade200 : Colors.white;
    final String alumnoId = alumno['id_alumno'] as String? ?? '';
    final String primerNombre = alumno['primer_nombre'] as String? ?? '';
    final String segundoNombre = alumno['segundo_nombre'] as String? ?? '';
    final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
    final String apellidoMat = alumno['apellido_mat'] as String? ?? '';
    final String nombreCompleto = '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.trim().replaceAll(RegExp(r'\s+'), ' '); 

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
          
          // 2. Celdas de Calificación Dinámicas
          ...allSubHeaderKeys.map((key) {
            
            // ⭐️ LÓGICA CLAVE: La columna es de solo lectura SOLAMENTE si está en la lista 'readonlyKeys'. ⭐️
            // Si la lista 'readonlyKeys' está vacía o no contiene 'calificacion_final' ni 'evalua_observaciones',
            // ambas columnas serán editables.
            final bool isReadonly = readonlyKeys.contains(key);
            
            if (isReadonly) {
              // Campo de solo lectura
              final String calculatedValue = alumno[key]?.toString() ?? '-';
              return _buildReadonlyCell(calculatedValue, GRADE_CELL_WIDTH, rowColor);
            } else {
              // Campo editable (Debe ser calificacion_final y evalua_observaciones)
              return _buildGradeCellAsContainer(buildGradeCell(alumnoId, key), GRADE_CELL_WIDTH, rowColor);
            }
          }).toList(),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES (Sin cambios) ---

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