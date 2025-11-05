import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
// Asumo que tu ColaboradorModel y submodelos (AvisoSalonModel, etc.) 
// están en un path accesible y pueden ser referenciados si es necesario,
// aunque la lógica de la vista solo interactúa con el Provider.
// import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 

class CrearAvisoScreen extends StatefulWidget {
  final Map<String, dynamic>? avisoParaEditar; // Null si es un nuevo aviso

  const CrearAvisoScreen({Key? key, this.avisoParaEditar}) : super(key: key);

  @override
  _CrearAvisoScreenState createState() => _CrearAvisoScreenState();
}

class _CrearAvisoScreenState extends State<CrearAvisoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado para los campos
  final _tituloController = TextEditingController();
  final _cuerpoController = TextEditingController();
  
  // ⭐️ 1. Controladores para las opciones de respuesta múltiple (NUEVOS) ⭐️
  final _opcion1Controller = TextEditingController();
  final _opcion2Controller = TextEditingController();
  final _opcion3Controller = TextEditingController();
  
  // ⭐️ DINÁMICOS: Se llenan en initState con datos del Provider ⭐️
  List<String> _destinatariosPrincipales = ['Todos'];
  String _destinatarioSeleccionado = 'Todos'; 
  
  // ⭐️ DINÁMICO: Se llena en initState con datos del Provider ⭐️
  Map<String, List<String>> _opcionesEspecificas = {};
  String? _seleccionEspecifica; // Valor seleccionado en el segundo combo
  
  String _respuestaSeleccionada = 'Ninguna';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 7));


  // Función para resetear/inicializar la selección específica cuando cambia el destinatario principal
  void _resetSeleccionEspecifica() {
    final String key = _destinatarioSeleccionado;

    // 1. Si el destinatario es 'Todos' o si la clave no existe en el mapa (por error o falta de datos)
    if (key == 'Todos' || !_opcionesEspecificas.containsKey(key)) {
        setState(() {
            _seleccionEspecifica = null;
        });
        return;
    }
    
    // 2. Si la clave existe, obtener la lista de opciones
    final List<String> opciones = _opcionesEspecificas[key]!;

    if (opciones.isNotEmpty) {
        // 3. Inicializar al primer elemento si hay opciones disponibles
        // Solo llamamos a setState si el valor va a cambiar (evitar reconstrucción innecesaria)
        if (_seleccionEspecifica == null || !opciones.contains(_seleccionEspecifica)) {
             setState(() {
                _seleccionEspecifica = opciones.first;
             });
        }
    } else {
        // 4. Si la lista está vacía, anular la selección
        setState(() {
            _seleccionEspecifica = null;
        });
    }
  }

  @override
  void initState() {
    super.initState();
    
    // ⭐️ LÓGICA DE CARGA DE DATOS DESDE EL PROVIDER ⭐️
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Usamos 'colaboradorModel' asumiendo que es el getter correcto en tu UserProvider
    final colaborador = userProvider.colaboradorModel;

    if (colaborador != null) {
      // 1. Extracción y formateo de los datos del modelo
      final List<String> listaNiveles = colaborador.avisoNivelesEducativos.map((n) => n.nivelEducativo).toList();
      final List<String> listaSalones = colaborador.avisoSalones.map((s) => s.salon).toList();
      final List<String> listaAlumnos = colaborador.avisoAlumnos.map((a) => '${a.primerNombre} ${a.apellidoPat} (${a.idAlumno})').toList();
      final List<String> listaColaboradores = colaborador.avisoColaboradores.map((c) => c.nombreCompleto).toList(); 
      
      // 2. Llenar el mapa dinámico de opciones específicas
      _opcionesEspecificas = {
        'Nivel Educativo': listaNiveles,
        'Salón': listaSalones,
        'Alumno Específico': listaAlumnos,
        'Colaborador Específico': listaColaboradores,
        // Añadir aquí la clave 'Club' si tienes datos
      };
      
      // 3. Llenar la lista de destinatarios principales (solo si tienen datos)
      _destinatariosPrincipales = [
        'Todos',                   // Mapea a 'Todos'
        'Todos los Alumnos',       // Mapea a 'Alumnos'
        'Todos los Colaboradores', // Mapea a 'Colaboradores'

        // Opciones que dependen de la existencia de datos específicos
        if (listaNiveles.isNotEmpty) 'Nivel Educativo',
        if (listaSalones.isNotEmpty) 'Salón',
        if (listaAlumnos.isNotEmpty) 'Alumno Específico',
        if (listaColaboradores.isNotEmpty) 'Colaborador Específico',
      ];
    }
    // ⭐️ FIN DE LA LÓGICA DE CARGA DE DATOS ⭐️

    // Llenar los campos si se está editando un aviso
    if (widget.avisoParaEditar != null) {
      _tituloController.text = widget.avisoParaEditar!['titulo'] as String? ?? '';
      _cuerpoController.text = widget.avisoParaEditar!['cuerpo'] as String? ?? '';
      _destinatarioSeleccionado = widget.avisoParaEditar!['destinatario'] as String? ?? 'Todos';
      _respuestaSeleccionada = widget.avisoParaEditar!['respuesta'] as String? ?? 'Ninguna';
      _fechaInicio = widget.avisoParaEditar!['fechaInicio'] as DateTime? ?? DateTime.now();
      _fechaFin = widget.avisoParaEditar!['fechaFin'] as DateTime? ?? DateTime.now().add(const Duration(days: 7));
      
      // Inicializar el nuevo combo al editar
      _seleccionEspecifica = widget.avisoParaEditar!['seleccionEspecifica'] as String?;
      
      // ⭐️ Cargar opciones múltiples al editar (si existen) ⭐️
      // NOTA: Esto asume que las opciones vienen en formato "op1,op2,op3" en 'opcionesMultiples'
      final String? opciones = widget.avisoParaEditar!['opcionesMultiples'] as String?;
      if (opciones != null && opciones.isNotEmpty) {
          final List<String> parts = opciones.split(',');
          if (parts.length > 0) _opcion1Controller.text = parts[0].trim();
          if (parts.length > 1) _opcion2Controller.text = parts[1].trim();
          if (parts.length > 2) _opcion3Controller.text = parts[2].trim();
      }
    } 
    
    // Asegurar que la selección específica sea coherente, ya sea al editar o crear
    _resetSeleccionEspecifica(); 
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _cuerpoController.dispose();
    // ⭐️ 2. Disponer los controladores de opciones múltiples (NUEVOS) ⭐️
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
      // Aplicar color dinámico al DatePicker
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

  void _guardarAviso() async { 
    if (_formKey.currentState!.validate()) {
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // ⭐️ LÓGICA DE CONCATENACIÓN DE OPCIONES MÚLTIPLES ⭐️
      String opcionesMultiples = '';
      String tipoRespuestaAPI = _respuestaSeleccionada; // Por defecto usa el texto del combo
      
      if (_respuestaSeleccionada == 'Seleccion multiple') {
          // Si es "Seleccion multiple", cambiamos el valor que se enviará a la API
          tipoRespuestaAPI = 'Seleccion'; 
          
          final List<String> opciones = [];
          if (_opcion1Controller.text.isNotEmpty) opciones.add(_opcion1Controller.text.trim());
          if (_opcion2Controller.text.isNotEmpty) opciones.add(_opcion2Controller.text.trim());
          if (_opcion3Controller.text.isNotEmpty) opciones.add(_opcion3Controller.text.trim());
          opcionesMultiples = opciones.join(',');
          
          // Validación adicional: debe haber al menos dos opciones
          if (opciones.length < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Debe ingresar al menos dos opciones para la Selección Múltiple.')),
              );
              return; 
          }
      }
      
      // 1. Mapeo de datos para el método saveAviso
      final avisoDataParaProvider = {
        'titulo': _tituloController.text,
        'cuerpo': _cuerpoController.text,
        'destinatario_tipo': _destinatarioSeleccionado,
        'destinatario_valor': _destinatarioSeleccionado != 'Todos' ? _seleccionEspecifica : null, 
        // ⭐️ CAMBIO APLICADO AQUÍ: Usamos tipoRespuestaAPI ⭐️
        'requiere_respuesta': tipoRespuestaAPI, 
        'fecha_inicio': _fechaInicio.toIso8601String().substring(0, 10),
        'fecha_fin': _fechaFin.toIso8601String().substring(0, 10),
        'id_calendario': widget.avisoParaEditar != null ? widget.avisoParaEditar!['id_aviso'] : '0', 
        'opciones_multiples': opcionesMultiples,
      };
      
      // 2. Mostrar indicador de carga
      final snackBar = SnackBar(
        content: Row(
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(width: 20),
            Text('Guardando aviso...'),
          ],
        ),
        duration: const Duration(minutes: 5), // Larga duración
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });

      // 3. Llamar a la API a través del Provider
      final result = await userProvider.saveAviso(avisoDataParaProvider);

      // 4. Manejo de la respuesta
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
    // Lógica para eliminar el aviso
    // ignore: avoid_print
    print('Aviso eliminado');
    Navigator.pop(context); // Regresar a la pantalla de lista
  }

  // ⭐️ NUEVO: Constructor para los campos de texto de opciones múltiples ⭐️
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

  @override
  Widget build(BuildContext context) {
    // ACCESO AL PROVEEDOR DE COLOR
    final colores = Provider.of<UserProvider>(context).colores;
    final Color dynamicPrimaryColor = colores.footerColor;
    final Color dynamicHeaderColor = colores.headerColor;

    // DETERMINAR SI EL SEGUNDO COMBO DEBE MOSTRARSE
    final bool mostrarComboEspecifico = _opcionesEspecificas.containsKey(_destinatarioSeleccionado) && (_opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ?? false);
    
    // ⭐️ DETERMINAR SI LOS CAMPOS DE OPCIÓN MÚLTIPLE DEBEN MOSTRARSE (NUEVO) ⭐️
    final bool mostrarOpcionesMultiples = _respuestaSeleccionada == 'Seleccion multiple';

    return Scaffold(
      // ... (AppBar) ...
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
              // 1. Combo Destinatario Principal
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
              
              // 2. Combo Específico Condicional
              if (mostrarComboEspecifico) ...[
                const SizedBox(height: 20),
                _buildFiltroDropdown(
                  label: 'Seleccionar $_destinatarioSeleccionado',
                  value: _seleccionEspecifica!, 
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
              // Fechas
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
              // Combo Respuesta
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
              
              // ⭐️ 3. Campos de Opción Múltiple Condicionales (NUEVOS) ⭐️
              if (mostrarOpcionesMultiples) ...[
                const Text('Opciones de Respuesta Múltiple:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                _buildOpcionTextField(
                  controller: _opcion1Controller, 
                  label: 'Opción 1', 
                  dynamicPrimaryColor: dynamicPrimaryColor
                ),
                _buildOpcionTextField(
                  controller: _opcion2Controller, 
                  label: 'Opción 2', 
                  dynamicPrimaryColor: dynamicPrimaryColor
                ),
                _buildOpcionTextField(
                  controller: _opcion3Controller, 
                  label: 'Opción 3', 
                  dynamicPrimaryColor: dynamicPrimaryColor
                ),
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
              // Comentario
              TextFormField(
                controller: _cuerpoController,
                decoration: InputDecoration(
                  labelText: 'Comentario', 
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: dynamicPrimaryColor),
                ),
                maxLines: null,
                minLines: 5,
                keyboardType: TextInputType.multiline,
              ),
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
    );
  }

  // Modificado: value ahora es String?
  Widget _buildFiltroDropdown({
    required String label,
    required String? value, // Puede ser null si la lista específica está vacía
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
          // Si items está vacío o value es nulo, deshabilitamos el dropdown
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
          // Deshabilitar el onChanged si la lista está vacía o el valor inicial es nulo (no hay nada que seleccionar)
          onChanged: items.isEmpty || value == null ? null : onChanged, 
          validator: (val) {
             // Validar solo si la lista de ítems no está vacía y se requiere una selección
             if (items.isNotEmpty && val == null) {
                 return 'Debe seleccionar una opción.';
             }
             return null;
          }
        ),
      ],
    );
  }

  // Se mantiene sin cambios
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
}