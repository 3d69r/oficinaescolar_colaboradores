import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WebsInteresScreen extends StatelessWidget {
  final EscuelaModel escuela;

  const WebsInteresScreen({
    super.key,
    required this.escuela,
  });

 @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    // Función para lanzar la URL, así evitamos duplicar código.
    void launchUrlInApp(String url) async {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('No se pudo lanzar la URL: $url');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la página web.')),
        );
      }
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sitios de Interés', style: TextStyle(color: Colors.white)),
          backgroundColor: colores.headerColor,
          iconTheme: const IconThemeData(color: Colors.white),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (escuela.websDeInteres != null && escuela.websDeInteres!.isNotEmpty)
                ...escuela.websDeInteres!.map((web) {
                  if (web.adicional.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      // Aquí, el Card envuelve el ListTile.
                      // El onTap se aplica al ListTile.
                      child: ListTile(
                        onTap: () => launchUrlInApp(web.adicional),
                        leading: Icon(Icons.public, color: colores.headerColor),
                        title: Text(web.nombreCat, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          web.adicional,
                          style: TextStyle(
                            color: colores.botonesColor,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList()
              else
                const Center(
                  child: Text('No hay webs de interés disponibles.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}