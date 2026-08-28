import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:oficinaescolar_colaboradores/utils/snackbar_util.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart'; // agregar import

import 'package:flutter/foundation.dart' show kIsWeb;


// ----------------------------------------------------------------------
// ESTA VISTA SOLO SE ENCARGA DE EDITAR Y ELIMINAR AVISOS EXISTENTES
// ----------------------------------------------------------------------

class EditarAvisoScreen extends StatefulWidget {
  final Map<String, dynamic> avisoParaEditar;

  const EditarAvisoScreen({Key? key, required this.avisoParaEditar})
      : super(key: key);

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
  final ImagePicker _imagePicker = ImagePicker();

  // Estado
  List<String> _destinatariosPrincipales = ['Todos'];
  String _destinatarioSeleccionado = 'Todos';
  Map<String, List<String>> _opcionesEspecificas = {};
  Map<String, String> _idAlumnoPorNombre = {}; // ⭐️ NUEVO
  String? _seleccionEspecifica;
  String _respuestaSeleccionada = 'Ninguna';

  // Fechas
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();

  String _initialHtmlContent = '';

  // ⭐️ ESTADOS PARA CONTROL DE ARCHIVO/COMENTARIO ⭐️
  bool _mostrarEditor = false;
  String? _rutaArchivoAdjunto;
  Uint8List? _archivoBytes;
  String? _archivoNombre;

  bool _esArchivoRemoto = false;
  // ----------------------------------------------------

