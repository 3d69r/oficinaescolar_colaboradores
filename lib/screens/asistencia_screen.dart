import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';
import 'package:oficinaescolar_colaboradores/screens/lista_screen.dart';
import 'package:provider/provider.dart';

// Asegúrate de tener estas importaciones correctas para tu proyecto
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 
import 'package:oficinaescolar_colaboradores/screens/captura_calificaciones_screen.dart'; 
import 'package:oficinaescolar_colaboradores/screens/preescolar_listado_screen.dart'; // ⭐️ NUEVA IMPORTACIÓN ⭐️

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
    
    // ⭐️ EXTRACCIÓN Y CONVERSIÓN DEL COLOR ⭐️
    // Asumimos que userProvider.colores.headerColor devuelve un Color de Flutter
    final Color headerColor = userProvider.colores.headerColor;

    if (userProvider.colaboradorModel == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tomar Asistencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones y Asistencia',  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: headerColor, // Usando el color dinámico en el AppBar
        centerTitle: true,
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
                  headerColor: headerColor
                ),
                _construirBotonOpcion(
                  context,
                  title: 'Clubes',
                  icon: Icons.sports_soccer,
                  value: 'clubes',
                  headerColor: headerColor
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
        required Color headerColor // Tipo Color para el parámetro
      }) {
    final bool isSelected = _selectedOption == value;
    return Expanded(
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isSelected
              // ⭐️ Uso del color dinámico en el borde
              ?  BorderSide(color: headerColor , width: 2)
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
                // Uso del color dinámico en el ícono
                Icon(icon, size: 40, color: isSelected ? headerColor : Colors.grey),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // Uso del color dinámico en el texto
                    color: isSelected ? headerColor : Colors.black87,
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
    final Color headerColor = userProvider.colores.headerColor; // Color para usar en ExpansionTile
    
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
        
        // Manejo de modelos
        final MateriaModel? materia = isMateria ? (item as MateriaModel) : null;
        
        final String idCurso = isMateria 
            ? materia!.idCurso 
            : (item as ClubModel).idCurso;
            
        final String title = isMateria
            ? materia!.materia
            : (item as ClubModel).nombreCurso; 
        
        final String subtitle = isMateria
            ? 'Plan: ${materia!.planEstudio}'
            : 'Horario: ${(item as ClubModel).horario}';

        // ⭐️ LÓGICA CLAVE: Verificar si es Preescolar ⭐️
        final bool isPreescolar = isMateria && materia!.planEstudio == 'Preescolar';

        // Si es Club, usa el ListTile simple para asistencia
        if (!isMateria) {
            return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                        // Navegación a ListaScreen (Asistencia de Clubes)
                        Navigator.push(
                            context, 
                            MaterialPageRoute(
                                builder: (_) => ListaScreen(
                                    idCurso: idCurso, 
                                    tipoCurso: TipoCurso.club,
                                ),
                            ),
                        );
                    },
                ),
            );
        }

        // Si es Materia, usamos la lógica de ExpansionTile para Preescolar, o ListTile para las demás
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: isPreescolar
              ? _buildPreescolarExpansionTile(context, materia, title, subtitle, headerColor)
              : _buildGeneralMateriaTile(context, materia!, title, subtitle),
        );
      },
    );
  }

  // ⭐️ MÉTODO: Para materias de Preescolar (con botones de acción)
  Widget _buildPreescolarExpansionTile(
      BuildContext context, 
      MateriaModel materia, 
      String title, 
      String subtitle,
      Color headerColor,
  ) {
      return ExpansionTile(
          key: PageStorageKey<String>(materia.idMateriaClase),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          initiallyExpanded: false,
          collapsedIconColor: headerColor,
          iconColor: headerColor,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: <Widget>[
              // 1. Botón para Capturar Comentarios
              ListTile(
                  leading: Icon(Icons.edit_note, color: headerColor),
                  title: const Text('Capturar Comentarios'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                      Navigator.push(
                          context, 
                          MaterialPageRoute(
                              builder: (_) => CapturaCalificacionesScreen(
                                  materiaSeleccionada: materia, 
                              ),
                          ),
                      );
                  },
              ),
              const Divider(height: 1),
              // 2. Botón para Ver Listado
              ListTile(
                  leading: const Icon(Icons.list_alt, color: Colors.blueGrey),
                  title: const Text('Ver Listado de Comentarios'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                      Navigator.push(
                          context, 
                          MaterialPageRoute(
                              builder: (_) => PreescolarListadoScreen(
                                  materiaSeleccionada: materia,
                              ),
                          ),
                      );
                  },
              ),
          ],
      );
  }

  // ⭐️ MÉTODO: Para materias Generales 
  Widget _buildGeneralMateriaTile(
      BuildContext context, 
      MateriaModel materia, 
      String title, 
      String subtitle,
  ) {
      return ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
              // Navegación directa a CapturaCalificacionesScreen para los demás niveles
              Navigator.push(
                  context, 
                  MaterialPageRoute(
                      builder: (_) => CapturaCalificacionesScreen(
                          materiaSeleccionada: materia,
                      ),
                  ),
              );
          },
      );
  }
}