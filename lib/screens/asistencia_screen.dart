import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';
import 'package:oficinaescolar_colaboradores/screens/lista_screen.dart';
import 'package:provider/provider.dart';

// Asegúrate de tener estas importaciones correctas para tu proyecto
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 

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
        title: const Text('Tomar Asistencia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona el tipo de asistencia:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ LLAMADA ACTUALIZADA
                _construirBotonOpcion(
                  context,
                  title: 'Materia',
                  icon: Icons.school,
                  value: 'materia',
                ),
                // ✅ LLAMADA ACTUALIZADA
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
              // ✅ LLAMADA ACTUALIZADA
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
  Widget _construirBotonOpcion( // ✅ CAMBIO DE NOMBRE
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
  Widget _construirListaCursos(UserProvider userProvider) { // ✅ CAMBIO DE NOMBRE
    final bool isMateria = _selectedOption == 'materia';
    
    // Asumimos que los modelos MateriaModel y ClubModel existen y tienen los getters correctos
    // para 'idCurso', 'materia', 'nombreCurso', 'planEstudio', 'horario'.
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
                // Navegación a la vista de detalles/opciones para Materias
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navegar a detalles de materia: $title')),
                );
              
              } else {
                // Navegación a la ListaScreen para tomar asistencia de Clubes
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