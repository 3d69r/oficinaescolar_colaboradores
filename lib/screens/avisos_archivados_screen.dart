/*import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'dart:convert'; // Necesario para json.decode, si lo usas.

// Asegúrate de importar tu UserProvider y tus modelos/widgets necesarios
// import 'ruta/a/user_provider.dart';
// import 'ruta/a/aviso_creado_item.dart';
// import 'ruta/a/crear_aviso_screen.dart'; // Si permites editar desde aquí

class AvisosArchivadosScreen extends StatelessWidget {
  const AvisosArchivadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos Archivados'),
        // No debería tener el botón flotante de crear, ya que son avisos históricos
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          // ⭐️ 1. FUENTE DE DATOS: Usamos la lista de avisos archivados ⭐️
          final avisos = provider.avisosArchivados;

          if (avisos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.archive_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No tienes avisos archivados.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Los avisos que archivas aparecerán aquí.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: avisos.length,
            itemBuilder: (context, index) {
              final avisoData = avisos[index];
              final String idAviso = avisoData['id_calendario']?.toString() ?? '0';

              // Usamos un Dismissible para la acción de Desarchivar
              return Dismissible(
                key: ValueKey(idAviso), // Clave única para el Dismissible
                direction: DismissDirection.startToEnd, // Solo deslizar de izquierda a derecha

                // ⭐️ 2. ACCIÓN PRINCIPAL: Desarchivar (Mover a Activos) ⭐️
                onDismissed: (direction) {
                  // Llamamos al método que mueve el aviso entre listas
                  provider.moverAvisoEntreListas(idAviso);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Aviso "${avisoData['titulo']}" desarchivado.')),
                  );
                },
                
                // Fondo que se muestra mientras se desliza
                background: Container(
                  color: Colors.green, // Color para desarchivar
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Row(
                    children: [
                      Icon(Icons.unarchive_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Desarchivar',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                // Contenido del elemento de la lista (asumiendo que tienes un Widget)
                child: AvisoCreadoItem(
                  avisoData: avisoData,
                  // Puedes pasar una función para manejar el tap para edición
                  onTap: () {
                    // Navegar a la pantalla de edición, usando los datos cargados
                    // Ejemplo:
                    // Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => CrearAvisoScreen(
                    //       avisoParaEditar: avisoData,
                    //     ),
                    //   ),
                    // );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------
// ⚠️ NOTA: Este es un Widget de ejemplo que asumo que existe.
// DEBES AJUSTARLO A TU IMPLEMENTACIÓN REAL DE LA LISTA.
// -----------------------------------------------------------
class AvisoCreadoItem extends StatelessWidget {
  final Map<String, dynamic> avisoData;
  final VoidCallback? onTap;

  const AvisoCreadoItem({required this.avisoData, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          avisoData['titulo'] ?? 'Sin Título',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Archivado • Sección: ${avisoData['seccion']}',
        ),
        trailing: const Icon(Icons.keyboard_arrow_right),
      ),
    );
  }
}*/