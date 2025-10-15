import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

// ⭐️ IMPORTACIONES NECESARIAS ⭐️
import 'package:oficinaescolar_colaboradores/config/api_constants.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
import 'package:oficinaescolar_colaboradores/screens/lista_screen.dart';
import 'package:oficinaescolar_colaboradores/screens/captura_calificaciones_screen.dart'; 
//import 'package:oficinaescolar_colaboradores/screens/preescolar_listado_screen.dart'; 

class AsistenciaScreen extends StatefulWidget {
  const AsistenciaScreen({super.key});

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen>
    with AutomaticKeepAliveClientMixin { 

  // Estado para controlar la opción seleccionada (null, 'materia' o 'clubes')
  String? _selectedOption; 
  
  // ⭐️ VARIABLES DE GESTIÓN DE RECARGA ⭐️
  bool _isLoading = false; 
  String? _errorMessage; 
  DateTime? _lastManualRefreshTime; 
  
  // Se inicializarán en initState
  late UserProvider _userProvider;
  late VoidCallback _autoRefreshListener;
  Timer? _autoRefreshTimer;


  @override
  void initState() {
    super.initState();
    debugPrint(
      'AsistenciaScreen: initState - Inicializando pantalla de asistencia/calificaciones.',
    );
    
    // ⭐️ CORRECCIÓN CLAVE: Inicialización inmediata de _userProvider
    // Esto previene el LateInitializationError si el RefreshIndicator se activa pronto.
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    // 1. Configuración del listener de auto-refresco del UserProvider
    _autoRefreshListener = () {
      debugPrint(
        'AsistenciaScreen: Gatillo de auto-refresco del UserProvider detectado. Recargando datos...',
      );
      // Llama a la función de carga con forceReload=true
      _cargarDatosAsistencia(forceReload: true);
    };

    // 2. Adjuntar el listener
    _userProvider.autoRefreshTrigger.addListener(_autoRefreshListener);

     // 💡 [CORRECCIÓN ALTERNATIVA]: Usar condicionales de compilación de Dart.
      bool shouldForceReload = false;
      
      // La web no es una plataforma de "IO" (Input/Output). 
      // Si NO es Android, iOS, Linux, o Windows, asumimos que es Web/Desktop
      if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows) {
        shouldForceReload = false; // Móvil/Desktop con DB local
      } else {
        shouldForceReload = true; // Web o plataforma sin soporte DB
      }

    // 3. Carga inicial de datos (false para usar caché si es reciente)
    _cargarDatosAsistencia(forceReload: shouldForceReload);
    
    // 4. Iniciar el temporizador de auto-refresco
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    debugPrint(
      'AsistenciaScreen: dispose - Cancelando temporizador y removiendo listeners.',
    );
    _autoRefreshTimer?.cancel();
    // 5. Remover listener del Provider
    // ignore: invalid_use_of_protected_member
    if (mounted && _userProvider.autoRefreshTrigger.hasListeners) {
      _userProvider.autoRefreshTrigger.removeListener(_autoRefreshListener);
    }
    super.dispose();
  }

