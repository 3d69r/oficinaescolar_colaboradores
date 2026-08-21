import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';

class UniversidadCalificacionesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alumnos;
  final BoletaEncabezadoModel estructura;
  final DataCell Function(String, String) buildGradeCell;
  final List<String> readonlyKeys;

   const UniversidadCalificacionesWidget({
    super.key,
    required this.alumnos,
    required this.estructura,
    required this.buildGradeCell,
    required this.readonlyKeys,
  });

  static const double GRADE_CELL_WIDTH = 150.0;
  static const double NAME_CELL_WIDTH = 260.0;


  @override
  Widget build(BuildContext context) {
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicHeaderColor = colores.headerColor;

    if (alumnos.isEmpty) {
      return _buildEmptyState();
    }

    final List<Map<String, dynamic>> headers = _getDynamicHeaders();
    final List<String> allSubHeaderKeys = headers.expand((h) => h['subHeaders'] as List<String>).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            _buildHeaderRow(headers, dynamicHeaderColor),
            ...List.generate(alumnos.length, (index) {
              final alumno = alumnos[index];
              return _buildAlumnoRow(alumno, allSubHeaderKeys, index.isEven);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.groups_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No se encontraron alumnos asignados a este curso.',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE ENCABEZADOS DINÁMICOS (SIN CAMBIOS) ---

  List<Map<String, dynamic>> _getDynamicHeaders() {
    final List<Map<String, dynamic>> headers = [];

    estructura.encabezados.forEach((nombreHeader, claveRelacion) {

      final String relationString = estructura.relaciones[claveRelacion] ?? nombreHeader;

      final List<String> subHeaders = relationString
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => s.trim())
          .toList();

      if (subHeaders.isNotEmpty) {
          headers.add({
            'header': nombreHeader,
            'subHeaders': subHeaders,
          });
      }
    });

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
    final bool needsDoubleHeight = headers.length == 1 && (headers.first['subHeaders'] as List<String>).length > 1;
    final double headerHeight = 46.0;

    return IntrinsicHeight(
      child: Row(
        children: [
          _buildHeaderCell(
            'ALUMNO',
            width: NAME_CELL_WIDTH,
            height: needsDoubleHeight ? headerHeight * 2 : headerHeight,
            color: headerColor,
            alignLeft: true,
          ),

          ...headers.map((header) {
            final subHeaders = header['subHeaders'] as List<String>;

            if (subHeaders.length == 1 && !needsDoubleHeight) {
                final String displayText = subHeaders.first.replaceAll('_', ' ').toUpperCase();
                return _buildHeaderCell(
                    displayText,
                    width: GRADE_CELL_WIDTH,
                    height: headerHeight,
                    color: headerColor,
                );
            }

            return Column(
              children: [
                _buildHeaderCell(
                  header['header'].toString().toUpperCase(),
                  width: subHeaders.length * GRADE_CELL_WIDTH,
                  height: headerHeight,
                  color: headerColor,
                ),
                Row(
                  children: subHeaders.map((subHeaderKey) {
                    final String displayText = subHeaderKey
                        .replaceAll('_', ' ')
                        .toUpperCase();

                    final Color subHeaderColor = readonlyKeys.contains(subHeaderKey)
                        ? headerColor.withOpacity(0.65)
                        : headerColor.withOpacity(0.85);

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


  // --- CONSTRUCCIÓN DE LAS FILAS DE DATOS ---

  Widget _buildAlumnoRow(
    Map<String, dynamic> alumno,
    List<String> allSubHeaderKeys,
    bool isEven,
  ) {
    final Color rowColor = isEven ? const Color(0xFFF7F8FA) : Colors.white;
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
          Container(
            width: NAME_CELL_WIDTH,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: rowColor,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Text(
              nombreCompleto,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF1E1E2C)),
            ),
          ),

          // ⭐️ Ambas columnas son editables solo si NO están en readonlyKeys (misma lógica original) ⭐️
          ...allSubHeaderKeys.map((key) {
            final bool isReadonly = readonlyKeys.contains(key);

            if (isReadonly) {
              final String calculatedValue = alumno[key]?.toString() ?? '-';
              return _buildReadonlyCell(calculatedValue, GRADE_CELL_WIDTH, rowColor);
            } else {
              return _buildGradeCellAsContainer(buildGradeCell(alumnoId, key), GRADE_CELL_WIDTH, rowColor);
            }
          }).toList(),
        ],
      ),
    );
  }

  // --- MÉTODOS AUXILIARES ---

  Widget _buildGradeCellAsContainer(DataCell dataCell, double width, Color color) {
    final Widget cellContent = dataCell.child;

    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 46.0),
      padding: EdgeInsets.zero,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        child: cellContent,
      ),
    );
  }

  Widget _buildReadonlyCell(String value, double width, Color color) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 46.0),
      padding: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.blueGrey.shade700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required double width, required double height, required Color color, bool alignLeft = false}) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
          child: Text(
            text,
            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            softWrap: true,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}