  @override
  void initState() {
    super.initState();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colaborador = userProvider.colaboradorModel;
    final aviso = widget.avisoParaEditar;

    // 1. Configurar listas de destinatarios (se mantiene igual)
    if (colaborador != null) {
      final List<String> listaNiveles = colaborador.avisoNivelesEducativos
          .map((n) => n.nivelEducativo)
          .toList();
      final String idColaboradorActual = userProvider.idColaborador;
      final List<AvisoSalaModel> salonesAsignados = colaborador.avisoSalones
          .where((s) =>
              s.idMaestroTitular == idColaboradorActual ||
              s.idMaestroSuplente == idColaboradorActual)
          .toList();
      final List<AvisoSalaModel> salonesParaMostrar =
          salonesAsignados.isNotEmpty ? salonesAsignados : colaborador.avisoSalones;
      final List<String> listaSalones =
          salonesParaMostrar.map((s) => s.salon).toList();
      final List<String> listaAlumnos = colaborador.avisoAlumnos
          .map((a) => '${a.primerNombre} ${a.apellidoPat}')
          .toList();

      // ⭐️ NUEVO: mapa nombre -> id_alumno (para resolver sin depender del texto visible)
      _idAlumnoPorNombre = {
        for (var a in colaborador.avisoAlumnos)
          '${a.primerNombre} ${a.apellidoPat}': a.idAlumno
      };

      final List<String> listaColaboradores = colaborador.avisoColaboradores
          .map((c) => c.nombreCompleto)
          .toList();

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
      _rutaArchivoAdjunto = archivoAdjuntoApi;
      _esArchivoRemoto = true;
      _mostrarEditor = false;
    } else if (_initialHtmlContent.isNotEmpty) {
      _mostrarEditor = true;
      _rutaArchivoAdjunto = null;
    } else {
      _mostrarEditor = false;
      _rutaArchivoAdjunto = null;
    }

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

    final String apiRespuesta =
        aviso['tipo_respuesta'] as String? ?? 'Ninguna';
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

    if (opcion1 != null && opcion1.isNotEmpty) {
      _opcion1Controller.text = opcion1;
    }
    if (opcion2 != null && opcion2.isNotEmpty) {
      _opcion2Controller.text = opcion2;
    }
    if (opcion3 != null && opcion3.isNotEmpty) {
      _opcion3Controller.text = opcion3;
    }

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

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile pickedFile = result.files.single;

        if (pickedFile.size > maxFileSize) {
          if (mounted) {
            showModernSnackBar(context, 'El archivo es demasiado grande. Máximo 1 MB.', SnackType.error);
          }
          return;
        }

        if (kIsWeb && pickedFile.bytes == null) {
          if (mounted) {
            showModernSnackBar(context, 'No se pudo leer el archivo seleccionado.', SnackType.error);
          }
          return;
        }

        setState(() {
          if (kIsWeb) {
            _archivoBytes = pickedFile.bytes;
            _archivoNombre = pickedFile.name;
            _rutaArchivoAdjunto = pickedFile.name; // solo para mostrar en UI
          } else {
            _rutaArchivoAdjunto = pickedFile.path;
            _archivoBytes = null;
            _archivoNombre = null;
          }
          _mostrarEditor = false;
          _esArchivoRemoto = false;
          _cuerpoEditorController.clear();
          _initialHtmlContent = '';
        });

        if (mounted) {
          showModernSnackBar(context, 'Archivo seleccionado: ${pickedFile.name}', SnackType.success);
        }
      }
    } catch (e) {
      // Manejo de error
    }
  }

  void _mostrarMenuAdjuntar(Color colorPrimario) {
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
                'Adjuntar archivo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.camera);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(Icons.photo_camera_rounded, color: colorPrimario),
                title: const Text('Tomar foto'),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen(ImageSource.gallery);
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(Icons.photo_library_rounded, color: colorPrimario),
                title: const Text('Elegir de galería'),
              ),
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarArchivo();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(Icons.picture_as_pdf_rounded, color: colorPrimario),
                title: const Text('Elegir documento (PDF)'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    const int maxFileSize = 1048576;
    try {
      final XFile? picked = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();

      if (bytes.length > maxFileSize) {
        if (mounted) {
          showModernSnackBar(context, 'La imagen es demasiado grande. Máximo 1 MB.', SnackType.error);
        }
        return;
      }

      setState(() {
        if (kIsWeb) {
          _archivoBytes = bytes;
          _archivoNombre = picked.name;
          _rutaArchivoAdjunto = picked.name; // solo para mostrar en UI
        } else {
          _rutaArchivoAdjunto = picked.path;
          _archivoBytes = null;
          _archivoNombre = null;
        }
        _mostrarEditor = false;
        _cuerpoEditorController.clear();
        _initialHtmlContent = '';
      });

      if (mounted) {
        showModernSnackBar(context, 'Imagen adjuntada correctamente', SnackType.success);
      }
    } catch (e) {
      if (mounted) {
        showModernSnackBar(context, 'No se pudo tomar/seleccionar la foto', SnackType.error);
      }
    }
  }
  void _mostrarEditorComentario() {
    setState(() {
      _mostrarEditor = true;
      _rutaArchivoAdjunto = null;
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
      if (_seleccionEspecifica == null ||
          !opciones.contains(_seleccionEspecifica!)) {
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        final Color dynamicPrimaryColor =
            Provider.of<UserProvider>(context, listen: false)
                .colores
                .headerColor;
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: dynamicPrimaryColor,
            colorScheme: ColorScheme.light(primary: dynamicPrimaryColor),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
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
        showModernSnackBar(context, 'Escribe un comentario o adjunta un archivo (PDF/Imagen).', SnackType.warning);
        return;
      }

      if (_mostrarEditor) {
        cuerpoHtml = await _cuerpoEditorController.getText();

        if (cuerpoHtml.trim().isEmpty || cuerpoHtml.trim() == '<p><br></p>') {
          showModernSnackBar(context, 'El campo de comentario no puede estar vacío.', SnackType.warning);
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
        if (_opcion1Controller.text.isNotEmpty) {
          opciones.add(_opcion1Controller.text.trim());
        }
        if (_opcion2Controller.text.isNotEmpty) {
          opciones.add(_opcion2Controller.text.trim());
        }
        if (_opcion3Controller.text.isNotEmpty) {
          opciones.add(_opcion3Controller.text.trim());
        }
        opcionesMultiples = opciones.join(',');

        if (opciones.length < 2) {
          showModernSnackBar(context, 'Ingresa al menos dos opciones para la Selección Múltiple.', SnackType.warning);
          return;
        }
      }

      // Lógica de destinatario específico (mantenida)
      final bool esDestinatarioEspecifico =
          _opcionesEspecificas.containsKey(_destinatarioSeleccionado);
      final bool hayOpcionesDisponibles =
          _opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ??
              false;
      final String? destinatarioValor;

      if (esDestinatarioEspecifico &&
          hayOpcionesDisponibles &&
          _seleccionEspecifica != null) {
        destinatarioValor = _seleccionEspecifica;
      } else {
        destinatarioValor = null;
      }

      // ⭐️ NUEVO: resolver el id_alumno real a partir del nombre seleccionado
      final String? destinatarioIdAlumno =
          (_destinatarioSeleccionado == 'Alumno Específico' && destinatarioValor != null)
              ? _idAlumnoPorNombre[destinatarioValor]
              : null;

      final String idAviso =
          widget.avisoParaEditar['id_calendario']?.toString() ??
          widget.avisoParaEditar['id_aviso']?.toString() ??
          '0';

      final avisoDataParaProvider = {
        'titulo': _tituloController.text,
        'cuerpo': _rutaArchivoAdjunto != null ? '' : cuerpoHtml, // Enviar cuerpo vacío si hay archivo
        'destinatario_tipo': _destinatarioSeleccionado,
        'destinatario_valor': destinatarioValor,
        'destinatario_id_alumno': destinatarioIdAlumno, // ⭐️ NUEVO
        'requiere_respuesta': tipoRespuestaAPI,
        'fecha_inicio': _fechaInicio.toIso8601String().substring(0, 10),
        'fecha_fin': _fechaFin.toIso8601String().substring(0, 10),
        'id_calendario': idAviso,
        'opciones_multiples': opcionesMultiples,
        'archivo': _rutaArchivoAdjunto, // ⭐️ Ruta del archivo ⭐️
      };

      print('--- EDICIÓN DE AVISO (ID: $idAviso) ---');
      print('Datos enviados al Provider: $avisoDataParaProvider');
      print('-------------------------------------------');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModernSnackBar(context, 'Actualizando aviso...', SnackType.loading);
      });

      final result = await userProvider.saveAviso(
        avisoDataParaProvider,
        archivoBytes: kIsWeb ? _archivoBytes : null,
        archivoNombre: kIsWeb ? _archivoNombre : null,
      );

      if (!mounted) return;

      showModernSnackBar(
        context,
        result['message'],
        result['success'] ? SnackType.success : SnackType.error,
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
        color: dynamicPrimaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: dynamicPrimaryColor.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
      child: ToolbarWidget(
        controller: _cuerpoEditorController,
        callbacks: Callbacks(),
        htmlToolbarOptions: HtmlToolbarOptions(
          defaultToolbarButtons: _toolbarButtons,
        ),
      ),
    );
  }

  // Definición de botones para el ToolbarWidget (se mantiene igual)
  final List<Toolbar> _toolbarButtons = const [
    FontButtons(strikethrough: false, subscript: false, superscript: false),
    FontSettingButtons(fontSize: true, fontName: false),
    StyleButtons(),
    ColorButtons(),
    ParagraphButtons(textDirection: false, lineHeight: false, caseConverter: false),
    ListButtons(listStyles: true),
    InsertButtons(link: true, picture: true, audio: false, video: false, table: false, hr: false),
  ];

  // ⭐️ Card de sección reutilizable, en línea con CrearAvisoScreen ⭐️
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF1E1E2C)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 19, color: selected ? Colors.white : Colors.grey.shade500),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchivoPreview() {
  final String? ruta = _rutaArchivoAdjunto;
  if (ruta == null) return const SizedBox.shrink();

  final bool esPdf = ruta.toLowerCase().endsWith('.pdf');

  if (esPdf) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red.shade400),
    );
  }

  if (_esArchivoRemoto) {
    final String url = ruta.toLowerCase().startsWith('http')
        ? ruta
        : ApiConstants.assetsBaseUrl +
            (ruta.startsWith('/') ? ruta.substring(1) : ruta);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_rounded,
          color: Colors.blue.shade300,
        ),
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: kIsWeb && _archivoBytes != null
        ? Image.memory(
            _archivoBytes!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image_rounded,
              color: Colors.blue.shade300,
            ),
          )
        : Image.file(
            File(ruta),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image_rounded,
              color: Colors.blue.shade300,
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

    final bool mostrarComboEspecifico =
        _opcionesEspecificas.containsKey(_destinatarioSeleccionado) &&
            (_opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ??
                false);
    final bool mostrarOpcionesMultiples =
        _respuestaSeleccionada == 'Seleccion multiple';

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5FA),
        appBar: AppBar(
          title: const Text('Editar Aviso'),
          titleTextStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
          backgroundColor: dynamicHeaderColor,
          centerTitle: true,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _eliminarAviso,
              tooltip: 'Eliminar aviso',
              color: Colors.white,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ------- SECCIÓN: DESTINATARIOS -------
                _buildSectionCard(
                  title: 'Destinatarios',
                  icon: Icons.groups_rounded,
                  accentColor: dynamicPrimaryColor,
                  children: [
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
                      const SizedBox(height: 16),
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
                  ],
                ),

                // ------- SECCIÓN: VIGENCIA -------
                _buildSectionCard(
                  title: 'Vigencia',
                  icon: Icons.date_range_rounded,
                  accentColor: dynamicPrimaryColor,
                  children: [
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
                        const SizedBox(width: 12),
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
                  ],
                ),

                // ------- SECCIÓN: RESPUESTA -------
                _buildSectionCard(
                  title: 'Respuesta',
                  icon: Icons.question_answer_rounded,
                  accentColor: dynamicPrimaryColor,
                  children: [
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
                    if (mostrarOpcionesMultiples) ...[
                      const SizedBox(height: 16),
                      _buildOpcionTextField(
                          controller: _opcion1Controller,
                          label: 'Opción 1',
                          dynamicPrimaryColor: dynamicPrimaryColor),
                      _buildOpcionTextField(
                          controller: _opcion2Controller,
                          label: 'Opción 2',
                          dynamicPrimaryColor: dynamicPrimaryColor),
                      _buildOpcionTextField(
                          controller: _opcion3Controller,
                          label: 'Opción 3',
                          dynamicPrimaryColor: dynamicPrimaryColor),
                    ],
                  ],
                ),

                // ------- SECCIÓN: CONTENIDO -------
                _buildSectionCard(
                  title: 'Contenido',
                  icon: Icons.article_rounded,
                  accentColor: dynamicPrimaryColor,
                  children: [
                    TextFormField(
                      controller: _tituloController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        labelText: 'Título',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: dynamicPrimaryColor, width: 2.0),
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
                    const SizedBox(height: 18),

                    // ⭐️ Selector segmentado: Archivo vs Comentario ⭐️
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F1F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSegmentButton(
                              label: 'Adjuntar archivo',
                              icon: Icons.attach_file_rounded,
                              selected: !_mostrarEditor,
                              color: dynamicPrimaryColor,
                              onTap: () => _mostrarMenuAdjuntar(dynamicPrimaryColor),
                            ),
                          ),
                          Expanded(
                            child: _buildSegmentButton(
                              label: 'Escribir comentario',
                              icon: Icons.edit_note_rounded,
                              selected: _mostrarEditor,
                              color: dynamicPrimaryColor,
                              onTap: _mostrarEditorComentario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Estado de archivo adjunto
                    if (_rutaArchivoAdjunto != null &&
                        _rutaArchivoAdjunto!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
child: Row(
  children: [
    _buildArchivoPreview(),
    const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    'Archivo adjunto: ${_rutaArchivoAdjunto!.split('/').last}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700))),
                            IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.red.shade400, size: 20),
                              onPressed: () => setState(() {
                                _rutaArchivoAdjunto = null;
                                _archivoBytes = null;
                                _archivoNombre = null;
                              }),
                            ),
                          ],
                        ),
                      ),

                    // Editor de comentario
                    if (_mostrarEditor) ...[
                      if (_rutaArchivoAdjunto != null &&
                          _rutaArchivoAdjunto!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 16, color: Colors.orange.shade700),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'Al guardar, se enviará el comentario y se ignorará el archivo.',
                                  style:
                                      TextStyle(color: Colors.orange, fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildCustomToolbar(context, dynamicPrimaryColor),
                      const SizedBox(height: 10),
                      HtmlEditor(
                        controller: _cuerpoEditorController,
                        htmlEditorOptions: HtmlEditorOptions(
                          hint: "Escriba aquí el cuerpo del aviso...",
                          initialText: _initialHtmlContent.isNotEmpty
                              ? _initialHtmlContent
                              : null,
                          darkMode:
                              Theme.of(context).brightness == Brightness.dark,
                          adjustHeightForKeyboard: true,
                        ),
                        htmlToolbarOptions: const HtmlToolbarOptions(
                          toolbarPosition: ToolbarPosition.custom,
                          toolbarType: ToolbarType.nativeGrid,
                        ),
                        otherOptions: OtherOptions(
                          height: 380,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),
                // Botón de guardar (alineado a la derecha)
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _guardarAviso,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Guardar Cambios',
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dynamicPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para Dropdown
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
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        DropdownButtonFormField2<String>(
          isExpanded: true,
          valueListenable: ValueNotifier<String?>(value),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
            ),
          ),
          items: items.map<DropdownItem<String>>((String itemValue) {
            return DropdownItem<String>(
              value: itemValue,
              child: Text(
                itemValue,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
          validator: (val) {
            if (items.isNotEmpty && val == null) {
              return 'Debe seleccionar una opción.';
            }
            return null;
          },
          dropdownStyleData: DropdownStyleData(
            maxHeight: 280,
            offset: const Offset(0, -4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ],
    );
  }

  // Widget para entrada de fecha
  Widget _buildDateInput({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required Color dynamicPrimaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: dynamicPrimaryColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Widget para opciones múltiples
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
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: dynamicPrimaryColor, width: 2.0),
          ),
          labelStyle: TextStyle(color: dynamicPrimaryColor),
        ),
      ),
    );
  }
}