import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/screens/editar_aviso_screen.dart';
import 'package:oficinaescolar_colaboradores/models/modo_visualizacion.dart';
import 'package:oficinaescolar_colaboradores/models/aviso_seguimiento_model.dart';
import 'package:oficinaescolar_colaboradores/widgets/visualizaciones_aviso_modal.dart';
import 'package:provider/provider.dart'; 
import 'package:intl/intl.dart'; 
import 'crear_aviso_screen.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; 
// import 'avisos_archivados_screen.dart'; // ❌ ELIMINADA: Ya no se usa
import 'package:flutter_html/flutter_html.dart'; 
// ⭐️ IMPORTACIONES NECESARIAS PARA IMAGEN ⭐️
import 'dart:io'; 
import 'package:flutter/foundation.dart' show kIsWeb; // Para verificar si es web
// ⚠️ IMPORTACIÓN NECESARIA PARA API CONSTANTS ⚠️


// CLASE AUXILIAR DE PINTURA (Se mantiene)

// ----------------------------------------------------------------------
// CLASE PRINCIPAL
// ----------------------------------------------------------------------

class SubirAvisosScreen extends StatefulWidget {
  const SubirAvisosScreen({super.key});

  @override
  State<SubirAvisosScreen> createState() => _SubirAvisosScreenState();
}

class _SubirAvisosScreenState extends State<SubirAvisosScreen> {
  DateTime? _fechaFiltroInicio;
  DateTime? _fechaFiltroFin;
  DateTime? _lastManualRefreshTime;
  // ⭐️ Lógica agregada para la carga inicial de avisos ⭐️
  @override
  void initState() {
    super.initState();
    // ⭐️ Rango por defecto: últimos 31 días hasta hoy.
    final DateTime hoy = DateTime.now();
    _fechaFiltroFin = DateTime(hoy.year, hoy.month, hoy.day);
    _fechaFiltroInicio = _fechaFiltroFin!.subtract(const Duration(days: 31));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadAvisosCreados();
    });
  }

