import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 

// ⭐️ CONVERTIDO A STATEFUL WIDGET ⭐️
class PreescolarCalificacionesWidget extends StatefulWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  
  // Aquí usamos 'observationKeys' como el identificador de los campos editables
  final List<String> observationKeys; 
  
   const PreescolarCalificacionesWidget({
    super.key,
    required this.alumnos,
    required this.estructura,
    required this.buildGradeCell,
    required this.observationKeys, // Claves de los comentarios (ej: comentario_parcial_1)
  });

  @override
  State<PreescolarCalificacionesWidget> createState() => _PreescolarCalificacionesWidgetState();
}

class _PreescolarCalificacionesWidgetState extends State<PreescolarCalificacionesWidget> {
  
  // ⭐️ VARIABLES DE ESTADO PARA EL FILTRO ⭐️
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _filteredAlumnos = [];
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // 1. Inicializar la lista filtrada con todos los alumnos
    _filteredAlumnos = widget.alumnos;
    
    // 2. Agregar listener para actualizar la lista cada vez que cambia el texto
    _searchController.addListener(_filterAlumnos);
  }
  
  @override
  void dispose() {
    // 3. Limpiar controller y listener al destruir el widget
    _searchController.removeListener(_filterAlumnos);
    _searchController.dispose();
    super.dispose();
  }
  
  // ⭐️ MÉTODO DE FILTRADO ⭐️
  void _filterAlumnos() {
    // Usamos el texto de búsqueda en minúsculas y sin espacios iniciales/finales
    final String query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      // Si la búsqueda está vacía, mostrar todos
      setState(() {
        _filteredAlumnos = widget.alumnos;
      });
      return;
    }
    
    // Filtramos en base al nombre completo del alumno
    final List<Map<String, dynamic>> results = widget.alumnos.where((alumno) {
      final String primerNombre = alumno['primer_nombre'] as String? ?? '';
      final String segundoNombre = alumno['segundo_nombre'] as String? ?? '';
      final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
      final String apellidoMat = alumno['apellido_mat'] as String? ?? '';
      
      // Concatenamos y normalizamos el nombre para la búsqueda
      final String nombreCompleto = '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.toLowerCase().trim();
      
      return nombreCompleto.contains(query);
    }).toList();
    
    setState(() {
      _filteredAlumnos = results;
    });
  }

  // --- LÓGICA DE EXTRACCIÓN DE ENCABEZADOS ---
  
  List<Map<String, dynamic>> _getDynamicHeaders() {
      final List<Map<String, dynamic>> headers = [];
      
      // Acceder a la estructura del widget
      widget.estructura.encabezados.forEach((key, value) {
          final String relationString = widget.estructura.relaciones[value] ?? ''; 
          
          final List<String> subKeys = relationString
              .split(',')
              .where((s) => s.isNotEmpty)
              .map((s) => s.trim())
              .toList();

          if (subKeys.isNotEmpty) {
              headers.add({
                  'header': key, 
                  'dataKey': subKeys.first,
              });
          }
      });
      return headers; 
  }
  
  // --- CONSTRUCCIÓN DEL WIDGET ---
  
  @override
  Widget build(BuildContext context) {
    // ACCESO AL COLOR DINÁMICO
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;
    
    if (widget.alumnos.isEmpty) {
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

    // El SingleChildScrollView que contiene este widget debe manejar el scroll vertical.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // Usamos MainAxisSize.max porque este Column sí tiene límites de altura definidos por el padre
      // (asumimos que está directamente bajo el body o en un Expanded/SizedBox).
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            'Captura de Observaciones de Preescolar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicHeaderColor),
          ),
        ),
        
        // ⭐️ CAMPO DE BÚSQUEDA ⭐️
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Filtrar por Alumno',
              hintText: 'Escribe el nombre del alumno...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterAlumnos();
                      },
                    )
                  : null,
            ),
          ),
        ),

        // ⭐️ LISTA DE ALUMNOS FILTRADA ⭐️
        // No usamos Expanded ni otro SingleChildScrollView aquí.
        
        // Mensaje si no hay resultados
        if (_filteredAlumnos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                'No se encontró ningún alumno con el nombre "${_searchController.text}".',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),

        // Construcción de cada Bloque de Alumno usando la lista FILTRADA
        ..._filteredAlumnos.map((alumno) {
          return _buildAlumnoBlock(alumno, headers, dynamicHeaderColor);
        }).toList(),
      ],
    );
  }

  // --- BLOQUE DE ALUMNO ---
  
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
            
            // Itera sobre los encabezados de parciales/observaciones
            ...headers.map((header) {
              return _buildObservationSection(alumnoId, header, headerColor);
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  // --- SECCIÓN DE OBSERVACIÓN ---
  
  Widget _buildObservationSection(String alumnoId, Map<String, dynamic> header, Color headerColor) {
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
    final DataCell dataCell = widget.buildGradeCell(alumnoId, key);
    
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