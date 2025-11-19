import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/screens/editar_aviso_screen.dart';
import 'package:provider/provider.dart'; 
import 'package:intl/intl.dart'; 
import 'crear_aviso_screen.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart'; 
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

  // ⭐️ Lógica agregada para la carga inicial de avisos ⭐️
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadAvisosCreados();
    });
  }

  // ⭐️ 1. FUNCIÓN PARA EL MODAL SIMPLIFICADO DE VISUALIZACIÓN/EDICIÓN (MODIFICADA) ⭐️
void _mostrarAvisoParaEdicion(Map<String, dynamic> aviso) {
    final userProvider = Provider.of<UserProvider>(context, listen: false); 
    final colores = userProvider.colores;
    
    final String titulo = aviso['titulo'] as String? ?? 'Aviso sin Título';
    final String comentario = aviso['comentario'] as String? ?? 'Aviso sin Contenido';
    final String fechaStr = aviso.containsKey('fecha_inicio') ? aviso['fecha_inicio'] as String? ?? '' : '';
    
    // ⭐️ LÓGICA CLAVE PARA EL ARCHIVO (ACTUALIZADA) ⭐️
    final String? rutaArchivoAlmacenada = aviso['archivo'] as String?;
    final bool tieneArchivo = rutaArchivoAlmacenada != null && rutaArchivoAlmacenada.isNotEmpty;
    
    String? rutaFinalParaVisualizar;
    
    if (tieneArchivo) {
        // La ruta es una URL completa si empieza con 'http'
        if (rutaArchivoAlmacenada.toLowerCase().startsWith('http')) {
            rutaFinalParaVisualizar = rutaArchivoAlmacenada;
        } else {
            // Si la ruta NO es una URL completa (como 'assets/...'), prefijamos.
            // Usamos la constante API para prefijar y asegurar que no haya doble barra
            String limpiaRuta = rutaArchivoAlmacenada.startsWith('/') ? rutaArchivoAlmacenada.substring(1) : rutaArchivoAlmacenada;
            rutaFinalParaVisualizar = ApiConstants.assetsBaseUrl + limpiaRuta;
        }
    } else {
        rutaFinalParaVisualizar = null;
    }

    // Usamos rutaFinalParaVisualizar para determinar si es una URL funcional
    final bool esURL = rutaFinalParaVisualizar != null && rutaFinalParaVisualizar.toLowerCase().startsWith('http');
    
    // ---------------------------------------------------------------------------------
    
    String fechaFormateada = '';
    try {
        final DateTime fecha = DateTime.parse(fechaStr);
        // Asegúrate de que DateFormat use el idioma español si está configurado en el proyecto
        fechaFormateada = DateFormat('EEEE d \'de\' MMMM \'del\' yyyy', 'es').format(fecha);
    } catch (e) {
        fechaFormateada = 'Fecha no disponible';
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final dialogWidth = screenWidth * 0.90;
        final dialogHeight = screenHeight * 0.90; 

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
                    titulo,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Información de fecha
                        Text(
                          fechaFormateada,
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          
                        ),
                        const SizedBox(height: 5),
                        const Divider(color: Colors.grey, thickness: 0.5),
                        const SizedBox(height: 10),
                        
                        // ⭐️ WIDGET DE IMAGEN CONDICIONAL (SI TIENE ARCHIVO) ⭐️
                        if (tieneArchivo) ...[

                            
                            const SizedBox(height: 10),
                            // Lógica para mostrar la imagen según la plataforma y la ruta
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Builder(
                                builder: (context) {
                                  // Si es una URL (la hemos construido arriba), usa Image.network
                                  if (esURL) {
                                    return Image.network(
                                      rutaFinalParaVisualizar!, // ⭐️ USAMOS LA RUTA FINAL AQUÍ ⭐️
                                      fit: BoxFit.contain,
                                      height: 200, // Altura máxima para el modal
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const SizedBox(
                                          height: 200,
                                          child: Center(child: CircularProgressIndicator()),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const SizedBox(
                                          height: 100,
                                          child: Center(child: Text('Error al cargar imagen remota. Verifique la URL y la conexión.')),
                                        );
                                      },
                                    );
                                  // Si es una ruta local y NO es web, usa Image.file
                                  } else if (!kIsWeb) {
                                    return Image.file(
                                      // ⚠️ Nota: Si rutaArchivoAlmacenada contiene 'assets/...' no funcionará en Image.file ⚠️
                                      // Usamos la ruta almacenada original para Image.file, esperando que sea una ruta de sistema válida.
                                      File(rutaArchivoAlmacenada), 
                                      fit: BoxFit.contain,
                                      height: 200,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Muestra un widget si el archivo no existe localmente
                                        return const SizedBox(
                                          height: 100,
                                          child: Center(child: Text('Archivo local no encontrado o no es una imagen.')),
                                        );
                                      },
                                    );
                                  } else {
                                    // Web no puede acceder a rutas locales por seguridad, solo a URLs
                                    return const SizedBox(
                                        height: 50,
                                        child: Center(child: Text('Archivo adjunto no disponible.')),
                                      );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                        ],
                        
                        // ⭐️ CONTENIDO DEL AVISO CON FORMATO HTML ⭐️
                        Html(
                          data: comentario,
                          style: {
                            "body": Style(
                              fontSize: FontSize(16.0),
                              lineHeight: LineHeight(1.5),
                              margin: Margins.zero, 
                              padding: HtmlPaddings.zero, 
                            ),
                            "h1": Style(fontSize: FontSize(24.0), fontWeight: FontWeight.bold),
                            "h2": Style(fontSize: FontSize(20.0), fontWeight: FontWeight.bold),
                            "h3": Style(fontSize: FontSize(18.0), fontWeight: FontWeight.bold),
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // --- Botones al fondo del modal (Editar / Cerrar) ---
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cerrar', style: TextStyle(color: colores.botonesColor)),
                      ),
                      const SizedBox(width: 15),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Cerrar modal
                          _navegarAEdicion(aviso);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar Aviso'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colores.botonesColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
  
  // ⭐️ 2. FUNCIÓN PARA NAVEGAR A LA VISTA DE EDICIÓN (Modificada para recargar) ⭐️
  void _navegarAEdicion(Map<String, dynamic> aviso) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditarAvisoScreen(avisoParaEditar: aviso),
      ),
    );
    // Recargar avisos cuando se regrese de la edición/creación
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

  // ⭐️ 4. FUNCIÓN PARA MANEJAR LA CONFIRMACIÓN Y ELIMINACIÓN (CORREGIDA) ⭐️
Future<void> _confirmarYEliminar(BuildContext context, Map<String, dynamic> aviso, UserProvider userProvider) async {
    // ⭐️ CORRECCIÓN: Usar id_calendario o id_aviso, y asegurar que no sea '0'.
    final String idAviso = aviso['id_calendario']?.toString() ?? aviso['id_aviso']?.toString() ?? '0'; 
    final String tituloAviso = aviso['titulo']?.toString() ?? 'este aviso';
    
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
      if (result == 'editar') {
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
          body: Column(
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
        );
      },
    );
  }
}
