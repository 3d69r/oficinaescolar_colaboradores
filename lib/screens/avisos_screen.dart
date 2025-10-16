import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:io'; // Se mantiene por si hay otros usos, aunque la llamada API se mueva
import 'package:flutter_html/flutter_html.dart';
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:provider/provider.dart';
//import 'package:intl/date_symbol_data_local.dart'; // ¡Nueva importación necesaria!
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Importa tus constantes de API y tu provider
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/aviso_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Clase [AvisosView]
///
/// Muestra una lista de avisos para el usuario, permitiendo filtrar por estado
/// de lectura y fecha. Los avisos se cargan desde el [UserProvider], que gestiona
/// la caché local y las llamadas a la API. El estado de "leído" ahora se gestiona
/// completamente por el [UserProvider] y la base de datos local.

class AvisosView extends StatefulWidget {
  /// Constructor para [AvisosView].
  ///
  /// Recibe un [key] opcional para identificar este widget en el árbol de widgets.
  const AvisosView({super.key});

  @override
  /// Crea y retorna el estado mutable para este [StatefulWidget].
  ///
  /// La instancia de [_AvisosViewState] asociada a este widget.
  State<AvisosView> createState() => _AvisosViewState();
}

/// La clase de estado para [AvisosView].
///
/// Contiene el estado mutable y la lógica de negocio para la pantalla de avisos.
/// Incluye [AutomaticKeepAliveClientMixin] para mantener el estado de la vista
/// (ej. posición de scroll) cuando la vista no está activa pero sigue en memoria
/// (por ejemplo, dentro de un [TabBarView]).
class _AvisosViewState extends State<AvisosView>
    with AutomaticKeepAliveClientMixin {
  // ELIMINADO: static const String _kReadAvisosKey = 'readAvisosCalendarIds';
  // ELIMINADO: Set<String> _readAvisosIds = {};

  // Propiedades del estado que controlan la UI y los datos.
  // No es necesario mantener una copia separada de los avisos aquí,
  // se accederá directamente a la lista en [_userProvider].
  // List<AvisoModel> avisos = []; // Se usará directamente _userProvider.avisos

  /// Filtro actual para el estado de lectura de los avisos ('Todos', 'Leídos', 'No leídos').
  String filtroLectura = 'Todos';

  /// Fecha seleccionada para filtrar los avisos. Si es `null`, no hay filtro de fecha.
  DateTime? fechaFiltro;

  DateTime? _lastManualRefreshTime;

  /// Bandera que indica si la vista está en su carga inicial de datos.
  /// Se usa para mostrar un indicador de carga solo al principio.
  bool _isInitialLoading = true;

  /// Mensaje de error a mostrar si falla la carga de avisos. Es `null` si no hay error.
  String? _errorMessage;

  String?
  _selectedOption; // Nuevo: Almacena la opción seleccionada en el formulario

  /// Referencia a la instancia de [UserProvider].
  /// Se inicializa en [initState] y se utiliza para acceder a los datos y la lógica de avisos.
  late UserProvider _userProvider;
  

  // [NUEVO] Referencia al UserProvider y a los colores dinámicos
  late UserProvider userProvider;
  late Colores colores;

  /// Temporizador para el auto-refresco periódico de los avisos.
  /// Se usa para recargar los avisos cada cierto intervalo.
  Timer? _autoRefreshTimer;

  @override
  /// Se llama una vez cuando el objeto [State] se inserta en el árbol de widgets.
  ///
  /// Se utiliza para la inicialización de datos y configuración de listeners o timers.
  void initState() {
    super.initState();
    debugPrint('AvisosView: initState - Inicializando pantalla de avisos.');
    //initializeDateFormatting('es_ES', null);
    // Asegura que las operaciones que dependen del 'context' se ejecuten después de que el widget esté completamente montado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Obtiene la instancia de UserProvider. 'listen: false' previene reconstrucciones innecesarias en este punto.
      _userProvider = Provider.of<UserProvider>(context, listen: false);

      // 💡 [CORRECCIÓN ALTERNATIVA]: Usar condicionales de compilación de Dart.
      bool shouldForceReload = false;
      
      // La web no es una plataforma de "IO" (Input/Output). 
      // Si NO es Android, iOS, Linux, o Windows, asumimos que es Web/Desktop
      if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows) {
        shouldForceReload = false; // Móvil/Desktop con DB local
      } else {
        shouldForceReload = true; // Web o plataforma sin soporte DB
      }

      // Realiza la carga inicial de avisos. No fuerza la recarga desde la API si ya hay datos en caché.
      _loadAvisos(forceReload: shouldForceReload);
      //initializeDateFormatting('es_ES', null);

      // Inicia el temporizador para auto-refrescar los avisos periódicamente.
      _startAutoRefreshTimer();
    });
  }

  

  @override
  /// Se llama cuando este objeto [State] se elimina permanentemente del árbol de widgets.
  ///
  /// Se utiliza para liberar recursos y cancelar suscripciones (como temporizadores).
  void dispose() {
    debugPrint(
      'AvisosView: dispose - Cancelando temporizador de auto-refresco y removiendo listeners.',
    );
    // Cancela el temporizador para evitar fugas de memoria.
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// Inicia un temporizador que dispara la recarga de avisos periódicamente.
  ///
  /// El temporizador se cancela antes de iniciar uno nuevo para evitar múltiples instancias.
  /// La frecuencia de recarga se define en [ApiConstants.minutosRecarga].
  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel(); // Cancela cualquier temporizador existente.
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: ApiConstants.minutosRecarga),
      (timer) {
        debugPrint(
          'AvisosView: Disparando auto-refresco por temporizador (${ApiConstants.minutosRecarga} minutos).',
        );
        // Fuerza una recarga completa de los avisos desde la API.
        _loadAvisos(forceReload: true);
      },
    );
  }
  // Método auxiliar para obtener el IconData desde una cadena 'fa-'
  IconData _getIconFromFa(String? faIconName) {
    final normalizedName = faIconName;
  
  if (normalizedName == null || normalizedName.isEmpty) {
    return Icons.comment; // Devuelve la campana si no hay icono
  }

    switch (faIconName) {
      case 'Todos':
        return FontAwesomeIcons.bell;
      case 'AlumnosNivelEdu':
        return FontAwesomeIcons.building;
      case 'AlumnosSalon':
        return FontAwesomeIcons.book;
      case 'AlumnoEspecifico':
        return FontAwesomeIcons.user;
      default:
        return Icons.comment; // Icono por defecto si no se encuentra el nombre
    }
  }

  /// Muestra un [SnackBar] en la parte inferior de la pantalla para notificar al usuario.
  ///
  /// [message]: El texto a mostrar en el SnackBar.
  /// [backgroundColor]: El color de fondo del SnackBar (rojo por defecto para errores).
  /// [duration]: La duración que el SnackBar estará visible (4 segundos por defecto).
  void _showSnackBar(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Solo muestra el SnackBar si el widget todavía está montado.
    if (!mounted) return;
    // Oculta cualquier SnackBar anterior para evitar que se solapen.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior:
            SnackBarBehavior
                .floating, // Hace que el SnackBar flote sobre el contenido.
        duration: duration,
      ),
    );
  }

  // ELIMINADO: _getReadAvisosIds() ya no es necesario aquí. (Comentario mantenido para referencia de la eliminación)

  /// Carga los datos de avisos desde el [UserProvider].
  ///
  /// Este método se encarga de iniciar el proceso de obtención de avisos,
  /// ya sea desde la caché local o desde la API, y de manejar los posibles errores.
  /// El estado de "leído" de cada aviso ya es gestionado por el [UserProvider].
  ///
  /// [forceReload]: Si es `true`, fuerza la recarga de avisos desde la API,
  ///                ignorando la caché.
  Future<void> _loadAvisos({bool forceReload = false}) async {
    // Limpia cualquier mensaje de error previo al iniciar una nueva carga.
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      // Solicita al UserProvider que obtenga y cargue los datos de avisos.
      // El provider se encarga de la lógica de caché y de fusionar el estado 'leido'.
      await _userProvider.fetchAndLoadAvisosData(forceRefresh: forceReload);

      // Si el widget se desmonta mientras la operación asíncrona está en curso, salir.
      if (!mounted) {
        debugPrint(
          'AvisosView: _loadAvisos - Widget no montado después de la carga de avisos del provider.',
        );
        return;
      }

      setState(() {
        // La lista 'avisos' en el UserProvider ya contiene el estado 'leido' correcto.
        // No es necesario mapear ni actualizar el estado 'leido' aquí.
        _errorMessage =
            null; // Confirma que no hay error si la carga fue exitosa.
      });
      debugPrint(
        'AvisosView: Avisos cargados desde UserProvider: ${_userProvider.avisos.length} avisos.',
      );
    } catch (e) {
      // Manejo de errores durante la carga de avisos.
      if (!mounted) {
        debugPrint(
          'AvisosView: _loadAvisos - Widget no montado durante manejo de excepción.',
        );
        return;
      }
      setState(() {
        // Formatea el mensaje de error para que sea más legible para el usuario.
        _errorMessage =
            'Error al cargar avisos: ${e.toString().replaceFirst('Exception: ', '')}';
        // Si hay un error, la lista de avisos se gestiona por el provider, no se vacía aquí.
      });
      debugPrint('AvisosView: Excepción al cargar avisos: $e');
      // Muestra un SnackBar con el mensaje de error.
      _showSnackBar(_errorMessage!, backgroundColor: Colors.red);
    } finally {
      // Este bloque se ejecuta siempre, haya o no una excepción.
      // Desactiva la bandera de carga inicial una vez que el proceso de carga ha finalizado.
      // Esto previene que el indicador de carga inicial se muestre en pull-to-refresh.
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }
  

  /// Muestra un diálogo ([Dialog]) con los detalles completos de un [AvisoModel].
  ///
  /// Si el aviso no ha sido leído previamente, lo marca como leído a través del [UserProvider].
  ///
  /// [aviso]: El [AvisoModel] cuyos detalles se mostrarán.
  /// Muestra un diálogo ([Dialog]) con los detalles completos de un [AvisoModel].
  ///
  /// Si el aviso no ha sido leído previamente, lo marca como leído a través del [UserProvider].
  ///
  /// [aviso]: El [AvisoModel] cuyos detalles se mostrarán.
