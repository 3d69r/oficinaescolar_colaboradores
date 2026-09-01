import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/models/aviso_seguimiento_model.dart';
import 'package:oficinaescolar_colaboradores/models/modo_visualizacion.dart';

class VisualizacionesAvisoModal extends StatelessWidget {
  final String titulo;
  final ModoVisualizacion modo;
  final List<AvisoSeguimientoModel> seguimiento;
  final dynamic colores;

  const VisualizacionesAvisoModal({
    super.key,
    required this.titulo,
    required this.modo,
    required this.seguimiento,
    required this.colores,
  });

  String _iconoPorTipo(String tipo) {
    switch (tipo) {
      case 'papa':
        return '👪';
      case 'colaborador':
        return '🧑‍🏫';
      default:
        return '👤';
    }
  }

  String _headerTitulo() {
    if (seguimiento.isEmpty) return titulo;
    switch (modo) {
      case ModoVisualizacion.individual:
        return seguimiento.first.nombreAlumnoRelacionado.isNotEmpty
            ? seguimiento.first.nombreAlumnoRelacionado
            : titulo;
      case ModoVisualizacion.grupoEspecifico:
        return seguimiento.first.salon.isNotEmpty ? seguimiento.first.salon : titulo;
      case ModoVisualizacion.nivelEducativo:
        return seguimiento.first.nivelEducativo.isNotEmpty
            ? seguimiento.first.nivelEducativo
            : titulo;
      case ModoVisualizacion.general:
        return 'Todo el plantel';
    }
  }

  IconData _headerIcono() {
    switch (modo) {
      case ModoVisualizacion.individual:
        return Icons.person_outline_rounded;
      case ModoVisualizacion.grupoEspecifico:
        return Icons.class_rounded;
      case ModoVisualizacion.nivelEducativo:
        return Icons.school_rounded;
      case ModoVisualizacion.general:
        return Icons.public_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final int leidos = seguimiento.where((s) => s.segLeido).length;
    final double progreso = seguimiento.isEmpty ? 0 : leidos / seguimiento.length;
    final Color headerColor = colores.headerColor as Color;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.95,
          maxHeight: screenHeight * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header con gradiente ---
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerColor, headerColor.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_headerIcono(), color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _headerTitulo(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // --- Barra de progreso de leídos ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progreso,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$leidos de ${seguimiento.length} han visto el aviso',
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // --- Contenido ---
              Flexible(
                child: seguimiento.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(30),
                        child: Text(
                          'No hay registros de seguimiento para este aviso.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF7F8FA),
                        child: _buildContenidoPorModo(),
                      ),
              ),

              // --- Cerrar ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoPorModo() {
    switch (modo) {
      case ModoVisualizacion.individual:
      case ModoVisualizacion.grupoEspecifico:
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemCount: seguimiento.length,
          itemBuilder: (context, index) => _buildTarjetaFila(seguimiento[index]),
        );

      case ModoVisualizacion.nivelEducativo:
        return _buildAgrupadoPorSalon(seguimiento);

      case ModoVisualizacion.general:
        return _buildAgrupadoPorNivel(seguimiento);
    }
  }

  Widget _buildGrupoCard({
    required IconData icono,
    required String titulo,
    required int leidos,
    required int total,
    required List<Widget> children,
    Color? tint,
  }) {
    final Color acento = tint ?? (colores.headerColor as Color);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: acento.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icono, size: 18, color: acento),
          ),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('$leidos de $total leyeron', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: leidos == total ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$leidos/$total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: leidos == total ? Colors.green.shade700 : Colors.orange.shade800,
              ),
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildAgrupadoPorSalon(List<AvisoSeguimientoModel> lista) {
    final Map<String, List<AvisoSeguimientoModel>> grupos = {};
    for (final v in lista) {
      final String key = v.salon.isNotEmpty ? v.salon : 'Sin salón / Colaboradores';
      grupos.putIfAbsent(key, () => []).add(v);
    }
    final List<String> keys = grupos.keys.toList()..sort();

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final grupo = keys[index];
        final items = grupos[grupo]!;
        final leidos = items.where((i) => i.segLeido).length;
        return _buildGrupoCard(
          icono: Icons.class_rounded,
          titulo: grupo,
          leidos: leidos,
          total: items.length,
          children: items.map((v) => _buildTarjetaFila(v)).toList(),
        );
      },
    );
  }

  Widget _buildAgrupadoPorNivel(List<AvisoSeguimientoModel> lista) {
    final Map<String, List<AvisoSeguimientoModel>> gruposNivel = {};
    for (final v in lista) {
      final String key = v.nivelEducativo.isNotEmpty ? v.nivelEducativo : 'Colaboradores';
      gruposNivel.putIfAbsent(key, () => []).add(v);
    }
    final List<String> nivelKeys = gruposNivel.keys.toList()..sort();

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: nivelKeys.length,
      itemBuilder: (context, index) {
        final nivel = nivelKeys[index];
        final itemsNivel = gruposNivel[nivel]!;
        final leidos = itemsNivel.where((i) => i.segLeido).length;
        return _buildGrupoCard(
          icono: Icons.school_rounded,
          titulo: nivel,
          leidos: leidos,
          total: itemsNivel.length,
          tint: Colors.deepPurple,
          children: [_buildAgrupadoPorSalon(itemsNivel)],
        );
      },
    );
  }

  Widget _buildTarjetaFila(AvisoSeguimientoModel v) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (v.segLeido ? Colors.green : Colors.orange).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Text(_iconoPorTipo(v.tipoUsuario), style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.nombreAlumnoRelacionado.isNotEmpty
                      ? '${v.nombreVe} · ${v.nombreAlumnoRelacionado}'
                      : v.nombreVe,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      v.segLeido ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 13,
                      color: v.segLeido ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      v.fechaHoraLegible,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (v.respuestaLegible != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                v.respuestaLegible!,
                style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}