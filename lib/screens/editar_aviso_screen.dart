import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:file_picker/file_picker.dart'; // ⭐️ IMPORTAR FILE_PICKER ⭐️

// ----------------------------------------------------------------------
// ESTA VISTA SOLO SE ENCARGA DE EDITAR Y ELIMINAR AVISOS EXISTENTES
// ----------------------------------------------------------------------

class EditarAvisoScreen extends StatefulWidget {
  final Map<String, dynamic> avisoParaEditar; 

  const EditarAvisoScreen({Key? key, required this.avisoParaEditar}) : super(key: key);

  @override
  _EditarAvisoScreenState createState() => _EditarAvisoScreenState();
}

class _EditarAvisoScreenState extends State<EditarAvisoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _tituloController = TextEditingController();
  final HtmlEditorController _cuerpoEditorController = HtmlEditorController();
  final _opcion1Controller = TextEditingController();
  final _opcion2Controller = TextEditingController();
  final _opcion3Controller = TextEditingController();
  
  // Estado
  List<String> _destinatariosPrincipales = ['Todos'];
  String _destinatarioSeleccionado = 'Todos'; 
  Map<String, List<String>> _opcionesEspecificas = {};
  String? _seleccionEspecifica;
  String _respuestaSeleccionada = 'Ninguna';
  
  // Fechas 
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();
  
  String _initialHtmlContent = ''; 

  // ⭐️ NUEVOS ESTADOS PARA CONTROL DE ARCHIVO/COMENTARIO ⭐️
  bool _mostrarEditor = false; 
  String? _rutaArchivoAdjunto; 
  // ----------------------------------------------------

  // Definición de botones para el ToolbarWidget
  final List<Toolbar> _toolbarButtons = const [
      FontButtons(strikethrough: false, subscript: false, superscript: false),
      FontSettingButtons(fontSize: true, fontName: false),
      StyleButtons(), 
      ColorButtons(), 
      ParagraphButtons(textDirection: false, lineHeight: false, caseConverter: false),
      ListButtons(listStyles: true),
      InsertButtons(link: true, picture: true, audio: false, video: false, table: false, hr: false),
  ];

  @override
  void initState() {
    super.initState();
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colaborador = userProvider.colaboradorModel;
    final aviso = widget.avisoParaEditar;

    // 1. Configurar listas de destinatarios (se mantiene igual)
    if (colaborador != null) {
      final List<String> listaNiveles = colaborador.avisoNivelesEducativos.map((n) => n.nivelEducativo).toList();
      final List<String> listaSalones = colaborador.avisoSalones.map((s) => s.salon).toList();
      final List<String> listaAlumnos = colaborador.avisoAlumnos.map((a) => '${a.primerNombre} ${a.apellidoPat} (${a.idAlumno})').toList();
      final List<String> listaColaboradores = colaborador.avisoColaboradores.map((c) => c.nombreCompleto).toList(); 
      
      _opcionesEspecificas = {
        'Nivel Educativo': listaNiveles,
        'Salón': listaSalones,
        'Alumno Específico': listaAlumnos,
        'Colaborador Específico': listaColaboradores,
      };
      
      _destinatariosPrincipales = [
        'Todos',                   
        'Todos los Alumnos',       
        'Todos los Colaboradores', 
        if (listaNiveles.isNotEmpty) 'Nivel Educativo',
        if (listaSalones.isNotEmpty) 'Salón',
        if (listaAlumnos.isNotEmpty) 'Alumno Específico',
        if (listaColaboradores.isNotEmpty) 'Colaborador Específico',
      ];
    }

    // 2. Llenar los campos para EDICIÓN (Carga de datos de la API)
    _tituloController.text = aviso['titulo'] as String? ?? '';
    _initialHtmlContent = aviso['comentario'] as String? ?? ''; 
    
    // ⭐️ LÓGICA CLAVE DE COMENTARIO/ARCHIVO ⭐️
    final String? archivoAdjuntoApi = aviso['archivo'] as String?;
    
    if (archivoAdjuntoApi != null && archivoAdjuntoApi.isNotEmpty) {
        // Se subió un archivo, lo mostramos.
        _rutaArchivoAdjunto = archivoAdjuntoApi;
        _mostrarEditor = false;
    } else if (_initialHtmlContent.isNotEmpty) {
        // Hay comentario, mostramos el editor.
        _mostrarEditor = true;
        _rutaArchivoAdjunto = null;
    } else {
        // No hay ni archivo ni comentario, por defecto no mostramos nada.
        _mostrarEditor = false;
        _rutaArchivoAdjunto = null;
    }

    // El resto de la inicialización se mantiene (con las correcciones anteriores)
    
    String destinatarioTipoApi = aviso['seccion'] as String? ?? 'Todos'; 
    if (destinatarioTipoApi == 'ColaboradorEspecifico') {
        destinatarioTipoApi = 'Colaborador Específico';
    } else if (destinatarioTipoApi == 'AlumnoEspecifico') { 
        destinatarioTipoApi = 'Alumno Específico';
    }

    if (_destinatariosPrincipales.contains(destinatarioTipoApi)) {
        _destinatarioSeleccionado = destinatarioTipoApi;
    } else {
        _destinatarioSeleccionado = 'Todos';
    }
    
    final String apiRespuesta = aviso['tipo_respuesta'] as String? ?? 'Ninguna'; 
    if (apiRespuesta == 'Seleccion') {
        _respuestaSeleccionada = 'Seleccion multiple';
    } else if (apiRespuesta == 'SioNo') { 
        _respuestaSeleccionada = 'Sí o No'; 
    } else {
        _respuestaSeleccionada = apiRespuesta;
    }

    try {
        final String? fechaInicioStr = aviso['fecha_inicio'] as String?;
        final String? fechaFinStr = aviso['fecha_fin'] as String?;
        
        if (fechaInicioStr != null && fechaInicioStr.isNotEmpty) {
              _fechaInicio = DateTime.parse(fechaInicioStr.substring(0, 10));
        }
        if (fechaFinStr != null && fechaFinStr.isNotEmpty) {
              _fechaFin = DateTime.parse(fechaFinStr.substring(0, 10));
        }
    } catch (_) {}
    
    _seleccionEspecifica = aviso['valor_especifico'] as String?;
    
    final String? opcion1 = aviso['opcion_1'] as String?; 
    final String? opcion2 = aviso['opcion_2'] as String?; 
    final String? opcion3 = aviso['opcion_3'] as String?; 

    if (opcion1 != null && opcion1.isNotEmpty) _opcion1Controller.text = opcion1;
    if (opcion2 != null && opcion2.isNotEmpty) _opcion2Controller.text = opcion2;
    if (opcion3 != null && opcion3.isNotEmpty) _opcion3Controller.text = opcion3;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
             setState(() {
                _resetSeleccionEspecifica(); 
             });
        }
    });
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _opcion1Controller.dispose();
    _opcion2Controller.dispose();
    _opcion3Controller.dispose();
    super.dispose();
  }

  // ⭐️ LÓGICA DE ARCHIVO Y EDITOR ⭐️
  Future<void> _seleccionarArchivo() async {
    const int maxFileSize = 1048576; // 1 MB
    
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final PlatformFile pickedFile = result.files.single;

        if (pickedFile.size > maxFileSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡El archivo es demasiado grande! Máximo 1 MB.'),
              backgroundColor: Colors.red,
            ),
          );
          return; 
        }
        
        setState(() {
          _rutaArchivoAdjunto = pickedFile.path;
          _mostrarEditor = false; // Deshabilita el editor si hay archivo
          _cuerpoEditorController.clear(); // Limpia el editor
          _initialHtmlContent = ''; // Limpia el contenido inicial si se cambia de editor a archivo
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archivo seleccionado: ${pickedFile.name}')),
        );
        
      }
    } catch (e) {
      // Manejo de error
    }
  }

  void _mostrarEditorComentario() {
    setState(() {
      _mostrarEditor = true;
      _rutaArchivoAdjunto = null; // Elimina el archivo si se elige escribir
    });
  }

  // Lógica de reset (se mantiene igual)
  void _resetSeleccionEspecifica() {
    final String key = _destinatarioSeleccionado;

    if (key == 'Todos' || !_opcionesEspecificas.containsKey(key)) {
        if (mounted) {
            setState(() {
                _seleccionEspecifica = null;
            });
        }
        return;
    }
    
    final List<String> opciones = _opcionesEspecificas[key]!;

    if (opciones.isNotEmpty) {
        if (_seleccionEspecifica == null || !opciones.contains(_seleccionEspecifica!)) {
             if (mounted) {
                 setState(() {
                    _seleccionEspecifica = opciones.first;
                 });
             }
        }
    } else {
        if (mounted) {
            setState(() {
                _seleccionEspecifica = null;
            });
        }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    // Lógica de selección de fecha (se mantiene igual)
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        final Color dynamicPrimaryColor = Provider.of<UserProvider>(context, listen: false).colores.headerColor;
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
        if (isStartDate) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  // Lógica de guardar Aviso (Editar) (se ajusta la carga de 'cuerpo' y 'archivo')
  void _guardarAviso() async { 
    if (_formKey.currentState!.validate()) {
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      String cuerpoHtml = '';
      
      // ⚠️ VALIDACIÓN CLAVE: Debe haber un cuerpo de mensaje O un archivo adjunto
      if (_rutaArchivoAdjunto == null && !_mostrarEditor) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debe escribir un comentario o adjuntar un archivo (PDF/Imagen).')),
          );
          return;
      }
      
      if (_mostrarEditor) {
          cuerpoHtml = await _cuerpoEditorController.getText();

          if (cuerpoHtml.trim().isEmpty || cuerpoHtml.trim() == '<p><br></p>') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El campo de comentario no puede estar vacío.')),
              );
              return;
          }
      }
      
      // La lógica de respuesta múltiple (mantenida)
      String opcionesMultiples = '';
      String tipoRespuestaAPI = _respuestaSeleccionada; 
      
      if (_respuestaSeleccionada == 'Sí o No') {
          tipoRespuestaAPI = 'SioNo'; 
      } else if (_respuestaSeleccionada == 'Seleccion multiple') {
          tipoRespuestaAPI = 'Seleccion'; 
          
          final List<String> opciones = [];
          if (_opcion1Controller.text.isNotEmpty) opciones.add(_opcion1Controller.text.trim());
          if (_opcion2Controller.text.isNotEmpty) opciones.add(_opcion2Controller.text.trim());
          if (_opcion3Controller.text.isNotEmpty) opciones.add(_opcion3Controller.text.trim());
          opcionesMultiples = opciones.join(',');
          
          if (opciones.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debe ingresar al menos dos opciones para la Selección Múltiple.')),
              );
              return; 
          }
      }
      
      // Lógica de destinatario específico (mantenida)
      final bool esDestinatarioEspecifico = _opcionesEspecificas.containsKey(_destinatarioSeleccionado);
      final bool hayOpcionesDisponibles = _opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ?? false;
      final String? destinatarioValor;
      
      if (esDestinatarioEspecifico && hayOpcionesDisponibles && _seleccionEspecifica != null) {
          destinatarioValor = _seleccionEspecifica;
      } else {
          destinatarioValor = null;
      }
      
      final String idAviso = widget.avisoParaEditar['id_calendario'] as String? ?? '0';

      final avisoDataParaProvider = {
        'titulo': _tituloController.text,
        'cuerpo': _rutaArchivoAdjunto != null ? '' : cuerpoHtml, // Enviar cuerpo vacío si hay archivo
        'destinatario_tipo': _destinatarioSeleccionado,
        'destinatario_valor': destinatarioValor,
        'requiere_respuesta': tipoRespuestaAPI, 
        'fecha_inicio': _fechaInicio.toIso8601String().substring(0, 10),
        'fecha_fin': _fechaFin.toIso8601String().substring(0, 10),
        'id_calendario': idAviso, 
        'opciones_multiples': opcionesMultiples,
        'archivo': _rutaArchivoAdjunto, // ⭐️ Ruta del archivo ⭐️
      };

      print('--- EDICIÓN DE AVISO (ID: ${idAviso}) ---');
      print('Datos enviados al Provider: $avisoDataParaProvider');
      print('-------------------------------------------');
      
      // (Llamada a la API y manejo de respuesta...)
      final snackBar = SnackBar(
        content: Row(
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 20),
            Text('Actualizando aviso...'),
          ],
        ),
        duration: const Duration(minutes: 5),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });

      final result = await userProvider.saveAviso(avisoDataParaProvider);

      if (!mounted) return; 
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );

      if (result['success']) {
        Navigator.pop(context); 
      }
    }
  }

  void _eliminarAviso() {
    // Implementar la lógica de eliminación aquí
    // userProvider.deleteAviso(idAviso);
    // ...
    // ignore: avoid_print
    print('Aviso eliminado');
    Navigator.pop(context); // Regresar a la pantalla de lista
  }

  // ⭐️ FUNCIÓN: Construye la barra de herramientas separada ⭐️
  Widget _buildCustomToolbar(BuildContext context, Color dynamicPrimaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: dynamicPrimaryColor.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: dynamicPrimaryColor, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 8.0),
      child: ToolbarWidget(
        controller: _cuerpoEditorController,
        callbacks: Callbacks(),
        htmlToolbarOptions: HtmlToolbarOptions(
          defaultToolbarButtons: _toolbarButtons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colores = userProvider.colores;
    final Color dynamicPrimaryColor = colores.footerColor;
    final Color dynamicHeaderColor = colores.headerColor;

    final bool mostrarComboEspecifico = _opcionesEspecificas.containsKey(_destinatarioSeleccionado) && (_opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ?? false);
    final bool mostrarOpcionesMultiples = _respuestaSeleccionada == 'Seleccion multiple';

    return SafeArea( 
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Editar Aviso'), // Título estático
          backgroundColor: dynamicHeaderColor,
          centerTitle: true,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _eliminarAviso,
              tooltip: 'Eliminar aviso',
              color: Colors.white,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ... (Dropdowns y Fechas - Se mantienen igual) ...
                _buildFiltroDropdown(
                  label: 'Mostrar en Calendario de',
                  value: _destinatarioSeleccionado,
                  items: _destinatariosPrincipales, 
                  onChanged: (String? newValue) {
                    setState(() {
                      _destinatarioSeleccionado = newValue!;
                      _resetSeleccionEspecifica(); 
                    });
                  },
                  dynamicPrimaryColor: dynamicPrimaryColor,
                ),
                
                if (mostrarComboEspecifico) ...[
                  const SizedBox(height: 20),
                  _buildFiltroDropdown(
                    label: 'Seleccionar $_destinatarioSeleccionado',
                    value: _seleccionEspecifica,
                    items: _opcionesEspecificas[_destinatarioSeleccionado]!, 
                    onChanged: (String? newValue) {
                      setState(() {
                        _seleccionEspecifica = newValue!;
                      });
                    },
                    dynamicPrimaryColor: dynamicPrimaryColor,
                  ),
                ],
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateInput(
                        label: 'Visible desde',
                        date: _fechaInicio,
                        onTap: () => _selectDate(context, true),
                        dynamicPrimaryColor: dynamicPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateInput(
                        label: 'Visible hasta',
                        date: _fechaFin,
                        onTap: () => _selectDate(context, false),
                        dynamicPrimaryColor: dynamicPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFiltroDropdown(
                  label: 'Requiere respuesta',
                  value: _respuestaSeleccionada,
                  items: const ['Ninguna', 'Sí o No', 'Seleccion multiple'],
                  onChanged: (String? newValue) {
                    setState(() {
                      _respuestaSeleccionada = newValue!;
                    });
                  },
                  dynamicPrimaryColor: dynamicPrimaryColor,
                ),
                const SizedBox(height: 20),
                
                if (mostrarOpcionesMultiples) ...[
                  const Text('Opciones de Respuesta Múltiple:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _buildOpcionTextField(controller: _opcion1Controller, label: 'Opción 1', dynamicPrimaryColor: dynamicPrimaryColor),
                  _buildOpcionTextField(controller: _opcion2Controller, label: 'Opción 2', dynamicPrimaryColor: dynamicPrimaryColor),
                  _buildOpcionTextField(controller: _opcion3Controller, label: 'Opción 3', dynamicPrimaryColor: dynamicPrimaryColor),
                  const SizedBox(height: 20),
                ],
                
                // Título (se mantiene igual)
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título', 
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
                    ),
                    labelStyle: TextStyle(color: dynamicPrimaryColor),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingrese un título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // ⭐️ ÁREA DE SELECCIÓN: COMENTARIO vs ARCHIVO ⭐️
                const Text('Contenido:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),

                // 1. Botones de Acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _seleccionarArchivo,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Adjuntar Archivo'),
                        style: ElevatedButton.styleFrom(
                          // Resaltar si hay un archivo adjunto
                          backgroundColor: _rutaArchivoAdjunto != null && _rutaArchivoAdjunto!.isNotEmpty ? Colors.green : dynamicPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _mostrarEditorComentario,
                        icon: const Icon(Icons.edit),
                        label: const Text('Escribir Comentario'),
                        style: ElevatedButton.styleFrom(
                          // Resaltar si el editor está visible
                          backgroundColor: _mostrarEditor ? Colors.green : dynamicPrimaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // 2. Estado de Archivo Adjunto (Muestra solo el nombre del archivo si existe)
                if (_rutaArchivoAdjunto != null && _rutaArchivoAdjunto!.isNotEmpty) 
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 10),
                        // Muestra solo el nombre del archivo si es una ruta completa
                        Expanded(child: Text('Archivo adjunto: ${_rutaArchivoAdjunto!.split('/').last}', overflow: TextOverflow.ellipsis)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _rutaArchivoAdjunto = null),
                        ),
                      ],
                    ),
                  ),

                // 3. Editor de Comentario (se muestra condicionalmente)
                if (_mostrarEditor) ...[
                  if (_rutaArchivoAdjunto != null && _rutaArchivoAdjunto!.isNotEmpty) 
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('⚠️ Nota: Al guardar, se enviará el comentario y se ignorará el archivo. Para enviar el archivo, desactiva el editor.', style: TextStyle(color: Colors.orange)),
                    ),
                    
                  _buildCustomToolbar(context, dynamicPrimaryColor),
                  const SizedBox(height: 10),
                  
                  HtmlEditor(
                    controller: _cuerpoEditorController,
                    htmlEditorOptions: HtmlEditorOptions(
                      hint: "Escriba aquí el cuerpo del aviso...",
                      // Usar el contenido inicial si está disponible
                      initialText: _initialHtmlContent.isNotEmpty ? _initialHtmlContent : null, 
                      darkMode: Theme.of(context).brightness == Brightness.dark,
                      adjustHeightForKeyboard: true,
                    ),
                    htmlToolbarOptions: const HtmlToolbarOptions(
                      toolbarPosition: ToolbarPosition.custom, 
                      toolbarType: ToolbarType.nativeGrid,
                    ),
                    otherOptions: OtherOptions(
                      height: 400, 
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 30),
                // Botón de guardar
                ElevatedButton(
                  onPressed: _guardarAviso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dynamicPrimaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (Funciones auxiliares buildFiltroDropdown, buildDateInput, buildOpcionTextField se mantienen igual) ...
  Widget _buildFiltroDropdown({
    required String label,
    required String? value, 
    required List<String> items,
    required Function(String?) onChanged,
    required Color dynamicPrimaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value, 
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
            ),
          ),
          isExpanded: true,
          items: items.map<DropdownMenuItem<String>>((String itemValue) {
            return DropdownMenuItem<String>(
              value: itemValue,
              child: Text(itemValue),
            );
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged, 
          validator: (val) {
             if (items.isNotEmpty && val == null) {
                 return 'Debe seleccionar una opción.';
             }
             return null;
          }
        ),
      ],
    );
  }

  Widget _buildDateInput({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required Color dynamicPrimaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
              ),
              suffixIcon: Icon(Icons.calendar_today, color: dynamicPrimaryColor),
            ),
            child: Text(
              '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOpcionTextField({
    required TextEditingController controller,
    required String label,
    required Color dynamicPrimaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label, 
          hintText: 'Ej. "Opción A"',
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
          ),
          labelStyle: TextStyle(color: dynamicPrimaryColor),
        ),
      ),
    );
  }
}