import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/utils/log_util.dart';


class DatosEscuelaScreen extends StatelessWidget {
  final EscuelaModel escuela;

  const DatosEscuelaScreen({super.key, required this.escuela});

  // ---------- Helpers de UI ----------

  Widget _sectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta genérica moderna: ícono en "badge" + título + subtítulo
  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectorCard(String title, String directorName, Color accent) {
    if (directorName.isEmpty) return const SizedBox.shrink();
    return _infoTile(
      icon: Icons.school_rounded,
      title: title,
      subtitle: directorName,
      accent: accent,
    );
  }

  Widget _buildDomicilioCard(Domicilio domicilio, Color accent) {
    if (domicilio.adicional.isEmpty) return const SizedBox.shrink();
    return _infoTile(
      icon: Icons.location_on_rounded,
      title: domicilio.nombreCat,
      subtitle: domicilio.adicional,
      accent: accent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    final String schoolLogoUrl = escuela.rutaLogo.isNotEmpty
        ? '${ApiConstants.assetsBaseUrl}${escuela.rutaLogo}'
        : '';
    final bool isPng = schoolLogoUrl.toLowerCase().endsWith('.png');

    final direccionCompleta =
        '${escuela.calle} ${escuela.numeroExterior} '
        '${escuela.numeroInterior.isNotEmpty ? 'Int. ${escuela.numeroInterior}' : ''}, '
        '${escuela.colonia}, C.P. ${escuela.codigoPostal}, '
        '${escuela.municipio}, ${escuela.estado}';

    final directores = <List<String>>[
      ['Director General', escuela.empDirector],
      ['Director de Preescolar', escuela.empDirectorPreesco],
      ['Director de Primaria', escuela.empDirectorPrim],
      ['Director de Secundaria', escuela.empDirectorSec],
      ['Director de Preparatoria', escuela.empDirectorPrepa],
    ].where((d) => d[1].isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // ---------- Header moderno con degradado ----------
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: colores.headerColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colores.headerColor,
                      colores.headerColor.withOpacity(0.75),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30, bottom: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isPng ? colores.headerColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: schoolLogoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: schoolLogoUrl,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) {
                                      appLog(
                                          'Error al cargar imagen del logo: $error');
                                      return const Icon(Icons.wifi_off,
                                          size: 40, color: Colors.white);
                                    },
                                  )
                                : const Icon(Icons.wifi_off,
                                    size: 40, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            escuela.nombreComercial,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            escuela.cicloEscolar.periodo,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ---------- Contenido ----------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Institución + Dirección principal
                  _sectionTitle('Información general', colores.headerColor),
                  _infoTile(
                    icon: Icons.business_rounded,
                    title: 'Institución Educativa',
                    subtitle: escuela.nombreComercial,
                    accent: colores.headerColor,
                  ),
                  _infoTile(
                    icon: Icons.location_on_rounded,
                    title: 'Dirección',
                    subtitle: direccionCompleta,
                    accent: colores.headerColor,
                  ),

                  // Directores
                  if (directores.isNotEmpty) ...[
                    _sectionTitle('Directivos', colores.headerColor),
                    ...directores.map(
                      (d) => _buildDirectorCard(d[0], d[1], colores.headerColor),
                    ),
                  ],

                  // Domicilios adicionales
                  if (escuela.dirDomicilios != null &&
                      escuela.dirDomicilios!.isNotEmpty) ...[
                    _sectionTitle('Domicilio(s) adicionales',
                        colores.headerColor),
                    ...escuela.dirDomicilios!.map(
                      (domicilio) =>
                          _buildDomicilioCard(domicilio, colores.headerColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//MENSAJE BANDERA ESTE CODIGO ES FUNCIONAL