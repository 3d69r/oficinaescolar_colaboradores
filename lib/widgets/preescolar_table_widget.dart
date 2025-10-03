import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importar Provider
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; // 2. Importar UserProvider

class PreescolarCalificacionesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  
  // Aquí usamos 'observationKeys' como el identificador de los campos editables
  final List<String> observationKeys; 
  
  //final Color headerColor = Colors.green.shade700; // Eliminado

   const PreescolarCalificacionesWidget({
    super.key,
    required this.alumnos,
    required this.estructura,
    required this.buildGradeCell,
    required this.observationKeys, // Claves de los comentarios (ej: comentario_parcial_1)
  });

  // --- LÓGICA DE EXTRACCIÓN DE ENCABEZADOS ---
  
  List<Map<String, dynamic>> _getDynamicHeaders() {
      final List<Map<String, dynamic>> headers = [];
      
      // Itera sobre los encabezados principales (Parcial 1, Parcial 2, Parcial 3).
      estructura.encabezados.forEach((key, value) {
          // 'key' es el nombre del encabezado (Ej: "Parcial 1")
          // 'value' es la clave de la relación (Ej: "enc_relacion_1")

          // Busca la clave del dato real (Ej: "comentario_parcial_1") usando la clave de relación.
          final String relationString = estructura.relaciones[value] ?? ''; 
          
          final List<String> subKeys = relationString
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => s.trim())
              .toList();

          // Solo si encontramos una clave de dato válida (Ej: 'comentario_parcial_1'), la agregamos.
          if (subKeys.isNotEmpty) {
              headers.add({
                  'header': key, // ⭐️ USAMOS EL NOMBRE DEL ENCABEZADO ("Parcial 1") COMO TÍTULO
                  'dataKey': subKeys.first, // USAMOS LA CLAVE DEL DATO ("comentario_parcial_1") PARA EL CAMPO
              });
          }
      });
      return headers; // Esto debe devolver una lista con 3 elementos: Parcial 1, Parcial 2, Parcial 3.
  }
  
  // --- CONSTRUCCIÓN DE LA TABLA VERTICAL ---
  
  @override
  Widget build(BuildContext context) {
    // 3. ACCESO AL COLOR DINÁMICO
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;
    
    if (alumnos.isEmpty) {
      return const Center(child: Text('No se encontraron alumnos asignados.'));
    }

    final List<Map<String, dynamic>> headers = _getDynamicHeaders();
    
    if (headers.isEmpty) {
        return const Center(
          child: Text(
            'Error: No se definió la estructura de observaciones para Preescolar.', 
            style: TextStyle(color: Colors.red)
          )
        );
    }


    return SingleChildScrollView(
      scrollDirection: Axis.vertical, // Scroll vertical para los bloques de alumnos
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Captura de Observaciones de Preescolar',
              // ⭐️ USAR COLOR DINÁMICO ⭐️
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicHeaderColor),
            ),
          ),
          
          // Construcción de cada Bloque de Alumno
          // Pasamos el color al bloque
          ...alumnos.map((alumno) {
            return _buildAlumnoBlock(alumno, headers, dynamicHeaderColor);
          }).toList(),
        ],
      ),
    );
  }

  // --- BLOQUE DE ALUMNO (Modificamos la firma) ---
  
  Widget _buildAlumnoBlock(Map<String, dynamic> alumno, List<Map<String, dynamic>> headers, Color headerColor) {
    final String alumnoId = alumno['id_alumno'] as String? ?? '';
    final String primerNombre = alumno['primer_nombre'] as String? ?? '';
    final String segundoNombre = alumno['segundo_nombre'] as String? ?? '';
    final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
    final String apellidoMat = alumno['apellido_mat'] as String? ?? '';
    final String nombreCompleto = '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.trim().replaceAll(RegExp(r'\s+'), ' '); 

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
              'Alumno: $nombreCompleto'.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const Divider(),
            
            // ⭐️ SOLO ITERA SOBRE LA LISTA DE HEADERS (3 VECES) ⭐️
            ...headers.map((header) {
              // Pasamos el color a la sección de observación
              return _buildObservationSection(alumnoId, header, headerColor);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  // --- SECCIÓN DE OBSERVACIÓN (Modificamos la firma) ---
  
  Widget _buildObservationSection(String alumnoId, Map<String, dynamic> header, Color headerColor) {
    // Usamos el nombre del encabezado (Ej: "Parcial 1") como título.
    final String displayTitle = header['header'].toString().toUpperCase(); 
    final String dataKey = header['dataKey'] as String; // Ej: "comentario_parcial_1"
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del Parcial/Observación
          Text(
            displayTitle,
            // ⭐️ USAR COLOR DINÁMICO ⭐️
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