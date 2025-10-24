// asistencia_calificacion_archivo_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';

// ⭐️ IMPORTACIONES NECESARIAS ⭐️
import 'package:oficinaescolar_colaboradores/config/api_constants.dart'; 
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/providers/tipo_curso.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 
// 👈 NUEVAS IMPORTACIONES REQUERIDAS
import 'package:oficinaescolar_colaboradores/models/alumno_salon_model.dart'; 
import 'package:oficinaescolar_colaboradores/screens/archivos_calificaciones_screen.dart';
// ------------------------------------
import 'package:oficinaescolar_colaboradores/screens/lista_screen.dart';
// import 'package:oficinaescolar_colaboradores/screens/captura_calificaciones_screen.dart'; // Ya no se usa

class AsistenciaCalificacionArchivoScreen extends StatefulWidget {
  const AsistenciaCalificacionArchivoScreen({super.key});

  @override
  State<AsistenciaCalificacionArchivoScreen> createState() => _AsistenciaCalificacionArchivoScreenState();
}

class _AsistenciaCalificacionArchivoScreenState extends State<AsistenciaCalificacionArchivoScreen>
    with AutomaticKeepAliveClientMixin { 

  // Estado para controlar la opción seleccionada (null, 'salon' o 'clubes')
  // ⚠️ Cambiado de 'materia' a 'salon'
  String? _selectedOption; 
  
  //  VARIABLES DE GESTIÓN DE RECARGA 
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
      'AsistenciaCalificacionArchivoScreen: initState - Inicializando pantalla de archivos/clubes.',
    );
    
    // ⭐️ CORRECCIÓN CLAVE: Inicialización inmediata de _userProvider
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _selectedOption = 'salon'; // ⭐️ INICIALIZAR EN 'SALONES' POR DEFECTO ⭐️

    // 1. Configuración del listener de auto-refresco del UserProvider
    _autoRefreshListener = () {
      debugPrint(
        'AsistenciaCalificacionArchivoScreen: Gatillo de auto-refresco del UserProvider detectado. Recargando datos...',
      );
      _cargarDatosAsistencia(forceReload: true);
    };

    // 2. Adjuntar el listener
    _userProvider.autoRefreshTrigger.addListener(_autoRefreshListener);

     bool shouldForceReload = false;
      
     if (kIsWeb) {
        shouldForceReload = true; 
     } else {
        shouldForceReload = false; 
     }

    // 3. Carga inicial de datos
    _cargarDatosAsistencia(forceReload: shouldForceReload);
    
    // 4. Iniciar el temporizador de auto-refresco
    _startAutoRefreshTimer();
  }

  @override
  void dispose() {
    debugPrint(
      'AsistenciaCalificacionArchivoScreen: dispose - Cancelando temporizador y removiendo listeners.',
    );
    _autoRefreshTimer?.cancel();
    // 5. Remover listener del Provider
    // ignore: invalid_use_of_protected_member
    if (mounted && _userProvider.autoRefreshTrigger.hasListeners) {
      _userProvider.autoRefreshTrigger.removeListener(_autoRefreshListener);
    }
    super.dispose();
  }

  // ✅ MÉTODO: Iniciar el temporizador de recarga automática (Sin Cambios)
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: ApiConstants.minutosRecarga),
      (timer) {
        debugPrint(
          'AsistenciaCalificacionArchivoScreen: Disparando auto-refresco por temporizador (${ApiConstants.minutosRecarga} minutos).',
        );
        _cargarDatosAsistencia(forceReload: false); 
      },
    );
  }

  // ✅ MÉTODO: Mostrar SnackBar (Sin Cambios)
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


  // ⭐️ MÉTODO CLAVE: Carga principal de datos (recarga materias/clubes) ⭐️ (Sin Cambios)
  Future<void> _cargarDatosAsistencia({bool forceReload = false}) async {
    debugPrint(
      'AsistenciaCalificacionArchivoScreen: _cargarDatosAsistencia llamado (forceReload: $forceReload).',
    );

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

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      await _userProvider.fetchAndLoadColaboradorData(forceRefresh: forceReload);

      if (!mounted) {
        debugPrint('AsistenciaCalificacionArchivoScreen: Widget no montado después de la carga.');
        return;
      }

      debugPrint(
        'AsistenciaCalificacionArchivoScreen: Datos de materias/clubes cargados. Materias: ${_userProvider.colaboradorMaterias.length}, Clubes: ${_userProvider.colaboradorClubes.length}',
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
      if (_errorMessage != 'No hay conexión a internet. Mostrando datos cacheados.') {
         _showSnackBar(_errorMessage!, backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
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
    
    final userProvider = Provider.of<UserProvider>(context);
    final Color headerColor = userProvider.colores.headerColor;

    if (userProvider.colaboradorModel == null && !_isLoading && _errorMessage == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calificaciones y Asistencia')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivos y Clubes',  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // ⭐️ TÍTULO MODIFICADO ⭐️
        backgroundColor: headerColor, 
        centerTitle: true,
      ),
      // ✅ IMPLEMENTACIÓN DEL REFRESH INDICATOR
      body: RefreshIndicator(
        onRefresh: () async {
            final now = DateTime.now();
            if (_lastManualRefreshTime != null &&
                now.difference(_lastManualRefreshTime!).inSeconds < 60) {
              _showSnackBar('Datos actualizados', backgroundColor: Colors.green);
              return;
            }

            _showSnackBar(
              'Recargando datos...',
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.grey,
            );

            _lastManualRefreshTime = now; 

            await _cargarDatosAsistencia(forceReload: true);

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
                            // ⭐️ BOTÓN MODIFICADO: Materia -> Salón ⭐️
                            _construirBotonOpcion(
                              context,
                              title: 'Salones',
                              icon: Icons.class_, // ⭐️ ICONO MODIFICADO ⭐️
                              value: 'salon', // ⭐️ VALOR MODIFICADO ⭐️
                              headerColor: headerColor
                            ),
                            _construirBotonOpcion( // Botón Clubes (sin cambios)
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
                            _selectedOption == 'salon' ? 'Salones asignados:' : 'Clubes asignados:', // ⭐️ ETIQUETA MODIFICADA ⭐️
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            // ⭐️ MÉTODO MODIFICADO: Redirigimos a la lista correcta ⭐️
                            child: _selectedOption == 'salon' 
                                ? _construirListaSalones(userProvider)
                                : _construirListaClubes(userProvider), // Mantenemos lista de clubes
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }
  
  // -------------------------------------------------------------
  // ⭐️ NUEVOS WIDGETS Y MÉTODOS PARA FLUJO SALONES ⭐️
  // -------------------------------------------------------------

  // ⭐️ NUEVO MÉTODO: Construir la lista de Salones Agrupados ⭐️
  Widget _construirListaSalones(UserProvider userProvider) {
      final Color headerColor = userProvider.colores.headerColor; 
      // Consumimos el getter del Provider que agrupa los datos
      final Map<String, List<AlumnoSalonModel>> salonesAgrupados = userProvider.groupedAlumnosBySalon;
      final List<String> salonNombres = salonesAgrupados.keys.toList();

      if (_isLoading && _errorMessage == null) {
          return const Center(child: CircularProgressIndicator());
      }

      if (_errorMessage != null) {
          return _buildErrorWidget();
      }

      if (salonNombres.isEmpty) {
          return Center(
              child: Text(
                  'No tienes salones asignados para subir archivos de calificación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
          );
      }

      return ListView.builder(
          itemCount: salonNombres.length,
          itemBuilder: (context, index) {
              final salon = salonNombres[index];
              final List<AlumnoSalonModel> alumnos = salonesAgrupados[salon]!;

              // Determinamos el nivel educativo para el subtítulo (asumimos el mismo nivel)
              final String nivel = alumnos.isNotEmpty ? alumnos.first.nivelEducativo : 'N/A';

              return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                      title: Text(salon),
                      subtitle: Text('${alumnos.length} alumnos - Nivel: $nivel'),
                      leading: Icon(Icons.class_, color: headerColor),
                      trailing: Icon(Icons.arrow_forward_ios, color: headerColor),
                      onTap: () {
                          // ⭐️ NAVEGAR A LA VISTA DE SUBIDA DE ARCHIVOS POR SALÓN ⭐️
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ArchivosCalificacionesScreen(
                                      salonSeleccionado: salon,
                                      alumnosSalon: alumnos,
                                  ),
                              ),
                          );
                      },
                  ),
              );
          },
      );
  }
  
  // -------------------------------------------------------------
  // ✅ MÉTODOS Y WIDGETS AUXILIARES (Ajustados)
  // -------------------------------------------------------------
  
  // ✅ WIDGET: Para mostrar errores (Sin Cambios)
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


  // ✅ MÉTODO: Construir botón de opción (Salones/Clubes) (Sin Cambios en la lógica del botón, solo en el valor 'salon')
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

  // ✅ MÉTODO: Construir lista de clubes (Extraído del método original _construirListaCursos)
  Widget _construirListaClubes(UserProvider userProvider) { 
    final Color headerColor = userProvider.colores.headerColor; 
    final List items = userProvider.colaboradorClubes;

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No tienes clubes asignados para este ciclo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final ClubModel club = items[index] as ClubModel;
        
        final String title = club.nombreCurso; 
        final String subtitle = 'Horario: ${club.horario}';

        return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
                title: Text(title),
                subtitle: Text(subtitle),
                trailing: Icon(Icons.arrow_forward_ios, color: headerColor), // Usar headerColor
                onTap: () {
                    Navigator.push(
                        context, 
                        MaterialPageRoute(
                            builder: (_) => ListaScreen(
                                idCurso: club.idCurso, 
                                tipoCurso: TipoCurso.club,
                            ),
                        ),
                    );
                },
            ),
        );
      },
    );
  }

  // ⚠️ Los métodos _construirListaCursos, _buildPreescolarExpansionTile y _buildGeneralMateriaTile 
  // del archivo original ya NO se usan ni son necesarios en esta nueva vista.
}