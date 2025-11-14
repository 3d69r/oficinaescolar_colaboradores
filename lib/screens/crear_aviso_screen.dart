import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class CrearAvisoScreen extends StatefulWidget {
  final Map<String, dynamic>? avisoParaEditar;

  const CrearAvisoScreen({Key? key, this.avisoParaEditar}) : super(key: key);

  @override
  _CrearAvisoScreenState createState() => _CrearAvisoScreenState();
}

class _CrearAvisoScreenState extends State<CrearAvisoScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado para los campos
  final _tituloController = TextEditingController();
  final HtmlEditorController _cuerpoEditorController = HtmlEditorController();
  final _opcion1Controller = TextEditingController();
  final _opcion2Controller = TextEditingController();
  final _opcion3Controller = TextEditingController();
  
  // DINÁMICOS: Se llenan en initState con datos del Provider
  List<String> _destinatariosPrincipales = ['Todos'];
  String _destinatarioSeleccionado = 'Todos';  
  Map<String, List<String>> _opcionesEspecificas = {};
  String? _seleccionEspecifica;
  String _respuestaSeleccionada = 'Ninguna';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));
  String _initialHtmlContent = '';  

  // ⭐️ ESTADOS PARA CONTROL DE ARCHIVO/COMENTARIO ⭐️
  bool _mostrarEditor = false;
  String? _rutaArchivoAdjunto;
  // ----------------------------------------------------

  void _resetSeleccionEspecifica() {
    final String key = _destinatarioSeleccionado;

    if (key == 'Todos' || !_opcionesEspecificas.containsKey(key)) {
        setState(() {
            _seleccionEspecifica = null;
        });
        return;
    }
    
    final List<String> opciones = _opcionesEspecificas[key]!;

    if (opciones.isNotEmpty) {
        if (_seleccionEspecifica == null || !opciones.contains(_seleccionEspecifica)) {
              setState(() {
                _seleccionEspecifica = opciones.first;
              });
        }
    } else {
        setState(() {
            _seleccionEspecifica = null;
        });
    }
  }

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this); 

    // ⭐️ AÑADIDO: Eliminar el foco en el primer frame ⭐️
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colaborador = userProvider.colaboradorModel;

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

    if (widget.avisoParaEditar != null) {
      _tituloController.text = widget.avisoParaEditar!['titulo'] as String? ?? '';
      _initialHtmlContent = widget.avisoParaEditar!['comentario'] as String? ?? '';  
      
      if (_initialHtmlContent.isNotEmpty) {
          _mostrarEditor = true;
      }
      
      _destinatarioSeleccionado = widget.avisoParaEditar!['destinatario_tipo'] as String? ?? 'Todos';  
      
      final String apiRespuesta = widget.avisoParaEditar!['requiere_respuesta'] as String? ?? 'Ninguna';  
      _respuestaSeleccionada = apiRespuesta == 'Seleccion' ? 'Seleccion multiple' : apiRespuesta;

      try {
          final String? fechaInicioStr = widget.avisoParaEditar!['fecha_inicio'] as String?;
          final String? fechaFinStr = widget.avisoParaEditar!['fecha_fin'] as String?;
          
          if (fechaInicioStr != null && fechaInicioStr.isNotEmpty) {
              _fechaInicio = DateTime.parse(fechaInicioStr);
          }
          if (fechaFinStr != null && fechaFinStr.isNotEmpty) {
              _fechaFin = DateTime.parse(fechaFinStr);
          }
      } catch (_) {}
      
      _seleccionEspecifica = widget.avisoParaEditar!['destinatario_valor'] as String?;
      
      final String? opciones = widget.avisoParaEditar!['opciones_multiples'] as String?;  
      if (opciones != null && opciones.isNotEmpty) {
          final List<String> parts = opciones.split(',');
          if (parts.isNotEmpty) _opcion1Controller.text = parts[0].trim();
          if (parts.length > 1) _opcion2Controller.text = parts[1].trim();
          if (parts.length > 2) _opcion3Controller.text = parts[2].trim();
      }
    }  
    
    _resetSeleccionEspecifica();  
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {}); 
        
        // ⭐️ AÑADIDO: Eliminar el foco al reanudar ⭐️
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    _tituloController.dispose();
    _opcion1Controller.dispose();
    _opcion2Controller.dispose();
    _opcion3Controller.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
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
  
  Future<void> _seleccionarArchivo() async {
    const int maxFileSize = 1048576;  
    
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        final PlatformFile pickedFile = result.files.single;

        if (pickedFile.size > maxFileSize) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('¡El archivo es demasiado grande! Máximo 1 MB.'),
                  backgroundColor: Colors.red,
                ),
              );
          }
          return;  
        }
        
        if (mounted) {
            setState(() {
              _rutaArchivoAdjunto = pickedFile.path;
              _mostrarEditor = false;
            });
            
            _cuerpoEditorController.clear();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Archivo seleccionado: ${pickedFile.name}')),
            );
        }
        
      } else {
        // El usuario canceló la selección.
      }
    } catch (e) {
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al seleccionar archivo: $e')),
          );
      }
    }
  }

  void _mostrarEditorComentario() {
    setState(() {
      _mostrarEditor = true;
      _rutaArchivoAdjunto = null;
    });
  }
  
  void _guardarAviso() async {  
    if (_formKey.currentState!.validate()) {
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      String cuerpoHtml = '';
      
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
      
      final bool esDestinatarioEspecifico = _opcionesEspecificas.containsKey(_destinatarioSeleccionado);
      final bool hayOpcionesDisponibles = _opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ?? false;
      
      final String? destinatarioValor;
      
      if (esDestinatarioEspecifico && hayOpcionesDisponibles && _seleccionEspecifica != null) {
          destinatarioValor = _seleccionEspecifica;
      } else {
          destinatarioValor = null;
      }
      
      final String idAviso = widget.avisoParaEditar?['id_calendario'] as String? ?? '0';

      final avisoDataParaProvider = {
        'titulo': _tituloController.text,
        'cuerpo': cuerpoHtml,
        'destinatario_tipo': _destinatarioSeleccionado,
        'destinatario_valor': destinatarioValor,
        'requiere_respuesta': tipoRespuestaAPI,  
        'fecha_inicio': _fechaInicio.toIso8601String().substring(0, 10),
        'fecha_fin': _fechaFin.toIso8601String().substring(0, 10),
        'id_calendario': idAviso,  
        'opciones_multiples': opcionesMultiples,
        'archivo': _rutaArchivoAdjunto,
      };

      print('--- CREACIÓN/EDICIÓN DE AVISO (ID: ${idAviso}) ---');
      print('Datos enviados al Provider: $avisoDataParaProvider');
      print('-------------------------------------------');
      
      final snackBar = SnackBar(
        content: Row(
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 20),
            Text('Guardando aviso...'),
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
    print('Aviso eliminado');
    Navigator.pop(context, true);
  }

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
        htmlToolbarOptions: const HtmlToolbarOptions(
          defaultToolbarButtons: [
            FontButtons(
              strikethrough: false,  
              subscript: false,     
              superscript: false,   
            ),
            FontSettingButtons(
              fontSize: true,    
              fontName: false,   
            ),
            StyleButtons(),  
            ColorButtons(),  
            ParagraphButtons(
              textDirection: false,  
              lineHeight: false,  
              caseConverter: false,
            ),
            InsertButtons(
              link: true,        
              picture: false,  
              audio: false,  
              video: false,  
              table: false,  
              hr: false,
            ),
          ],
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

    // ⭐️ MODIFICACIÓN CLAVE 1: Envolver en GestureDetector para cerrar el teclado al tocar fuera ⭐️
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(  
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.avisoParaEditar == null ? 'Crear Aviso' : 'Editar Aviso'),
            backgroundColor: dynamicHeaderColor,
            centerTitle: true,
            foregroundColor: Colors.white,
            actions: widget.avisoParaEditar != null
                ? [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _eliminarAviso,
                tooltip: 'Eliminar aviso',
                color: Colors.white,
              ),
            ]
                : null,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                  
                  // Título
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
                            backgroundColor: _rutaArchivoAdjunto != null ? Colors.green : dynamicPrimaryColor,
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
                            backgroundColor: _mostrarEditor ? Colors.green : dynamicPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 2. Estado de Archivo Adjunto
                  if (_rutaArchivoAdjunto != null)  
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
                    if (_rutaArchivoAdjunto != null)  
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text('⚠️ El archivo adjunto se eliminará al guardar si escribes un comentario.', style: TextStyle(color: Colors.orange)),
                      ),
                      
                    _buildCustomToolbar(context, dynamicPrimaryColor),
                    const SizedBox(height: 10),
                    
                    HtmlEditor(
                      controller: _cuerpoEditorController,
                      htmlEditorOptions: HtmlEditorOptions(
                        hint: "Escriba aquí el cuerpo del aviso...",
                        initialText: _initialHtmlContent,  
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
                    child: const Text('Guardar Aviso'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget para Dropdown (Mantenido)
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
          onChanged: items.isEmpty || value == null ? null : onChanged,  
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

  // Widget para entrada de fecha (Mantenido)
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

  // Widget para opciones múltiples (Mantenido)
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