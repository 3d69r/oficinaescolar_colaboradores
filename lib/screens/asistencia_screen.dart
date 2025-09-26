import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';
import 'package:oficinaescolar_colaboradores/screens/lista_screen.dart';
import 'package:provider/provider.dart';

// Asegúrate de tener estas importaciones correctas para tu proyecto
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:oficinaescolar_colaboradores/models/boleta_encabezado_model.dart'; // Aunque no se use aquí, se usa en la navegación
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 

// ⭐️ Importación de la nueva vista de calificaciones
import 'package:oficinaescolar_colaboradores/screens/captura_calificaciones_screen.dart'; // Asume que esta es la ruta correcta

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  // Estado para controlar la opción seleccionada (null, 'materia' o 'clubes')
  String? _selectedOption; 

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    if (userProvider.colaboradorModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tomar Asistencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones y Asistencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona la opcion deseada:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _construirBotonOpcion(
                  context,
                  title: 'Materia',
                  icon: Icons.school,
                  value: 'materia',
                ),
                _construirBotonOpcion(
                  context,
                  title: 'Clubes',
                  icon: Icons.sports_soccer,
                  value: 'clubes',
                ),
              ],
            ),
            const SizedBox(height: 30),

            if (_selectedOption != null) ...[
              Text(
                _selectedOption == 'materia' ? 'Materias asignadas:' : 'Clubes asignados:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _construirListaCursos(userProvider),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ✅ MÉTODO: Construir botón de opción (Materia/Clubes)
  Widget _construirBotonOpcion( 
      BuildContext context, {
        required String title,
        required IconData icon,
        required String value,
      }) {
    final bool isSelected = _selectedOption == value;
    return Expanded(
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isSelected
              ? const BorderSide(color: Colors.blueAccent, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedOption = value;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
            child: Column(
              children: [
                Icon(icon, size: 40, color: isSelected ? Colors.blueAccent : Colors.grey),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.blueAccent : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO: Construir lista de cursos (Materias o Clubes)
  Widget _construirListaCursos(UserProvider userProvider) { 
    final bool isMateria = _selectedOption == 'materia';
    
    // El código asume que MateriaModel y ClubModel tienen los getters correctos
    final List items = isMateria 
        ? userProvider.colaboradorMaterias 
        : userProvider.colaboradorClubes;

    if (items.isEmpty) {
      return Center(
        child: Text(
          isMateria 
              ? 'No tienes materias asignadas para este ciclo.' 
              : 'No tienes clubes asignados para este ciclo.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        final String idCurso = isMateria 
            ? (item as MateriaModel).idCurso 
            : (item as ClubModel).idCurso;
            
        final String title = isMateria
            ? (item as MateriaModel).materia
            : (item as ClubModel).nombreCurso; 
        
        final String subtitle = isMateria
            ? 'Plan: ${(item as MateriaModel).planEstudio}'
            : 'Horario: ${(item as ClubModel).horario}';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              if (isMateria) {
                // ⭐️ LÓGICA DE NAVEGACIÓN A CALIFICACIONES
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (_) => CapturaCalificacionesScreen(
                      materiaSeleccionada: item as MateriaModel, // Se pasa el modelo completo
                    ),
                  ),
                );
              
              } else {
                // Navegación original a la ListaScreen (Asistencia de Clubes)
                 Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => ListaScreen(
                        idCurso: idCurso, 
                        tipoCurso: TipoCurso.club,
                      ),
                    ),
                  );
                
              }
            },
          ),
        );
      },
    );
  }
}