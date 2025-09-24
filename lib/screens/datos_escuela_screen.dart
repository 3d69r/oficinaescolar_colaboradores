import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:provider/provider.dart';

class DatosEscuelaScreen extends StatelessWidget {
  final EscuelaModel escuela;

  const DatosEscuelaScreen({super.key, required this.escuela});

  // Función privada para crear una Card de director si el nombre no está vacío
  Widget _buildDirectorCard(BuildContext context, String title, String directorName) {
    if (directorName.isEmpty) {
      return const SizedBox.shrink();
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    return Column(
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(Icons.person, color: colores.headerColor),
            title: Text(title),
            subtitle: Text(directorName),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // Nuevo método para construir una tarjeta de domicilio
  Widget _buildDomicilioCard(BuildContext context, Domicilio domicilio, Color headerColor) {
    // Solo muestra la tarjeta si el campo 'adicional' no está vacío
    if (domicilio.adicional.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.location_on, color: headerColor),
        title: Text(domicilio.nombreCat),
        subtitle: Text(domicilio.adicional),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    final String schoolLogoUrl = escuela.rutaLogo.isNotEmpty
        ? '${ApiConstants.assetsBaseUrl}${escuela.rutaLogo}'
        : '';
        
    // ✅ Agregamos una validación para determinar si la imagen es PNG.
    final bool isPng = schoolLogoUrl.toLowerCase().endsWith('.png');

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Datos de la Escuela',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: colores.headerColor,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                // ✅ Cambiamos el color de fondo del cuadrado basándonos en la validación.
                decoration: BoxDecoration(
                  color: isPng ? colores.headerColor : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0.0),
                  child: schoolLogoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: schoolLogoUrl,
                          fit: BoxFit.contain,
                          // ❌ Eliminamos la propiedad de color para mostrar la imagen tal cual es.
                          // color: isPng ? Colors.white : null,
                          errorWidget: (context, url, error) {
                            debugPrint('Error al cargar imagen del logo: $error');
                            return Icon(Icons.wifi_off, size: 50, color: colores.headerColor);
                          },
                        )
                      : Icon(Icons.wifi_off, size: 50, color: colores.headerColor),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                escuela.nombreComercial,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Sección de Directores
              _buildDirectorCard(context, 'Director General', escuela.empDirector),
              _buildDirectorCard(context, 'Director de Preescolar', escuela.empDirectorPreesco),
              _buildDirectorCard(context, 'Director de Primaria', escuela.empDirectorPrim),
              _buildDirectorCard(context, 'Director de Secundaria', escuela.empDirectorSec),
              _buildDirectorCard(context, 'Director de Preparatoria', escuela.empDirectorPrepa),
              
              // Resto de las tarjetas de información general
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.business, color: colores.headerColor),
                  title: const Text('Institucion Educativa'),
                  subtitle: Text(escuela.nombreComercial),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.calendar_today, color: colores.headerColor),
                  title: const Text('Ciclo Escolar'),
                  subtitle: Text(escuela.cicloEscolar.periodo),
                ),
              ),
              const SizedBox(height: 10),
              // Tarjeta de la dirección principal
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.location_on, color: colores.headerColor),
                  title: const Text('Dirección'),
                  subtitle: Text(
                    '${escuela.calle} ${escuela.numeroExterior} '
                    '${escuela.numeroInterior.isNotEmpty ? 'Int. ${escuela.numeroInterior}' : ''}, '
                    '${escuela.colonia}, C.P. ${escuela.codigoPostal}, '
                    '${escuela.municipio}, ${escuela.estado}',
                  ),
                ),
              ),
              
              // Sección de Domicilios adicionales
              if (escuela.dirDomicilios != null && escuela.dirDomicilios!.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Domicilio(s)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ...escuela.dirDomicilios!.map((domicilio) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: _buildDomicilioCard(context, domicilio, colores.headerColor),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
