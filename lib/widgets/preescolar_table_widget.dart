import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';

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

  // ⭐️ VARIABLES DE ESTADO PARA EL FILTRO (SIN CAMBIOS DE LÓGICA) ⭐️
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _filteredAlumnos = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredAlumnos = widget.alumnos;
    _searchController.addListener(_filterAlumnos);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAlumnos);
    _searchController.dispose();
    super.dispose();
  }

  void _filterAlumnos() {
    final String query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredAlumnos = widget.alumnos;
      });
      return;
    }

    final List<Map<String, dynamic>> results = widget.alumnos.where((alumno) {
      final String primerNombre = alumno['primer_nombre'] as String? ?? '';
      final String segundoNombre = alumno['segundo_nombre'] as String? ?? '';
      final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
      final String apellidoMat = alumno['apellido_mat'] as String? ?? '';

      final String nombreCompleto = '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.toLowerCase().trim();

      return nombreCompleto.contains(query);
    }).toList();

    setState(() {
      _filteredAlumnos = results;
    });
  }

  // --- LÓGICA DE EXTRACCIÓN DE ENCABEZADOS (SIN CAMBIOS) ---

  List<Map<String, dynamic>> _getDynamicHeaders() {
      final List<Map<String, dynamic>> headers = [];

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
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;

    if (widget.alumnos.isEmpty) {
      return _buildEmptyState('No se encontraron alumnos asignados.');
    }

    final List<Map<String, dynamic>> headers = _getDynamicHeaders();

    if (headers.isEmpty) {
        return _buildEmptyState(
          'Error: No se definió la estructura de observaciones para Preescolar.',
          isError: true,
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.child_care_rounded, color: dynamicHeaderColor, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Captura de observaciones de preescolar',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: dynamicHeaderColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ⭐️ CAMPO DE BÚSQUEDA MODERNO ⭐️
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Filtrar por alumno',
              hintText: 'Escribe el nombre del alumno...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _filterAlumnos();
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (_filteredAlumnos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No se encontró ningún alumno con el nombre "${_searchController.text}".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

        ..._filteredAlumnos.map((alumno) {
          return _buildAlumnoBlock(alumno, headers, dynamicHeaderColor);
        }).toList(),
      ],
    );
  }

  Widget _buildEmptyState(String message, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.groups_outlined,
              size: 40,
              color: isError ? Colors.red.shade300 : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? Colors.red.shade400 : Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BLOQUE DE ALUMNO (TARJETA MODERNA) ---

  Widget _buildAlumnoBlock(Map<String, dynamic> alumno, List<Map<String, dynamic>> headers, Color headerColor) {
    final String alumnoId = alumno['id_alumno'] as String? ?? '';
    final String primerNombre = alumno['primer_nombre'] as String? ?? '';
    final String segundoNombre = alumno['segundo_nombre'] as String? ?? '';
    final String apellidoPat = alumno['apellido_pat'] as String? ?? '';
    final String apellidoMat = alumno['apellido_mat'] as String? ?? '';
    final String nombreCompleto = '$primerNombre $segundoNombre $apellidoPat $apellidoMat'.trim().replaceAll(RegExp(r'\s+'), ' ');
    final String iniciales = (primerNombre.isNotEmpty ? primerNombre[0] : '') +
        (apellidoPat.isNotEmpty ? apellidoPat[0] : '');

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: headerColor.withOpacity(0.12),
                  child: Text(
                    iniciales.toUpperCase(),
                    style: TextStyle(color: headerColor, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombreCompleto,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E1E2C)),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

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
    final String dataKey = header['dataKey'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: headerColor, letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          _buildCommentInputField(alumnoId, dataKey),
        ],
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA LA CAPTURA ---

  Widget _buildCommentInputField(String alumnoId, String key) {
    final DataCell dataCell = widget.buildGradeCell(alumnoId, key);

    return Container(
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: dataCell.child,
    );
  }
}