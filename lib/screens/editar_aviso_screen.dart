import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:html_editor_enhanced/html_editor.dart';

// ----------------------------------------------------------------------
// ESTA VISTA SOLO SE ENCARGA DE EDITAR Y ELIMINAR AVISOS EXISTENTES
// ----------------------------------------------------------------------

class EditarAvisoScreen extends StatefulWidget {
  final Map<String, dynamic> avisoParaEditar; // Ya no es nullable

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
  
  // Fechas (Inicializadas con los valores del aviso)
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();
  
  String _initialHtmlContent = ''; 

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

    // 1. Configurar listas de destinatarios (igual que en CrearAvisoScreen)
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

    // 2. Llenar los campos para EDICIÓN
    _tituloController.text = aviso['titulo'] as String? ?? '';
    _initialHtmlContent = aviso['comentario'] as String? ?? ''; 
    _destinatarioSeleccionado = aviso['destinatario_tipo'] as String? ?? 'Todos'; 
    
    final String apiRespuesta = aviso['requiere_respuesta'] as String? ?? 'Ninguna'; 
    _respuestaSeleccionada = apiRespuesta == 'Seleccion' ? 'Seleccion multiple' : apiRespuesta;

    try {
        final String? fechaInicioStr = aviso['fecha_inicio'] as String?;
        final String? fechaFinStr = aviso['fecha_fin'] as String?;
        
        if (fechaInicioStr != null && fechaInicioStr.isNotEmpty) {
              // Parsear solo la parte de la fecha si es una cadena ISO completa
              _fechaInicio = DateTime.parse(fechaInicioStr.substring(0, 10));
        }
        if (fechaFinStr != null && fechaFinStr.isNotEmpty) {
              _fechaFin = DateTime.parse(fechaFinStr.substring(0, 10));
        }
    } catch (_) {}
    
    _seleccionEspecifica = aviso['destinatario_valor'] as String?;
    
    final String? opciones = aviso['opciones_multiples'] as String?; 
    if (opciones != null && opciones.isNotEmpty) {
        final List<String> parts = opciones.split(',');
        if (parts.isNotEmpty) _opcion1Controller.text = parts[0].trim();
        if (parts.length > 1) _opcion2Controller.text = parts[1].trim();
        if (parts.length > 2) _opcion3Controller.text = parts[2].trim();
    }
    
    _resetSeleccionEspecifica(); 
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _opcion1Controller.dispose();
    _opcion2Controller.dispose();
    _opcion3Controller.dispose();
    super.dispose();
  }

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

  // ⭐️ Lógica de guardar Aviso (Editar) ⭐️
  void _guardarAviso() async { 
    if (_formKey.currentState!.validate()) {
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String cuerpoHtml = await _cuerpoEditorController.getText();
      
      if (cuerpoHtml.trim().isEmpty || cuerpoHtml.trim() == '<p><br></p>') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El campo de comentario no puede estar vacío.')),
          );
          return;
      }

      // Lógica de respuesta múltiple (mantenida)
      String opcionesMultiples = '';
      String tipoRespuestaAPI = _respuestaSeleccionada; 
      
      if (_respuestaSeleccionada == 'Seleccion multiple') {
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
      
      // ⭐️ Clave para EDICIÓN: Usamos el ID existente ⭐️
      final String idAviso = widget.avisoParaEditar['id_calendario'] as String? ?? '0';

      final avisoDataParaProvider = {
        'titulo': _tituloController.text,
        'cuerpo': cuerpoHtml,
        'destinatario_tipo': _destinatarioSeleccionado,
        'destinatario_valor': destinatarioValor,
        'requiere_respuesta': tipoRespuestaAPI, 
        'fecha_inicio': _fechaInicio.toIso8601String().substring(0, 10),
        'fecha_fin': _fechaFin.toIso8601String().substring(0, 10),
        'id_calendario': idAviso, // El ID existente
        'opciones_multiples': opcionesMultiples,
      };
      
      // Llamar a la API a través del Provider
      // Mostrar indicador de carga...
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

  // ❌ Lógica de eliminación (DESHABILITADA TEMPORALMENTE) ❌
  /*
  void _eliminarAviso() {
    final String idAviso = widget.avisoParaEditar['id_calendario'] as String? ?? '0';
    if (idAviso == '0') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de aviso no válido para eliminar.')),
      );
      return;
    }
    
    // Muestra un diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Está seguro de que desea eliminar este aviso permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              
              // ⚠️ ESTA FUNCIÓN AÚN NO EXISTE EN EL PROVIDER ⚠️
              // final result = await userProvider.deleteAviso(idAviso); 
              
              const result = {'success': false, 'message': 'Funcionalidad de Eliminación deshabilitada temporalmente.'};

              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message']),
                  backgroundColor: result['success'] ? Colors.green : Colors.red,
                ),
              );

              // if (result['success']) {
              //   Navigator.pop(context); // Regresar a la lista de avisos
              // }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  */

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
          // ❌ SECCIÓN DE ACCIONES ELIMINADA (Para deshabilitar la eliminación)
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // 1. Destinatarios
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
                      
                      // 2. Fechas
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
                      
                      // 3. Requisito de Respuesta
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
                      
                      // 4. Opciones Múltiples (Si aplica)
                      const SizedBox(height: 20),
                      if (mostrarOpcionesMultiples) ...[
                        const Text('Opciones de Respuesta Múltiple:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        _buildOpcionTextField(controller: _opcion1Controller, label: 'Opción 1', dynamicPrimaryColor: dynamicPrimaryColor),
                        _buildOpcionTextField(controller: _opcion2Controller, label: 'Opción 2', dynamicPrimaryColor: dynamicPrimaryColor),
                        _buildOpcionTextField(controller: _opcion3Controller, label: 'Opción 3', dynamicPrimaryColor: dynamicPrimaryColor),
                        const SizedBox(height: 20),
                      ],
                      
                      // ⭐️ 5. TÍTULO (MOVido aquí, justo antes del editor) ⭐️
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
                      
                      // ⭐️ 6. WIDGET DE COMENTARIO/EDITOR HTML ⭐️
                      _buildCustomToolbar(context, dynamicPrimaryColor),
                      
                      const SizedBox(height: 10),
                      const Text('Comentario:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      
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
                      const SizedBox(height: 30),
                      
                      // 7. Botón de guardar
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
          ],
        ),
      ),
    );
  }

  // ⭐️ Widgets Auxiliares ⭐️

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