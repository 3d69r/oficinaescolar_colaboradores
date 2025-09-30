import 'package:flutter/material.dart';
// Asegúrate de que esta importación sea correcta para tu modelo MateriaModel
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:provider/provider.dart';

// Opcional: Importar el UserProvider si necesitas cargar la lista real en el futuro
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';

class PreescolarListadoScreen extends StatefulWidget {
  final MateriaModel materiaSeleccionada;

  const PreescolarListadoScreen({
    super.key,
    required this.materiaSeleccionada,
  });

  @override
  State<PreescolarListadoScreen> createState() => _PreescolarListadoScreenState();
}

class _PreescolarListadoScreenState extends State<PreescolarListadoScreen> {
  // En una implementación real, aquí cargarías la lista de alumnos
  // con sus últimos comentarios guardados.
  final List<Map<String, String>> _alumnosConComentarios = [
    {'nombre': 'Ana Sofía Rangel', 'estatus': 'Comentarios Capturados'},
    {'nombre': 'Benito Juárez Garcia', 'estatus': 'Comentarios Capturados'},
    {'nombre': 'Carlos Alberto Díaz', 'estatus': 'Comentarios Parciales'},
    {'nombre': 'Diana Laura Hernández', 'estatus': 'Sin Capturar'},
    {'nombre': 'Emilio Zapata Salazar', 'estatus': 'Comentarios Capturados'},
  ];
  
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    // ⭐️ Opcional: Usar el color dinámico del header
    final headerColor = Provider.of<UserProvider>(context).colores.headerColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Listado: ${widget.materiaSeleccionada.materia}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        //title:  Text('Comentarios por alumno (Preescolar)'),
        backgroundColor: headerColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alumnosConComentarios.isEmpty
              ? const Center(
                  child: Text(
                    'No hay alumnos o comentarios para mostrar.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _alumnosConComentarios.length,
                  itemBuilder: (context, index) {
                    final alumno = _alumnosConComentarios[index];
                    final String estatus = alumno['estatus']!;
                    
                    Color estatusColor;
                    if (estatus == 'Comentarios Capturados') {
                      estatusColor = Colors.green.shade700;
                    } else if (estatus == 'Comentarios Parciales') {
                      estatusColor = Colors.orange.shade700;
                    } else {
                      estatusColor = Colors.red.shade700;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blueGrey),
                        title: Text(
                          alumno['nombre']!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: estatusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            estatus,
                            style: TextStyle(
                              color: estatusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          // 🚨 Lógica de la vida real: Navegar a la vista de captura
                          // para editar los comentarios de este alumno en específico.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ver/Editar comentarios de ${alumno['nombre']}'),
                              backgroundColor: Colors.indigo,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}