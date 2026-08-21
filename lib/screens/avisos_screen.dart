import 'package:flutter/foundation.dart';
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
//import 'package:url_launcher/url_launcher.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
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

      if (_userProvider.sesionInvalida) {
        _userProvider.sesionInvalida = false; // resetea la bandera
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
      return;
      }

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
          borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colores.headerColor, colores.headerColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  aviso.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // --- Contenido scrollable dentro de Expanded ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE d \'de\' MMMM \'del\' yyyy', 'es_ES').format(aviso.fecha),
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      const SizedBox(height: 10),

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
                                
                                final String resourcePath = snapshot.data!;
                                  final String extension = resourcePath.split('.').last.toLowerCase();

                                     // Lógica de visualización: PDF o imagen
                                if (extension == 'pdf') {
                                  // 🚀 LÓGICA DE PDF MODIFICADA para usar Syncfusion en Web y Móvil
                                  if (kIsWeb) {
                                    // WEB: Usa la URL de red.
                                    return SfPdfViewer.network(
                                      resourcePath,
                                      canShowHyperlinkDialog: true,
                                      enableDocumentLinkAnnotation: true,
                                    );
                                  } else {
                                    // MÓVIL: Usa la ruta de archivo local (asumiendo que getAvisoImagePath 
                                    // devolvió la ruta local en móvil).
                                    return SfPdfViewer.file(
                                      File(resourcePath),
                                      canShowHyperlinkDialog: true,
                                      enableDocumentLinkAnnotation: true,
                                    );
                                  }
                                }
                                     else if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: InteractiveViewer(
                                          panEnabled: true,
                                          minScale: 1.0,
                                          maxScale: 4.0,
                                          child: SizedBox(
                                            width: double.infinity,
                                            // 🛑 Implementación Condicional
                                            child: kIsWeb
                                                ? Image.network( // 🟢 WEB: Usar Image.network y la URL de red
                                                    resourcePath,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Text('No se pudo cargar la imagen (Web).', textAlign: TextAlign.center);
                                                    },
                                                  )
                                                : Image.file( // 🔵 MÓVIL: Usar Image.file y la ruta local
                                                    File(resourcePath),
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Text('No se pudo cargar la imagen (Móvil).', textAlign: TextAlign.center);
                                                    },
                                                  ),
                                          ),
                                        ),
                                      );
                                    } else {
                                      // Fallback para tipos de archivo no soportados o si solo hay texto HTML
                                      return SingleChildScrollView(
                                        child: Html(data: aviso.comentario),
                                      );
                                    }
                                    // ⭐️ FIN DEL CÓDIGO MODIFICADO ⭐️
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
                            return Container(
                              margin: const EdgeInsets.only(top: 16.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F7FB),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Por favor, responde a este aviso:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 12),
                                  if (aviso.tipoRespuesta!.toLowerCase() == 'siono')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: ElevatedButton(
                                              onPressed: aviso.segRespuesta != null && aviso.segRespuesta!.isNotEmpty
                                                  ? null
                                                  : () {
                                                      setStateForm(() {
                                                        _selectedOption = 'Sí';
                                                      });
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _selectedOption == 'Sí' ? colores.botonesColor : Colors.white,
                                                foregroundColor: _selectedOption == 'Sí' ? Colors.white : Colors.black87,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(color: colores.botonesColor.withOpacity(0.4)),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: const Text('Sí'),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: ElevatedButton(
                                              onPressed: aviso.segRespuesta != null && aviso.segRespuesta!.isNotEmpty
                                                  ? null
                                                  : () {
                                                      setStateForm(() {
                                                        _selectedOption = 'No';
                                                      });
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _selectedOption == 'No' ? colores.botonesColor : Colors.white,
                                                foregroundColor: _selectedOption == 'No' ? Colors.white : Colors.black87,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  side: BorderSide(color: colores.botonesColor.withOpacity(0.4)),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                              child: const Text('No'),
                                            ),
                                          ),
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
                                  const SizedBox(height: 14),
                                  if (aviso.segRespuesta == null || aviso.segRespuesta!.isEmpty)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
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
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: const Text('Enviar respuesta'),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: colores.botonesColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Ya has respondido este aviso: "${aviso.segRespuesta}"',
                                        style: TextStyle(
                                          color: colores.botonesColor,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
        if (avisoStartDate.isAfter(today)) {
            return false; // Descartar si aún no es la fecha de inicio.
        }

        // CONDICIÓN 2: AVISO ARCHIVADO (Fecha de fin es anterior a hoy)
        final avisoEndDate = DateTime(aviso.fechaFin.year, aviso.fechaFin.month, aviso.fechaFin.day);
        final bool isArchivedByDate = avisoEndDate.isBefore(today);

        // -------------------------------------------------------------

        // Condición para el filtro de estado de lectura.
        final bool pasaLectura =
            (filtroLectura == 'Todos') ||
            (filtroLectura == 'Leídos' && aviso.leido) ||
            (filtroLectura == 'No leídos' && !aviso.leido);

        // Lógica principal:
        if (filtroLectura == 'Archivados') {
            return isArchivedByDate;
        } else {
            return !isArchivedByDate && pasaLectura;
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

    // ============================================================
  // FILTROS
  // ============================================================

  /// Construye la barra de filtros: un botón centrado que muestra el
  /// filtro activo y abre un modal inferior con las opciones. Si hay
  /// un filtro distinto de 'Todos' aplicado, se muestra debajo un
  /// acceso rápido para limpiarlo.
  Widget _buildFilterBar(Colores colores) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 250,
              child: _buildFilterButton(
                icon: Icons.filter_list_rounded,
                label: filtroLectura,
                active: filtroLectura != 'Todos',
                color: colores.headerColor,
                onTap: () => _showFilterMenu(colores),
              ),
            ),
          ),
          if (filtroLectura != 'Todos')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () => setState(() => filtroLectura = 'Todos'),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Mostrar todos'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Botón que representa el filtro actualmente seleccionado y abre el menú de opciones.
  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active ? color.withOpacity(0.10) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? color.withOpacity(0.45) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: active ? color : Colors.grey.shade600),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? color : Colors.grey.shade700,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el modal inferior con las opciones de filtro de lectura.
  void _showFilterMenu(Colores colores) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Filtrar avisos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ...['Todos', 'No leídos', 'Leídos', 'Archivados'].map((filtro) {
                final selected = filtroLectura == filtro;
                return ListTile(
                  onTap: () {
                    setState(() => filtroLectura = filtro);
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  tileColor: selected ? colores.headerColor.withOpacity(0.08) : null,
                  leading: Icon(
                    _getFilterIcon(filtro),
                    color: selected ? colores.headerColor : Colors.grey.shade600,
                  ),
                  title: Text(
                    filtro,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colores.headerColor : Colors.black87,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_circle_rounded, color: colores.headerColor)
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Ícono representativo para cada opción de filtro de lectura.
  IconData _getFilterIcon(String filtro) {
    switch (filtro) {
      case 'No leídos':
        return Icons.mark_email_unread_rounded;
      case 'Leídos':
        return Icons.mark_email_read_rounded;
      case 'Archivados':
        return Icons.inventory_2_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Muestra un selector de fecha ([showDatePicker]) para permitir al usuario
  /// filtrar los avisos por una fecha específica.
  /*void _seleccionarFecha() async {
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
  }*/

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
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Avisos',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: colores.headerColor,
          centerTitle: true,
        ),

        body: RefreshIndicator(
          color: colores.headerColor,
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
              // --- Barra de filtros: botón que abre un modal inferior con las opciones ---
              _buildFilterBar(colores),
              // Área principal de la lista de avisos.
              // Área principal de la lista de avisos.
              Expanded(
                // El indicador de carga solo se muestra en la carga inicial
                // Y si la lista de avisos del provider está vacía Y no hay un mensaje de error.
                child:
                    _isInitialLoading &&
                            _userProvider.avisos.isEmpty &&
                            _errorMessage == null
                        ? Center(
                          child: CircularProgressIndicator(color: colores.headerColor),
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
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Column(
                                children: [
                                  Icon(Icons.notifications_off_rounded, size: 56, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay avisos para mostrar según los filtros.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          itemCount: avisosFiltrados.length,
                          itemBuilder: (context, index) {
                            final aviso = avisosFiltrados[index];
                            final IconData iconoAviso = _getIconFromFa(aviso.seccion);
                            final bool leido = aviso.leido;

                            const Color colorFondoLeido = Color(0xFFDDE1EA);
                            const Color colorTextoLeido = Color(0xFF5B6472);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: leido ? colorFondoLeido : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(leido ? 0.03 : 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: leido
                                    ? null
                                    : Border.all(color: colores.headerColor.withOpacity(0.25), width: 1.2),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _mostrarAviso(aviso),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 46,
                                              height: 46,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: leido
                                                    ? colorTextoLeido.withOpacity(0.15)
                                                    : colores.headerColor.withOpacity(0.12),
                                              ),
                                              child: Icon(
                                                iconoAviso,
                                                color: leido ? colorTextoLeido : colores.headerColor,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.only(right: 70),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      aviso.titulo.toUpperCase(),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15.5,
                                                        color: leido ? colorTextoLeido : Colors.black87,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today_rounded,
                                                          size: 12,
                                                          color: leido ? colorTextoLeido : Colors.grey.shade500,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          DateFormat('dd/MM/yyyy').format(aviso.fecha),
                                                          style: TextStyle(
                                                            fontSize: 12.5,
                                                            fontWeight: FontWeight.w500,
                                                            color: leido ? colorTextoLeido : Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 16,
                                              color: leido ? colorTextoLeido : Colors.grey.shade400,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 42,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: leido ? colorTextoLeido : colores.headerColor,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            leido ? 'LEÍDO' : 'NUEVO',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ),
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