// Tu método _mostrarAviso modificado
void _mostrarAviso(AvisoModel aviso) {
  // Si el aviso no ha sido leído, lo marca como leído.
  if (!aviso.leido) {
    _userProvider.markAvisoAsRead(aviso.idCalendario);
  }

  _selectedOption = null;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final dialogWidth = screenWidth * 0.90;
      final dialogHeight = screenHeight * 0.95;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final colores = userProvider.colores;
      final List<String> opciones =
          [aviso.opcion1, aviso.opcion2, aviso.opcion3, aviso.opcion4, aviso.opcion5]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .toList();

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        backgroundColor: Colors.white,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: dialogWidth,
            maxWidth: dialogWidth,
            minHeight: dialogHeight,
            maxHeight: dialogHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Encabezado ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: colores.headerColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Text(
                  aviso.titulo,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // --- Contenido scrollable dentro de Expanded ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE d \'de\' MMMM \'del\' yyyy', 'es_ES').format(aviso.fecha),
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(height: 5),
                      const Divider(color: Colors.grey, thickness: 0.5),
                      const SizedBox(height: 10),
                      CustomPaint(
                        size: Size(dialogWidth * 0.6, 5),
                        painter: _SharpLinePainter(),
                      ),
                      CustomPaint(
                        size: Size(dialogWidth * 0.6, 5),
                        painter: _SharpLinePainter(),
                      ),

                      // Contenido del aviso: imagen, PDF o texto
                      if (aviso.archivo != null && aviso.archivo!.isNotEmpty)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: FutureBuilder<String?>(
                              future: userProvider.getAvisoImagePath(aviso),
                              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                if (!snapshot.hasData || snapshot.data == null) {
                                  return SingleChildScrollView(
                                    child: Html(data: aviso.comentario),
                                  );
                                }
                                
                                final String filePath = snapshot.data!;
                                final String extension = filePath.split('.').last.toLowerCase();

                                // Lógica de visualización: PDF o imagen
                                if (extension == 'pdf') {
                                  // **[MODIFICACIÓN]** Usamos el widget de Syncfusion
                                  return SfPdfViewer.file(File(filePath));
                                } else if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
                                  return InteractiveViewer(
                                    panEnabled: true,
                                    minScale: 1.0,
                                    maxScale: 4.0,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Image.file(
                                        File(filePath),
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Text('No se pudo cargar la imagen.', textAlign: TextAlign.center);
                                        },
                                      ),
                                    ),
                                  );
                                } else {
                                  return SingleChildScrollView(
                                    child: Html(data: aviso.comentario),
                                  );
                                }
                              },
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Html(data: aviso.comentario),
                            ),
                          ),
                        ),
                      
                      // --- Formulario de respuesta condicional ---
                      if (aviso.tipoRespuesta != null &&
                          (aviso.tipoRespuesta!.toLowerCase() == 'siono' ||
                              aviso.tipoRespuesta!.toLowerCase() == 'seleccion'))
                        StatefulBuilder(
                          builder: (BuildContext context, StateSetter setStateForm) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Por favor, responde a este aviso:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 10),
                                  if (aviso.tipoRespuesta!.toLowerCase() == 'siono')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: aviso.segRespuesta != null && aviso.segRespuesta!.isNotEmpty
                                              ? null
                                              : () {
                                                  setStateForm(() {
                                                    _selectedOption = 'Sí';
                                                  });
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _selectedOption == 'Sí' ? colores.botonesColor : Colors.grey.shade200,
                                            foregroundColor: _selectedOption == 'Sí' ? Colors.white : Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Sí'),
                                        ),
                                        ElevatedButton(
                                          onPressed: aviso.segRespuesta != null && aviso.segRespuesta!.isNotEmpty
                                              ? null
                                              : () {
                                                  setStateForm(() {
                                                    _selectedOption = 'No';
                                                  });
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _selectedOption == 'No' ? colores.botonesColor : Colors.grey.shade200,
                                            foregroundColor: _selectedOption == 'No' ? Colors.white : Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: const Text('No'),
                                        ),
                                      ],
                                    )
                                  else if (aviso.tipoRespuesta!.toLowerCase() == 'seleccion')
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: opciones.map((opcion) {
                                        return RadioListTile<String>(
                                          title: Text(opcion),
                                          value: opcion,
                                          groupValue: aviso.segRespuesta != null && aviso.segRespuesta!.isNotEmpty
                                              ? aviso.segRespuesta
                                              : _selectedOption,
                                          onChanged: aviso.segRespuesta != null && aviso.segRespuesta!.isNotEmpty
                                              ? null
                                              : (String? value) {
                                                  setStateForm(() {
                                                    _selectedOption = value;
                                                  });
                                                },
                                          activeColor: colores.botonesColor,
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 15),
                                  if (aviso.segRespuesta == null || aviso.segRespuesta!.isEmpty)
                                    ElevatedButton(
                                      onPressed: _selectedOption != null
                                          ? () async {
                                              if (_selectedOption != null) {
                                                await _userProvider.markAvisoAsRead(
                                                  aviso.idCalendario,
                                                  respuesta: _selectedOption,
                                                );
                                                if (mounted) Navigator.of(context).pop();
                                              }
                                            }
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colores.botonesColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                                      ),
                                      child: const Text('Enviar Respuesta'),
                                    )
                                  else
                                    Text(
                                      'Ya has respondido este aviso: "${aviso.segRespuesta}"',
                                      style: TextStyle(
                                        color: colores.botonesColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // --- Botón "Cerrar" al fondo del modal ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colores.botonesColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    ),
                    child: const Text('Cerrar', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  /// Función auxiliar para eliminar etiquetas HTML y truncar el texto si es necesario.
  ///
  /// [htmlString]: La cadena de texto que puede contener etiquetas HTML.
  /// [maxLength]: La longitud máxima deseada para el texto resultante.
  ///
  /// Retorna una cadena de texto sin HTML y posiblemente truncada.
  String _stripHtmlIfNeeded(String htmlString, {int maxLength = 80}) {
    // Expresión regular para encontrar etiquetas HTML.
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    // Elimina todas las etiquetas HTML.
    String plainText = htmlString.replaceAll(exp, '');
    // Reemplaza entidades HTML comunes como '&nbsp;' por un espacio.
    plainText = plainText.replaceAll('&nbsp;', ' ');
    // Elimina espacios en blanco al inicio y al final.
    plainText =
        plainText
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(); // Elimina múltiples espacios y recorta
    // Si el texto excede la longitud máxima, lo trunca y añade puntos suspensivos.
    if (plainText.length > maxLength) {
      return '${plainText.substring(0, maxLength)}...';
    }
    return plainText;
  }

  /// Getter que retorna una lista de [AvisoModel] filtrados y ordenados.
  ///
  /// Los avisos se obtienen directamente de [_userProvider.avisos].
  /// El ordenamiento se realiza de la siguiente manera:
  /// 1. Avisos no leídos aparecen primero.
  /// 2. Avisos leídos aparecen después.
  /// 3. Dentro de cada grupo, los avisos se ordenan por fecha de forma descendente (más reciente primero).
   List<AvisoModel> get avisosFiltrados {
    // 1. Definir el punto de referencia: Hoy, a medianoche.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Hoy a 00:00:00
    
    final List<AvisoModel> allAvisos = _userProvider.avisos;

    // 2. Aplicar los filtros de visibilidad y filtros de usuario
    final List<AvisoModel> filtered = allAvisos.where((aviso) {
        
        // --- PRE-FILTRO DE VISIBILIDAD (Requerimiento del usuario) ---
        
        // Convertimos la fecha de inicio del aviso a medianoche para una comparación solo por día.
        final avisoStartDate = DateTime(aviso.fecha.year, aviso.fecha.month, aviso.fecha.day);

        // CONDICIÓN 1: AVISO NO VISIBLE (Fecha de inicio es posterior a hoy)
        // Ejemplo: Aviso 2025-11-10. Si hoy es 2025-10-10, esAfter devuelve TRUE.
        if (avisoStartDate.isAfter(today)) {
            return false; // Descartar si aún no es la fecha de inicio.
        }

        // CONDICIÓN 2: AVISO ARCHIVADO (Fecha de fin es anterior a hoy)
        // Convertimos la fecha de fin del aviso a medianoche.
        final avisoEndDate = DateTime(aviso.fechaFin.year, aviso.fechaFin.month, aviso.fechaFin.day);
        
        // isBefore devuelve TRUE si la fecha del aviso es ESTRICTAMENTE anterior a hoy.
        // Ejemplo: Hoy es 2025-10-10. Si fecha_fin es 2025-10-09, isBefore devuelve TRUE.
        final bool isArchivedByDate = avisoEndDate.isBefore(today);

        // -------------------------------------------------------------
        
        // Condición para el filtro de fecha (el filtro de la UI)
        // Ya que avisos.fecha es DateTime, la comparación es segura.
        final bool pasaFecha =
            fechaFiltro == null || aviso.fecha.isAfter(fechaFiltro!);

        // Condición para el filtro de estado de lectura.
        final bool pasaLectura =
            (filtroLectura == 'Todos') ||
            (filtroLectura == 'Leídos' && aviso.leido) ||
            (filtroLectura == 'No leídos' && !aviso.leido);

        // Lógica principal:
        if (filtroLectura == 'Archivados') {
            // Si el filtro es 'Archivados', solo mostramos los que cumplen esa condición.
            return isArchivedByDate && pasaFecha;
        } else {
            // Para 'Todos', 'Leídos' y 'No leídos', NO mostramos los avisos archivados.
            return !isArchivedByDate && pasaFecha && pasaLectura;
        }
    }).toList();

    // 3. Aplicar el ordenamiento personalizado.
    filtered.sort((a, b) {
        if (filtroLectura == 'Archivados') {
            return b.fecha.compareTo(a.fecha);
        }
        // Prioriza no leídos sobre leídos, luego por fecha descendente.
        if (!a.leido && b.leido) {
            return -1;
        }
        if (a.leido && !b.leido) {
            return 1;
        }
        return b.fecha.compareTo(a.fecha);
    });

    return filtered;
  }

  /// Muestra un selector de fecha ([showDatePicker]) para permitir al usuario
  /// filtrar los avisos por una fecha específica.
  void _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaFiltro ?? DateTime.now(), // Fecha inicial del selector.
      firstDate: DateTime(2020), // Fecha mínima seleccionable.
      lastDate: DateTime(2100), // Fecha máxima seleccionable.
      builder: (BuildContext context, Widget? child) {
        // [MODIFICACIÓN] Obtener los colores del provider dentro del builder
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final colores = userProvider.colores;
        // Aplica un tema personalizado al selector de fecha.
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.indigoAccent, // Color primario del selector.
              onPrimary: Colors.white, // Color del texto en el color primario.
              onSurface: Colors.black, // Color del texto en la superficie.
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    colores.botonesColor, // Color de los botones de texto.
              ),
            ),
          ),
          child: child!, // El propio selector de fecha.
        );
      },
    );
    // Si el usuario seleccionó una fecha (no canceló el selector).
    if (picked != null) {
      setState(() {
        fechaFiltro =
            picked; // Actualiza la fecha de filtro y reconstruye la UI.
      });
    }
  }

  @override
  /// Un getter que, al ser `true`, indica a [AutomaticKeepAliveClientMixin]
  /// que mantenga el estado de este widget cuando no está activo.
  ///
  /// Esto es útil en contextos como [TabBarView] para evitar que la vista
  /// se reconstruya cada vez que se navega a ella.
  bool get wantKeepAlive => true;

  @override
  /// Construye la interfaz de usuario de la pantalla de avisos.
  ///
  /// Escucha los cambios en [UserProvider] para reconstruir la UI
  /// automáticamente cuando los datos de avisos (incluyendo su estado de 'leído') cambian.
  ///
  /// [context]: El contexto de construcción del widget.