void _mostrarAvisoParaEdicion(Map<String, dynamic> aviso) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final colores = userProvider.colores;

  final String titulo = aviso['titulo'] as String? ?? 'Aviso sin Título';
  final String cuerpo = aviso['comentario'] as String? ?? '';
  final String fechaInicio = aviso['fecha_inicio'] as String? ?? '';
  final String fechaFin = aviso['fecha_fin'] as String? ?? '';
  final String tipoRespuesta = aviso['tipo_respuesta'] as String? ?? 'Ninguna';

  final List<String> opcionesPreview = [
    aviso['opcion_1'],
    aviso['opcion_2'],
    aviso['opcion_3'],
  ]
      .whereType<String>()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  // Resolver la ruta/URL final del archivo, igual que ya hacías
  final String? rutaArchivoAlmacenada = aviso['archivo'] as String?;
  final bool tieneArchivo =
      rutaArchivoAlmacenada != null && rutaArchivoAlmacenada.isNotEmpty;

  String? rutaFinalParaVisualizar;
  if (tieneArchivo) {
    if (rutaArchivoAlmacenada.toLowerCase().startsWith('http')) {
      rutaFinalParaVisualizar = rutaArchivoAlmacenada;
    } else {
      String limpiaRuta = rutaArchivoAlmacenada.startsWith('/')
          ? rutaArchivoAlmacenada.substring(1)
          : rutaArchivoAlmacenada;
      rutaFinalParaVisualizar = ApiConstants.assetsBaseUrl + limpiaRuta;
    }
  }

  final bool esPdf =
      tieneArchivo && rutaArchivoAlmacenada.toLowerCase().endsWith('.pdf');

  showDialog(
    context: context,
    builder: (dialogContext) {
      final screenWidth = MediaQuery.of(dialogContext).size.width;
      final screenHeight = MediaQuery.of(dialogContext).size.height;
      final dialogWidth = screenWidth * 0.90;
      final dialogHeight = screenHeight * 0.95;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colores.headerColor,
                      colores.headerColor.withOpacity(0.85)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),

              // --- Contenido ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Del $fechaInicio al $fechaFin',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                      const SizedBox(height: 10),

                      // Contenido: PDF / imagen / html
                      if (tieneArchivo)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: esPdf
                                ? SizedBox(
                                    width: double.infinity,
                                    height: double.infinity,
                                    child: SfPdfViewer.network(
                                      rutaFinalParaVisualizar!,
                                      canShowHyperlinkDialog: true,
                                      enableDocumentLinkAnnotation: true,
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      minScale: 1.0,
                                      maxScale: 4.0,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Image.network(
                                          rutaFinalParaVisualizar!,
                                          fit: BoxFit.contain,
                                          loadingBuilder: (context, child,
                                              loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return const SizedBox(
                                              height: 200,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            );
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Text(
                                            'No se pudo cargar la imagen.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Html(data: cuerpo),
                            ),
                          ),
                        ),

                      // --- Sección de respuesta (solo lectura) ---
                      if (tipoRespuesta.toLowerCase() == 'siono' ||
                          tipoRespuesta.toLowerCase() == 'seleccion')
                        Container(
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
                                'Este aviso pide una respuesta:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              if (tipoRespuesta.toLowerCase() == 'siono')
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: OutlinedButton(
                                          onPressed: null,
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: BorderSide(
                                                color: colores.botonesColor
                                                    .withOpacity(0.4)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text('Sí'),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: OutlinedButton(
                                          onPressed: null,
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            side: BorderSide(
                                                color: colores.botonesColor
                                                    .withOpacity(0.4)),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text('No'),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else if (tipoRespuesta.toLowerCase() ==
                                  'seleccion')
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: opcionesPreview.map((opcion) {
                                    return RadioListTile<String>(
                                      title: Text(opcion),
                                      value: opcion,
                                      groupValue: null,
                                      onChanged: null,
                                      activeColor: colores.botonesColor,
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // --- Botones ---
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cerrar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          _navegarAEdicion(aviso);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('Editar Aviso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colores.botonesColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _mostrarVisualizadosAviso(Map<String, dynamic> aviso, UserProvider userProvider) async {
  if (!_tieneAccesoADestinatario(aviso, userProvider)) {
    _mostrarAlertaSinAcceso('ver quién vio');
    return;
  }

  final String idAviso = aviso['id_calendario']?.toString() ?? aviso['id_aviso']?.toString() ?? '0';
  final String titulo = aviso['titulo'] as String? ?? 'Aviso';
  final String destinatarioTipo = aviso['seccion'] as String? ?? aviso['destinatario_tipo'] as String? ?? 'Todos';
  final ModoVisualizacion modo = resolverModoVisualizacion(destinatarioTipo);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final bool ok = await userProvider.fetchInfoSeguimientoAviso(idAviso);

  if (mounted) Navigator.of(context).pop();
  if (!mounted) return;

  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo cargar el seguimiento de este aviso.')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (_) => VisualizacionesAvisoModal(
      titulo: titulo,
      modo: modo,
      seguimiento: userProvider.seguimientoAviso, // ⭐️ CAMBIO de nombre de parámetro
      colores: userProvider.colores,
    ),
  );
}
  // ⭐️ 2. FUNCIÓN PARA NAVEGAR A LA VISTA DE EDICIÓN (Modificada para recargar) ⭐️
  void _navegarAEdicion(Map<String, dynamic> aviso) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!_tieneAccesoADestinatario(aviso, userProvider)) {
      _mostrarAlertaSinAcceso('editar');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarAvisoScreen(avisoParaEditar: aviso),
      ),
    );
    if (mounted) {
       Provider.of<UserProvider>(context, listen: false).loadAvisosCreados();
    }
  }
  
  // ⭐️ 3. LÓGICA DE FILTRADO (MODIFICADA PARA FORZAR ESPAÑOL EN MESES Y DÍAS) ⭐️
Future<void> _seleccionarRangoDeFechas(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: (_fechaFiltroInicio != null && _fechaFiltroFin != null)
          ? DateTimeRange(start: _fechaFiltroInicio!, end: _fechaFiltroFin!)
          : null,
      // 🎯 NUEVO: Forzar la localización a español 🎯
      locale: const Locale('es', 'ES'), 
      
      // Textos personalizados en español (ya agregados)
      helpText: 'Selecciona Rango de Fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      saveText: 'Guardar',
      errorInvalidRangeText: 'Rango de fechas inválido',
      errorFormatText: 'Formato de fecha inválido',
      fieldStartHintText: 'Fecha Inicial',
      fieldEndHintText: 'Fecha Final',

      builder: (BuildContext context, Widget? child) {
        final Color dynamicPrimaryColor = Provider.of<UserProvider>(context, listen: false).colores.footerColor;
        
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: dynamicPrimaryColor,
            colorScheme: ColorScheme.light(primary: dynamicPrimaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechaFiltroInicio = picked.start;
        _fechaFiltroFin = picked.end;
      });
    }
}

  List<Map<String, dynamic>> _getAvisosFiltrados(UserProvider provider) {
    // ⭐️ FUENTE DE DATOS: Usamos la lista de avisos creados (activos) ⭐️
    List<Map<String, dynamic>> avisos = provider.avisosCreados;
    
    if (_fechaFiltroInicio == null || _fechaFiltroFin == null) {
      return avisos;
    }
    
    return avisos.where((aviso) {
      final String? fechaInicioStr = aviso['fecha_inicio'] as String?;
      final String? fechaFinStr = aviso['fecha_fin'] as String?;

      if (fechaInicioStr == null || fechaFinStr == null) {
          return true; 
      }
      
      try {
        final DateTime fechaInicio = DateTime.parse(fechaInicioStr);
        final DateTime fechaFin = DateTime.parse(fechaFinStr);

        return (fechaInicio.isAfter(_fechaFiltroInicio!) || fechaInicio.isAtSameMomentAs(_fechaFiltroInicio!)) &&
            (fechaFin.isBefore(_fechaFiltroFin!) || fechaFin.isAtSameMomentAs(_fechaFiltroFin!));
            
      } catch (e) {
          return true;
      }
      
    }).toList();
  }
  
  String _formatDate(String isoDateString) {
      try {
          final date = DateTime.parse(isoDateString);
          return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
          return 'Fecha Inválida';
      }
  }

    // ⭐️ Replica la misma restricción de permisos que EditarAvisoScreen:
  // determina si el colaborador logueado tiene acceso al tipo de
  // destinatario con el que se creó este aviso.
  bool _tieneAccesoADestinatario(
      Map<String, dynamic> aviso, UserProvider userProvider) {
    final colaborador = userProvider.colaboradorModel;
    if (colaborador == null) return true; // fallback conservador

    final String idColaboradorActual = userProvider.idColaborador;
    final salonesAsignados = colaborador.avisoSalones
        .where((s) =>
            s.idMaestroTitular == idColaboradorActual ||
            s.idMaestroSuplente == idColaboradorActual)
        .toList();

    final bool tieneSalonAsignado = salonesAsignados.isNotEmpty;

    List<String> destinatariosPermitidos;
    if (tieneSalonAsignado) {
      final salonesParaMostrar = salonesAsignados;
      final listaSalones = salonesParaMostrar.map((s) => s.salon).toList();
      final listaAlumnos = colaborador.avisoAlumnos
          .where((a) => listaSalones.contains(a.salon))
          .map((a) => '${a.primerNombre} ${a.apellidoPat}')
          .toList();

      destinatariosPermitidos = [
        if (listaSalones.isNotEmpty) 'Salón',
        if (listaAlumnos.isNotEmpty) 'Alumno Específico',
      ];
    } else {
      final listaNiveles = colaborador.avisoNivelesEducativos
          .map((n) => n.nivelEducativo)
          .toList();
      final listaSalones =
          colaborador.avisoSalones.map((s) => s.salon).toList();
      final listaAlumnos = colaborador.avisoAlumnos
          .map((a) => '${a.primerNombre} ${a.apellidoPat}')
          .toList();
      final listaColaboradores = colaborador.avisoColaboradores
          .map((c) => c.nombreCompleto)
          .toList();

      destinatariosPermitidos = [
        'Todos',
        'Todos los Alumnos',
        'Todos los Colaboradores',
        if (listaNiveles.isNotEmpty) 'Nivel Educativo',
        if (listaSalones.isNotEmpty) 'Salón',
        if (listaAlumnos.isNotEmpty) 'Alumno Específico',
        if (listaColaboradores.isNotEmpty) 'Colaborador Específico',
      ];
    }

    final String codigoApiSeccion = aviso['seccion'] as String? ??
        aviso['destinatario_tipo'] as String? ??
        'Todos';
    String destinatarioTipoApi;
    switch (codigoApiSeccion) {
      case 'AlumnoEspecifico':
        destinatarioTipoApi = 'Alumno Específico';
        break;
      case 'ColaboradorEspecifico':
        destinatarioTipoApi = 'Colaborador Específico';
        break;
      case 'AlumnosSalon':
        destinatarioTipoApi = 'Salón';
        break;
      case 'AlumnosNivelEdu':
        destinatarioTipoApi = 'Nivel Educativo';
        break;
      case 'Alumnos':
        destinatarioTipoApi = 'Todos los Alumnos';
        break;
      case 'Colaboradores':
        destinatarioTipoApi = 'Todos los Colaboradores';
        break;
      case 'Todos':
      default:
        destinatarioTipoApi = 'Todos';
    }

    return destinatariosPermitidos.contains(destinatarioTipoApi);
  }

  void _mostrarAlertaSinAcceso(String accion) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sin acceso'),
        content: Text(
          'No tienes permiso para $accion este aviso, ya que fue creado '
          'para destinatarios a los que no tienes acceso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ⭐️ 4. FUNCIÓN PARA MANEJAR LA CONFIRMACIÓN Y ELIMINACIÓN (CORREGIDA) ⭐️
Future<void> _confirmarYEliminar(BuildContext context, Map<String, dynamic> aviso, UserProvider userProvider) async {
    final String idAviso = aviso['id_calendario']?.toString() ?? aviso['id_aviso']?.toString() ?? '0'; 
    final String tituloAviso = aviso['titulo']?.toString() ?? 'este aviso';

    if (!_tieneAccesoADestinatario(aviso, userProvider)) {
      _mostrarAlertaSinAcceso('eliminar');
      return;
    }
    
    if (idAviso == '0') {
      // ⚠️ El error se lanza si el ID es '0'
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No se pudo obtener el ID del aviso para eliminar.')),
        );
      }
      return;
    }
    // FIN CORRECCIÓN

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Está seguro de que desea eliminar el aviso "$tituloAviso"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      // 1. Mostrar indicador de carga
      if(mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // 2. Llamar al método de eliminación del Provider
      final result = await userProvider.deleteAvisoCreado(idAviso);

      // 3. Cerrar indicador de carga
      if(mounted) {
        Navigator.of(context).pop(); 
      }

      // 4. Mostrar resultado al usuario
      if (result['success'] == true) {
        if(mounted) {
          userProvider.loadAvisosCreados();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Aviso "$tituloAviso" eliminado con éxito.')),
            );
        }
      } else {
        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('❌ Error al eliminar el aviso: ${result['message']}')),
            );
        }
      }
    }
}
  
  // ⭐️ 5. FUNCIÓN PARA EL MENÚ DE ACCIONES (3 Puntos) - IMPLEMENTACIÓN FINAL ⭐️
  void _mostrarMenuAcciones(Map<String, dynamic> aviso, Offset position, UserProvider userProvider) {
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40), 
        Offset.zero & MediaQuery.of(context).size,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'seguimiento',
          child: ListTile(
            leading: Icon(Icons.visibility),
            title: Text('Ver quién lo vio'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'editar',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Editar'),
          ),
        ),
        const PopupMenuItem<String>(
          value: 'eliminar',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
      elevation: 8.0,
    ).then((String? result) {
      if (result == 'seguimiento') {
        _mostrarVisualizadosAviso(aviso, userProvider);
      } else if (result == 'editar') {
        _navegarAEdicion(aviso);
      } else if (result == 'eliminar') {
        _confirmarYEliminar(context, aviso, userProvider);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final colores = userProvider.colores;
        final Color dynamicPrimaryColor = colores.footerColor;
        
        final List<Map<String, dynamic>> avisosFiltrados = _getAvisosFiltrados(userProvider);

        return Scaffold(
          appBar: AppBar(
              title: const Text(
                'Subir Avisos',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: colores.headerColor,
              centerTitle: true,
            ),
          body: RefreshIndicator(
            color: dynamicPrimaryColor,
            onRefresh: () async {
              final now = DateTime.now();
              // Si pasó menos de un minuto desde la última recarga manual, no pega a la API.
              if (_lastManualRefreshTime != null &&
                  now.difference(_lastManualRefreshTime!).inSeconds < 60) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos actualizados.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                    margin: EdgeInsets.all(12),
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Recargando datos...'),
                  backgroundColor: Colors.grey,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                  margin: EdgeInsets.all(12),
                ),
              );

              _lastManualRefreshTime = now;

              await userProvider.loadAvisosCreados();

              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Datos actualizados.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                    margin: EdgeInsets.all(12),
                  ),
                );
              }
            },
            child: Column(
              children: [
              // Botón 'Crear Nuevo'
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Centramos al quitar el otro botón
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Modificada la navegación para forzar la recarga al volver
                          await Navigator.of(context).push(
                          // ⭐️ Esto hace que avisoParaEditar sea null por defecto ⭐️
                          MaterialPageRoute(builder: (context) => const CrearAvisoScreen()), 
                        );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dynamicPrimaryColor, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Crear Nuevo Aviso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              // Filtro de fecha (Mantenido)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () => _seleccionarRangoDeFechas(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Filtro de Fecha',
                      labelStyle: TextStyle(color: dynamicPrimaryColor), 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder( 
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0), 
                      ),
                      suffixIcon: Icon(Icons.calendar_today, color: dynamicPrimaryColor), 
                    ),
                    child: Text(
                      _fechaFiltroInicio == null
                          ? 'Seleccionar rango de fechas'
                          : '${_fechaFiltroInicio!.day}/${_fechaFiltroInicio!.month}/${_fechaFiltroInicio!.year} - ${_fechaFiltroFin!.day}/${_fechaFiltroFin!.month}/${_fechaFiltroFin!.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Lista de avisos (Mantenida)
              if (avisosFiltrados.isEmpty) 
                const Expanded(
                  child: Center(
                    child: Text(
                      'No se han encontrado avisos creados.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: avisosFiltrados.length,
                    itemBuilder: (context, index) {
                      final aviso = avisosFiltrados[index];
                      
                      final String titulo = aviso['titulo'] as String? ?? 'Sin título';
                      //final String contenido = aviso['comentario'] as String? ?? 'Sin contenido'; // No usado en la vista actual
                      final String fechaInicio = aviso['fecha_inicio'] as String? ?? '';
                      final String fechaFin = aviso['fecha_fin'] as String? ?? '';
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: InkWell(
                          onTap: () { // ⭐️ El print de debug se mantiene para la consola ⭐️                
                              _mostrarAvisoParaEdicion(aviso);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: dynamicPrimaryColor, 
                                  child: const Icon(Icons.campaign, color: Colors.white),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titulo,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                      Text(
                                        '${_formatDate(fechaInicio)} - ${_formatDate(fechaFin)}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),                                    
                                    ],
                                  ),
                                ),
                                
                                // ⭐️ BOTÓN DE MENÚ DE 3 PUNTOS ⭐️
                                Builder(
                                  builder: (BuildContext innerContext) {
                                    return IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () {
                                        final RenderBox renderBox = innerContext.findRenderObject()! as RenderBox;
                                        final Offset offset = renderBox.localToGlobal(Offset.zero);
                                        
                                        _mostrarMenuAcciones(aviso, offset, userProvider);
                                      },
                                    );
                                  },
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
        );
      },
    );
  }
}