  // ✅ MÉTODO: Iniciar el temporizador de recarga automática
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: ApiConstants.minutosRecarga),
      (timer) {
        debugPrint(
          'AsistenciaScreen: Disparando auto-refresco por temporizador (${ApiConstants.minutosRecarga} minutos).',
        );
        // Llamamos con forceReload: false para que la lógica del Provider decida si la caché expiró
        _cargarDatosAsistencia(forceReload: false); 
      },
    );
  }

  // ✅ MÉTODO: Mostrar SnackBar
  void _showSnackBar(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }


  // ⭐️ MÉTODO CLAVE: Carga principal de datos (recarga materias/clubes) ⭐️
  Future<void> _cargarDatosAsistencia({bool forceReload = false}) async {
    debugPrint(
      'AsistenciaScreen: _cargarDatosAsistencia llamado (forceReload: $forceReload).',
    );

    // Validación de datos de sesión
    if (_userProvider.idColaborador.isEmpty) { 
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: Datos de colaborador incompletos.';
          _isLoading = false;
        });
      }
      _showSnackBar(
        'Error: Datos de sesión no disponibles.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Ponemos isLoading a true y limpiamos errores ANTES de la llamada a la API
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }


    try {
      // 🚨 LLAMADA CLAVE: Recarga los datos del colaborador (que incluyen materias y clubes)
      await _userProvider.fetchAndLoadColaboradorData(forceRefresh: forceReload);

      if (!mounted) {
        debugPrint('AsistenciaScreen: Widget no montado después de la carga.');
        return;
      }

      // El provider notifica a los listeners (que es el método build())
      debugPrint(
        'AsistenciaScreen: Datos de materias/clubes cargados. Materias: ${_userProvider.colaboradorMaterias.length}, Clubes: ${_userProvider.colaboradorClubes.length}',
      );
    } on SocketException {
      if (mounted) {
        setState(() {
          _errorMessage = 'No hay conexión a internet. Mostrando datos cacheados.';
        });
      }
      _showSnackBar(
        'Sin conexión a internet. Mostrando datos cacheados.',
        backgroundColor: Colors.orange,
      );
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error al cargar datos: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
      // Mostrar SnackBar solo para errores no relacionados con la falta de conexión
      if (_errorMessage != 'No hay conexión a internet. Mostrando datos cacheados.') {
         _showSnackBar(_errorMessage!, backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        // Ponemos isLoading a false AL FINAL
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  bool get wantKeepAlive => true; // ✅ Mantiene el estado de la pantalla

  @override
  Widget build(BuildContext context) {
    super.build(context); 
    
    // Obtener el provider para el build
    final userProvider = Provider.of<UserProvider>(context);
    
    final Color headerColor = userProvider.colores.headerColor;

    if (userProvider.colaboradorModel == null && !_isLoading && _errorMessage == null) {
      // Si el modelo es nulo, no está cargando, y no hay error, mostramos el indicador inicial.
      return Scaffold(
        appBar: AppBar(title: const Text('Calificaciones y Asistencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones y Asistencia',  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: headerColor, 
        centerTitle: true,
      ),
      // ✅ IMPLEMENTACIÓN DEL REFRESH INDICATOR
      body: RefreshIndicator(
        onRefresh: () async {
            // 1. Control de tiempo entre refrescos (1 minuto de espera)
            final now = DateTime.now();
            if (_lastManualRefreshTime != null &&
                now.difference(_lastManualRefreshTime!).inSeconds < 60) {
              debugPrint('AsistenciaScreen: Intento de recarga manual demasiado pronto.');
              _showSnackBar('Datos actualizados', backgroundColor: Colors.green);
              return;
            }

            debugPrint('AsistenciaScreen: RefreshIndicator activado. Iniciando recarga forzada.');
            _showSnackBar(
              'Recargando datos...',
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.grey,
            );

            _lastManualRefreshTime = now; // Actualizar marca de tiempo antes de la recarga

            // 2. Llamada a la recarga forzada
            await _cargarDatosAsistencia(forceReload: true);

            // 3. Mostrar mensaje de éxito si no hay error
            if (_errorMessage == null) {
              _showSnackBar(
                'Datos actualizados.',
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              );
            }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading && _errorMessage == null && userProvider.colaboradorModel == null
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildErrorWidget() // Mostrar error
                  : Column( // Contenido principal
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
      ),
    );
  }
  
  // ✅ WIDGET: Para mostrar errores y dar opción de refresh
  Widget _buildErrorWidget() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              Text(
                // Mensaje informativo sobre cómo reintentar
                'Error al cargar datos: $_errorMessage\n\nArrastra hacia abajo para reintentar la conexión.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
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
        required Color headerColor 
      }) {
    final bool isSelected = _selectedOption == value;
    return Expanded(
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: isSelected
              ?  BorderSide(color: headerColor , width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () {
            if (mounted) {
              setState(() {
                _selectedOption = value;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
            child: Column(
              children: [
                Icon(icon, size: 40, color: isSelected ? headerColor : Colors.grey),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
    final Color headerColor = userProvider.colores.headerColor; 
    
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

        final bool isPreescolar = isMateria && materia!.planEstudio == 'Preescolar';

        if (!isMateria) {
            return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                    title: Text(title),
                    subtitle: Text(subtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white,),
                    onTap: () {
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
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white,),
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
              /*ListTile(
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
              ),*/
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
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white,),
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
      );
  }
}