Widget build(BuildContext context) {
    super.build(
      context,
    ); // Llama al método build de la clase padre (AutomaticKeepAliveClientMixin).

    // Escucha al UserProvider. Cuando los datos de avisos cambian en el provider,
    // este widget se reconstruirá para reflejar esos cambios.
    _userProvider = Provider.of<UserProvider>(context);

    debugPrint(
      'AvisosView: build llamado. _errorMessage: $_errorMessage, Avisos filtrados(${avisosFiltrados.length})',
    );
    // [MODIFICACIÓN] Obtener los colores del provider dentro del builder
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Avisos',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: colores.headerColor,
          centerTitle: true,
        ),

        body: RefreshIndicator(
          // Permite al usuario "arrastrar para refrescar" la lista de avisos.
          onRefresh: () async {
            final now = DateTime.now();
            // Verifica si ha pasado menos de un minuto desde la última recarga manual.
            if (_lastManualRefreshTime != null && now.difference(_lastManualRefreshTime!).inSeconds < 60) {
              debugPrint('AvisosView: Intento de recarga manual demasiado pronto.');
              _showSnackBar('Datos actualizados.', backgroundColor: Colors.green);
              return; 
            }

            debugPrint('AvisosView: RefreshIndicator activado. Iniciando recarga forzada.');

            _showSnackBar(
              'Recargando datos...',
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.grey,
            );

            // Actualiza el tiempo de la última recarga manual.
            _lastManualRefreshTime = now;

            await _loadAvisos(forceReload: true);

            if (_errorMessage == null) {
              _showSnackBar(
                'Datos actualizados.',
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              );
            }
          },
          child: Column(
            children: [
              // Sección de controles de filtrado (fecha y estado de lectura).
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón para seleccionar la fecha de filtro.
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        fechaFiltro != null
                            ? DateFormat('dd/MM/yyyy').format(
                              fechaFiltro!,
                            ) // Muestra la fecha seleccionada.
                            : 'Filtrar por fecha', // Texto por defecto.
                        style: const TextStyle(color: Colors.black),
                      ),
                      onPressed: _seleccionarFecha, // Llama al selector de fecha.
                    ),
                    // Dropdown para seleccionar el filtro de lectura.
                    DropdownButton<String>(
                      value: filtroLectura,
                      icon: const Icon(Icons.filter_list),
                      items:
                          ['Todos', 'Leídos', 'No leídos', 'Archivados']
                              .map(
                                (v) => DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(
                            () => filtroLectura = value!,
                          ), // Actualiza el filtro y reconstruye la UI.
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Área principal de la lista de avisos.
              Expanded(
                // El indicador de carga solo se muestra en la carga inicial
                // Y si la lista de avisos del provider está vacía Y no hay un mensaje de error.
                child:
                    _isInitialLoading &&
                            _userProvider.avisos.isEmpty &&
                            _errorMessage == null
                        ? const Center(
                          child: CircularProgressIndicator(),
                        ) // Indicador de carga.
                        : _errorMessage !=
                            null // Si hay un mensaje de error.
                        ? SingleChildScrollView(
                          physics:
                              const AlwaysScrollableScrollPhysics(), // Permite scroll incluso si el contenido es pequeño.
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
                                    _errorMessage!, // Muestra el mensaje de error.
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Arrastra hacia abajo para reintentar.', // Instrucción para reintentar.
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        : avisosFiltrados
                            .isEmpty // Si la lista filtrada está vacía.
                        ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No hay avisos para mostrar según los filtros.',
                              ), // Mensaje si no hay avisos.
                            ),
                          ),
                        )
                        : ListView.builder(
                          // Constructor de lista para mostrar los avisos.
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              avisosFiltrados
                                  .length, // Número de avisos a mostrar.
                          itemBuilder: (context, index) {
                            final aviso = avisosFiltrados[index]; // Aviso actual.
                            final IconData iconoAviso = _getIconFromFa(aviso.seccion);
                            return Card(
                              elevation:
                                  aviso.leido
                                      ? 1
                                      : 4, // Menor elevación para avisos leídos.
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side:
                                    aviso
                                            .leido // Borde diferente para avisos no leídos.
                                        ? BorderSide.none
                                        : BorderSide(
                                          color: colores.headerColor,
                                          width: 1.5,
                                        ),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              color:
                                  aviso
                                          .leido // Color de fondo diferente para avisos no leídos.
                                      ? Colors.white
                                      : Colors.indigo.shade50,
                              child: InkWell(
                                onTap:
                                    () => _mostrarAviso(
                                      aviso,
                                    ), // Al tocar, muestra el detalle del aviso.
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Icono de notificación.
                                      Icon(
                                        iconoAviso,
                                        color:
                                            aviso.leido
                                                ? Colors.grey
                                                : colores.headerColor,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      // Línea divisoria vertical.
                                      Container(
                                        height: 40,
                                        width: 1.5,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(width: 12),
                                      // Contenido del aviso (fecha, título, comentario).
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Fecha del aviso.
                                            Text(
                                              DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(aviso.fecha),
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: colores.botonesColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // Título del aviso (mayúsculas, truncado si es largo).
                                            Text(
                                              aviso.titulo.toUpperCase(),
                                              style: TextStyle(
                                                fontWeight:
                                                    aviso.leido
                                                        ? FontWeight.normal
                                                        : FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    aviso.leido
                                                        ? Colors.black87
                                                        : Colors.black,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            // Previsualización del comentario (sin HTML, truncado).
                                            Text(
                                              _stripHtmlIfNeeded(
                                                aviso.comentario,
                                                maxLength: 80,
                                              ),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color:
                                                    aviso.leido
                                                        ? Colors.grey.shade600
                                                        : Colors.black54,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Icono de flecha para indicar que es clickeable.
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Clase Painter para dibujar la línea horizontal "afilada"
class _SharpLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color =
              Colors
                  .grey
                  .shade300 // Color de la línea.
          ..strokeWidth =
              2 // Grosor de la línea.
          ..strokeCap =
              StrokeCap.butt; // Extremos "afilados" (por defecto es Square).

    final path = Path();
    path.moveTo(size.width * 0.05, size.height / 2);
    path.lineTo(size.width * 0.95, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No hay necesidad de repintar a menos que los parámetros cambien.
  }
}
