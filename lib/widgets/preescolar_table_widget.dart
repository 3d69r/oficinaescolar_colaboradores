import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 

class PreescolarCalificacionesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  
  // Aquí usamos 'observationKeys' como el identificador de los campos editables
  final List<String> observationKeys; 
  
  final Color headerColor = Colors.green.shade700; 

   PreescolarCalificacionesWidget({
    super.key,
    required this.alumnos,
    required this.estructura,
    required this.buildGradeCell,
    required this.observationKeys, // Claves de los comentarios (ej: comentario_parcial_1)
  });

  // --- LÓGICA DE EXTRACCIÓN DE ENCABEZADOS ---
  
  List<Map<String, dynamic>> _getDynamicHeaders() {
      final List<Map<String, dynamic>> headers = [];
      
      // En Preescolar, los encabezados principales (Parcial 1) se mapean a las claves de comentario.
      estructura.encabezados.forEach((key, value) {
          final String relationString = estructura.relaciones[key] ?? key; 
          
          // La relación es la clave de la observación
          final List<String> subKeys = relationString
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => s.trim())
              .toList();

          headers.add({
              'header': value, // Ej: Parcial 1
              'dataKey': subKeys.first, // Ej: comentario_parcial_1
          });
      });
      
      // Si hay un campo de comentario final (fuera de las relaciones)
      if (estructura.comentarios.isNotEmpty) {
        estructura.comentarios.forEach((key, value) {
            headers.add({
              'header': value, // Ej: Observaciones Finales
              'dataKey': key, // Ej: comentario_final
            });
        });
      }
      return headers;
  }
  
  // --- CONSTRUCCIÓN DE LA TABLA VERTICAL ---
  
  @override
  Widget build(BuildContext context) {
    if (alumnos.isEmpty) {
      return const Center(child: Text('No se encontraron alumnos asignados.'));
    }

    final List<Map<String, dynamic>> headers = _getDynamicHeaders();

    return SingleChildScrollView(
      scrollDirection: Axis.vertical, // Scroll vertical para los bloques de alumnos
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Captura de Observaciones de Preescolar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: headerColor),
            ),
          ),
          
          // Construcción de cada Bloque de Alumno
          ...alumnos.map((alumno) {
            return _buildAlumnoBlock(alumno, headers);
          }).toList(),
        ],
      ),
    );
  }

  // --- BLOQUE DE ALUMNO ---
  
  Widget _buildAlumnoBlock(Map<String, dynamic> alumno, List<Map<String, dynamic>> headers) {
    final String alumnoId = alumno['id_alumno'] as String? ?? '';
    final String primerNombre = alumno['primer_nombre'] as String? ?? '';
    final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
    final String nombreCompleto = '$primerNombre $apellidoPat'.trim().replaceAll(RegExp(r'\s+'), ' '); 

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del Alumno
            Text(
              'Alumno: $nombreCompleto',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const Divider(),
            
            // Secciones de Observación (Parcial 1, Parcial 2, etc.)
            ...headers.map((header) {
              return _buildObservationSection(alumnoId, header);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  // --- SECCIÓN DE OBSERVACIÓN (Parcial 1, Parcial 2, etc.) ---
  
  Widget _buildObservationSection(String alumnoId, Map<String, dynamic> header) {
    final String displayTitle = header['header'].toString().toUpperCase();
    final String dataKey = header['dataKey'] as String;
    
    // En Preescolar, la clave de dato es la clave de la observación
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del Parcial/Observación
          Text(
            displayTitle,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: headerColor),
          ),
          const SizedBox(height: 6),
          
          // Campo de Captura de la Observación (Editable)
          _buildCommentInputField(alumnoId, dataKey),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA LA CAPTURA ---

  Widget _buildCommentInputField(String alumnoId, String key) {
    // Usamos el callback DataCell de la pantalla principal
    final DataCell dataCell = buildGradeCell(alumnoId, key);
    
    return Container(
      // Altura ajustable para un campo de texto de varias líneas
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 150), 
      width: double.infinity,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: dataCell.child,
    );
  }
}