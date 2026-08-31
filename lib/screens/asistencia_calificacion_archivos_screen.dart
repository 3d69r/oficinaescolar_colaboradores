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
import 'package:oficinaescolar_colaboradores/utils/log_util.dart';
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
  
  // ⭐️ NUEVAS VARIABLES: BANDERAS DE PERMISO ⭐️
  bool _puedeVerSalones = false; // Mapea a 'califica'
  bool _puedeVerClubes = false;  // Mapea a 'asis_clubes'


  @override
  void initState() {
    super.initState();
    appLog(
      'AsistenciaCalificacionArchivoScreen: initState - Inicializando pantalla de archivos/clubes.',
    );
    
    // ⭐️ CORRECCIÓN CLAVE: Inicialización inmediata de _userProvider
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // ⭐️ LÓGICA DE PERMISOS: Extracción y asignación ⭐️
    // ⭐️ LÓGICA DE PERMISOS: Extracción y asignación ⭐️
    final String permisos = _userProvider.colaboradorModel?.appPermisosColabDet ?? '';
    appLog('DEBUG PERMISOS COLAB DET: appPermisosColabDet crudo = "$permisos"'); // ⭐️ NUEVO LOG
    final List<String> listaPermisos = permisos.split(',').map((e) => e.trim()).toList();
    appLog('DEBUG PERMISOS COLAB DET: lista parseada = $listaPermisos'); // ⭐️ NUEVO LOG
    
    _puedeVerSalones = listaPermisos.contains('califica');
    _puedeVerClubes = listaPermisos.contains('asis_clubes');

    // ⭐️ INICIALIZACIÓN DINÁMICA DE _selectedOption ⭐️
    if (_puedeVerSalones) {
        _selectedOption = 'salon'; // Si puede calificar, inicia en Salones
    } else if (_puedeVerClubes) {
        _selectedOption = 'clubes'; // Si solo puede asistir, inicia en Clubes
    } else {
        _selectedOption = null; // No tiene permisos para ninguna sección
    }
    
    // 1. Configuración del listener de auto-refresco del UserProvider
    _autoRefreshListener = () {
      appLog(
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
    appLog(
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
        appLog(
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
    appLog(
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
        appLog('AsistenciaCalificacionArchivoScreen: Widget no montado después de la carga.');
        return;
      }

      appLog(
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
        title: const Text(
          'Archivos y Clubes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: headerColor, 
        centerTitle: true,
      ),

      // ✅ IMPLEMENTACIÓN DEL REFRESH INDICATOR
      body: RefreshIndicator(
        onRefresh: () async {
          final now = DateTime.now();

          if (_lastManualRefreshTime != null &&
              now.difference(_lastManualRefreshTime!).inSeconds < 60) {
            _showSnackBar(
              'Datos actualizados',
              backgroundColor: Colors.green,
            );
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

        // ⭐️ FIX: MISMA ESTRUCTURA DE SCROLL QUE ASISTENCIAS
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child:
                    _isLoading &&
                            _errorMessage == null &&
                            userProvider.colaboradorModel == null
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : _errorMessage != null
                            ? _buildErrorWidget()
                            : (_puedeVerSalones || _puedeVerClubes)
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Selecciona la opcion deseada:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          // ⭐️ BOTÓN CONDICIONAL: Salones
                                          if (_puedeVerSalones)
                                            _construirBotonOpcion(
                                              context,
                                              title: 'Salones',
                                              icon: Icons.class_,
                                              value: 'salon',
                                              headerColor: headerColor,
                                            ),

                                          // ⭐️ BOTÓN CONDICIONAL: Clubes
                                          if (_puedeVerClubes)
                                            _construirBotonOpcion(
                                              context,
                                              title: 'Clubes',
                                              icon: Icons.sports_soccer,
                                              value: 'clubes',
                                              headerColor: headerColor,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 30),

                                      if (_selectedOption != null) ...[
                                        Text(
                                          _selectedOption == 'salon'
                                              ? 'Salones asignados:'
                                              : 'Clubes asignados:',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        const SizedBox(height: 20),

                                        // ⭐️ FIX:
                                        // Ya no usamos Expanded porque
                                        // el scroll principal es el
                                        // SingleChildScrollView.
                                        _selectedOption == 'salon'
                                            ? _construirListaSalones(
                                                userProvider,
                                              )
                                            : _construirListaClubes(
                                                userProvider,
                                              ),
                                      ],
                                    ],
                                  )
                                : Center(
                                    child: Text(
                                      'No tienes permisos de Asistencia o Calificación asignados.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
              ),
            );
          },
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
          // ⭐️ FIX: El scroll lo maneja el SingleChildScrollView
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                          // ⭐️ NUEVO: Mostrar modal de selección de parcial antes de navegar
                          _mostrarModalParciales(salon, alumnos, headerColor);
                      },
                  ),
              );
          },
      );
  }

    // ⭐️ NUEVO MÉTODO: Modal para elegir la parcial antes de entrar al listado de alumnos ⭐️
  // ⭐️ MÉTODO MEJORADO: Modal para elegir la parcial con diseño de botones y contador ⭐️
  void _mostrarModalParciales(
    String salon,
    List<AlumnoSalonModel> alumnos,
    Color headerColor,
  ) {
    final List<String> camposArchivo =
        alumnos.isNotEmpty ? alumnos.first.archivosCalificacion.keys.toList() : [];

    final int totalAlumnos = alumnos.length;

    String formatearCampo(String campo) {
      return campo
          .replaceAll('archivo_calif_', 'Archivo ')
          .replaceAll('_', ' ')
          .trim();
    }

    // ⭐️ NUEVO: Cuenta cuántos alumnos ya tienen archivo subido para un campo dado
    int contarSubidos(String campo) {
      return alumnos
          .where((a) => (a.archivosCalificacion[campo] ?? '').isNotEmpty)
          .length;
    }

    void navegar(String? campoFiltro) {
      Navigator.of(context).pop(); // cierra el modal
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArchivosCalificacionesScreen(
            salonSeleccionado: salon,
            alumnosSalon: alumnos,
            campoArchivoFiltro: campoFiltro,
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  color: headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      salon,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Selecciona la parcial',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // ⭐️ Botones por parcial
                    ...camposArchivo.map((campo) {
                      final int subidos = contarSubidos(campo);
                      final bool completo = totalAlumnos > 0 && subidos == totalAlumnos;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: completo
                              ? Colors.green.shade50
                              : headerColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => navegar(campo),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: completo
                                      ? Colors.green
                                      : headerColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    color: completo ? Colors.green : headerColor,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      formatearCampo(campo),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: completo
                                            ? Colors.green.shade800
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  // ⭐️ Contador X/Y
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: completo
                                          ? Colors.green
                                          : headerColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$subidos/$totalAlumnos',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (completo) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right,
                                    color: completo ? Colors.green : headerColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const Divider(height: 20),

                    // ⭐️ Botón "Todas las parciales"
                    Material(
                      color: headerColor,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => navegar(null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.select_all, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Todas las parciales',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
  // -------------------------------------------------------------
  // ✅ MÉTODOS Y WIDGETS AUXILIARES (Ajustados)
  // -------------------------------------------------
  
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

  // ✅ Método: Construir lista de clubes
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
      // ⭐️ FIX: El scroll lo maneja el SingleChildScrollView
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: headerColor,
                ),
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
}

