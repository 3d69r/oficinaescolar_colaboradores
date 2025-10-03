import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importar Provider
// Asegúrate de importar tu modelo de Boleta Encabezado
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; // 2. Importar UserProvider

class UniversidadCalificacionesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  // Para universidad, asumimos que no hay claves de solo lectura por defecto,
  // pero mantenemos la propiedad por consistencia.
  final List<String> readonlyKeys; 
  
  // Eliminamos el color estático
  // final Color headerColor = Colors.grey.shade900; 

   const UniversidadCalificacionesWidget({ // Usamos const para el constructor
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
    // 3. ACCESO AL COLOR DINÁMICO
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
            // ⭐️ Pasar el color dinámico ⭐️
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

  // --- LÓGICA DE ENCABEZADOS DINÁMICOS (SIN CAMBIOS) ---

  List<Map<String, dynamic>> _getDynamicHeaders() {
    final List<Map<String, dynamic>> headers = [];
    
    // 1. Encabezados principales (Solo uno o dos para Licenciatura)
    estructura.encabezados.forEach((key, value) {
      
      // La clave 'relaciones' contendrá la cadena: "calificacion_final,evalua_observaciones"
      final String relationString = estructura.relaciones[key] ?? key; 
      
      final List<String> subHeaders = relationString
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => s.trim())
          .toList();

      headers.add({
        'header': value, // Ej: Calificación
        'subHeaders': subHeaders, // Ej: [calificacion_final, evalua_observaciones]
      });
    });

    // 2. Comentarios/Observaciones (Si existen por separado) - Usualmente vacío en este nivel
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
  
  // --- CONSTRUCCIÓN DE LA CABECERA (Modificamos la firma) ---
  
  Widget _buildHeaderRow(List<Map<String, dynamic>> headers, Color headerColor) {
    // Para simplificar la interfaz, si solo hay un encabezado principal, lo hacemos simple
    final bool isSimpleHeader = headers.length == 1 && headers.first['subHeaders'].length == 1;
    final double headerHeight = 50.0;
    
    return IntrinsicHeight(
      child: Row(
        children: [
          // Celda fija para el Nombre del Alumno
          _buildHeaderCell(
            'ALUMNO', 
            width: NAME_CELL_WIDTH, 
            // Si el encabezado es simple (solo un sub-encabezado), la altura es 1x
            height: isSimpleHeader ? headerHeight : headerHeight * 2, 
            color: headerColor // ⭐️ Color Dinámico ⭐️
          ),

          // Encabezados Dinámicos
          ...headers.map((header) {
            final subHeaders = header['subHeaders'] as List<String>;
            
            // Si es un encabezado simple, no anidamos en Column.
            if (isSimpleHeader) {
                final String displayText = subHeaders.first.replaceAll('_', ' ').toUpperCase();
                return _buildHeaderCell(
                    displayText, 
                    width: GRADE_CELL_WIDTH, 
                    height: headerHeight, 
                    color: headerColor, // ⭐️ Color Dinámico ⭐️
                );
            }

            // Si es un encabezado anidado (como 'Calificación' sobre dos sub-claves)
            return Column(
              children: [
                // Encabezado Principal (Ej: CALIFICACIÓN)
                _buildHeaderCell(
                  header['header'].toString().toUpperCase(), 
                  width: subHeaders.length * GRADE_CELL_WIDTH, 
                  height: headerHeight, 
                  color: headerColor, // ⭐️ Color Dinámico ⭐️
                ),
                // Sub-Encabezado (Ej: CALIFICACIÓN FINAL, EVALÚA OBSERVACIONES)
                Row(
                  children: subHeaders.map((subHeaderKey) {
                    final String displayText = subHeaderKey
                        .replaceAll('_', ' ')
                        .toUpperCase();
                    
                    final Color subHeaderColor = readonlyKeys.contains(subHeaderKey) 
                        ? Colors.black.withOpacity(0.9) 
                        : headerColor.withOpacity(0.8); // ⭐️ Color Dinámico ⭐️

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


  // --- CONSTRUCCIÓN DE LAS FILAS DE DATOS (SIN CAMBIOS) ---

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
            
            if (readonlyKeys.contains(key)) {
              // Campo de solo lectura (Si se usa 'readonlyKeys')
              final String calculatedValue = alumno[key]?.toString() ?? '-';
              return _buildReadonlyCell(calculatedValue, GRADE_CELL_WIDTH, rowColor);
            } else {
              // Campo editable
              return _buildGradeCellAsContainer(buildGradeCell(alumnoId, key), GRADE_CELL_WIDTH, rowColor);
            }
          }).toList(),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES (Modificamos la firma de _buildHeaderCell) ---

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
  
  // Modificamos la firma para que use el color dinámico que se le pasa
  Widget _buildHeaderCell(String text, {required double width, required double height, required Color color}) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.0),
          color: color, // ⭐️ Color Dinámico ⭐️
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