import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart';
import 'package:oficinaescolar_colaboradores/utils/snackbar_util.dart';
import 'dart:io';
import 'package:flutter_html/flutter_html.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class CrearAvisoScreen extends StatefulWidget {
  final Map<String, dynamic>? avisoParaEditar;

  const CrearAvisoScreen({Key? key, this.avisoParaEditar}) : super(key: key);

  @override
  _CrearAvisoScreenState createState() => _CrearAvisoScreenState();
}

class _CrearAvisoScreenState extends State<CrearAvisoScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();

  // Controladores y variables de estado para los campos
  final _tituloController = TextEditingController();
  final HtmlEditorController _cuerpoEditorController = HtmlEditorController();
  final _opcion1Controller = TextEditingController();
  final _opcion2Controller = TextEditingController();
  final _opcion3Controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

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
      if (_seleccionEspecifica == null ||
          !opciones.contains(_seleccionEspecifica)) {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colaborador = userProvider.colaboradorModel;

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
          .map((a) => '${a.primerNombre} ${a.apellidoPat} (${a.idAlumno})')
          .toList();
      final List<String> listaColaboradores = colaborador.avisoColaboradores
          .map((c) => c.nombreCompleto)
          .toList();

      _opcionesEspecificas = {
        'Nivel Educativo': listaNiveles,
        'Salón': listaSalones,
        'Alumno Específico': listaAlumnos,
        'Colaborador Específico': listaColaboradores,
      };

      // ⭐️ NUEVO: id_maestro_titular o id_maestro_suplente distinto de "0"
      // en al menos un salón => el colaborador tiene salón(es) asignado(s).
      final bool tieneSalonAsignado = salonesAsignados.isNotEmpty;

      if (tieneSalonAsignado) {
        _destinatariosPrincipales = [
          if (listaSalones.isNotEmpty) 'Salón',
          if (listaAlumnos.isNotEmpty) 'Alumno Específico',
        ];
      } else {
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

      // 'Todos' es el valor por defecto de _destinatarioSeleccionado,
      // pero puede ya no existir en la lista filtrada. Lo corregimos aquí.
      if (widget.avisoParaEditar == null && _destinatariosPrincipales.isNotEmpty) {
        _destinatarioSeleccionado = _destinatariosPrincipales.first;
      }
    }

    if (widget.avisoParaEditar != null) {
      _tituloController.text =
          widget.avisoParaEditar!['titulo'] as String? ?? '';
      _initialHtmlContent =
          widget.avisoParaEditar!['comentario'] as String? ?? '';

      if (_initialHtmlContent.isNotEmpty) {
        _mostrarEditor = true;
      }

      _destinatarioSeleccionado =
          widget.avisoParaEditar!['destinatario_tipo'] as String? ?? 'Todos';

      final String apiRespuesta =
          widget.avisoParaEditar!['requiere_respuesta'] as String? ??
              'Ninguna';
      _respuestaSeleccionada =
          apiRespuesta == 'Seleccion' ? 'Seleccion multiple' : apiRespuesta;

      try {
        final String? fechaInicioStr =
            widget.avisoParaEditar!['fecha_inicio'] as String?;
        final String? fechaFinStr =
            widget.avisoParaEditar!['fecha_fin'] as String?;

        if (fechaInicioStr != null && fechaInicioStr.isNotEmpty) {
          _fechaInicio = DateTime.parse(fechaInicioStr);
        }
        if (fechaFinStr != null && fechaFinStr.isNotEmpty) {
          _fechaFin = DateTime.parse(fechaFinStr);
        }
      } catch (_) {}

      _seleccionEspecifica =
          widget.avisoParaEditar!['destinatario_valor'] as String?;

      final String? opciones =
          widget.avisoParaEditar!['opciones_multiples'] as String?;
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
            showModernSnackBar(context, 'El archivo es demasiado grande. Máximo 1 MB.', SnackType.error);
          }
          return;
        }

        if (mounted) {
          setState(() {
            _rutaArchivoAdjunto = pickedFile.path;
            _mostrarEditor = false;
          });

          _cuerpoEditorController.clear();

          showModernSnackBar(context, 'Archivo seleccionado: ${pickedFile.name}', SnackType.success);
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

      final file = File(picked.path);
      final int size = await file.length();

      if (size > maxFileSize) {
        if (mounted) {
          showModernSnackBar(context, 'La imagen es demasiado grande. Máximo 1 MB.', SnackType.error);
        }
        return;
      }

      setState(() {
        _rutaArchivoAdjunto = picked.path;
        _mostrarEditor = false;
      });
      _cuerpoEditorController.clear();

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

  void _prepararYMostrarPreview() async {
    if (!_formKey.currentState!.validate()) return;

    String cuerpoHtml = '';

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
        showModernSnackBar(context, 'Ingresa al menos dos opciones para la Selección Múltiple.', SnackType.warning);
        return;
      }
    }

    final bool esDestinatarioEspecifico =
        _opcionesEspecificas.containsKey(_destinatarioSeleccionado);
    final bool hayOpcionesDisponibles =
        _opcionesEspecificas[_destinatarioSeleccionado]?.isNotEmpty ?? false;
    final String? destinatarioValor =
        (esDestinatarioEspecifico && hayOpcionesDisponibles && _seleccionEspecifica != null)
            ? _seleccionEspecifica
            : null;

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

    if (!mounted) return;
    _mostrarPreviewAviso(avisoDataParaProvider);
  }

  void _publicarAviso(Map<String, dynamic> avisoDataParaProvider) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String idAviso = avisoDataParaProvider['id_calendario'] as String? ?? '0';

      print('--- CREACIÓN/EDICIÓN DE AVISO (ID: $idAviso) ---');
      print('Datos enviados al Provider: $avisoDataParaProvider');
      print('-------------------------------------------');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModernSnackBar(context, 'Guardando aviso...', SnackType.loading);
      });

      final result = await userProvider.saveAviso(avisoDataParaProvider);

      if (!mounted) return;

      showModernSnackBar(
        context,
        result['message'],
        result['success'] ? SnackType.success : SnackType.error,
      );

      if (result['success']) {
        Navigator.pop(context); // cierra CrearAvisoScreen
      }
    }

  void _mostrarPreviewAviso(Map<String, dynamic> avisoData) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;
    final String? archivo = avisoData['archivo'] as String?;
    final String cuerpo = avisoData['cuerpo'] as String? ?? '';
    final bool tieneArchivo = archivo != null && archivo.isNotEmpty;
    final bool esPdf = tieneArchivo && archivo.toLowerCase().endsWith('.pdf');
    final String tipoRespuesta = avisoData['requiere_respuesta'] as String? ?? 'Ninguna';
    final List<String> opcionesPreview = avisoData['opciones_multiples'] != null &&
            (avisoData['opciones_multiples'] as String).isNotEmpty
        ? (avisoData['opciones_multiples'] as String).split(',').map((e) => e.trim()).toList()
        : <String>[];

    showDialog(
      context: context,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final screenHeight = MediaQuery.of(dialogContext).size.height;
        final dialogWidth = screenWidth * 0.90;
        final dialogHeight = screenHeight * 0.95;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                // --- Encabezado, idéntico al de AvisosView._mostrarAviso ---
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
                    avisoData['titulo'] as String? ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),

                // --- Contenido, mismo layout que el detalle real ---
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
                              'Del ${avisoData['fecha_inicio']} al ${avisoData['fecha_fin']}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFFE5E7EB), thickness: 1),
                        const SizedBox(height: 10),

                        // Contenido: imagen / pdf (sin nombre de archivo) / html
                        if (tieneArchivo)
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: esPdf
                                      ? SizedBox(
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: SfPdfViewer.file(
                                            File(archivo!),
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
                                          child: Image.file(
                                            File(archivo),
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Text('No se pudo cargar la imagen.', textAlign: TextAlign.center),
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

                        // --- Sección de respuesta, mismo estilo que el detalle real ---
                        if (tipoRespuesta.toLowerCase() == 'siono' || tipoRespuesta.toLowerCase() == 'seleccion')
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
                                  'Este aviso pedirá una respuesta:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 12),
                                if (tipoRespuesta.toLowerCase() == 'siono')
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: OutlinedButton(
                                            onPressed: null,
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(color: colores.botonesColor.withOpacity(0.4)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('Sí'),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: OutlinedButton(
                                            onPressed: null,
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              side: BorderSide(color: colores.botonesColor.withOpacity(0.4)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: const Text('No'),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (tipoRespuesta.toLowerCase() == 'seleccion')
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

                // --- Botones: mismo patrón que ya tenías (editar / publicar) ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Seguir editando'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _publicarAviso(avisoData);
                          },
                          icon: const Icon(Icons.publish_rounded),
                          label: const Text('Publicar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colores.botonesColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
  void _eliminarAviso() {
    print('Aviso eliminado');
    Navigator.pop(context, true);
  }

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

  // ⭐️ Card de sección reutilizable para el nuevo diseño ⭐️
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F5FA),
          appBar: AppBar(
            title: Text(widget.avisoParaEditar == null
                ? 'Crear Aviso'
                : 'Editar Aviso'),
            titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            backgroundColor: dynamicHeaderColor,
            centerTitle: true,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            actions: widget.avisoParaEditar != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: _eliminarAviso,
                      tooltip: 'Eliminar aviso',
                      color: Colors.white,
                    ),
                  ]
                : null,
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
                      if (_rutaArchivoAdjunto != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            children: [
                              if (!_rutaArchivoAdjunto!.toLowerCase().endsWith('.pdf'))
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_rutaArchivoAdjunto!),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.broken_image_rounded,
                                      color: Colors.blue.shade300,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.picture_as_pdf_rounded, color: Colors.red.shade400),
                                ),
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
                                onPressed: () =>
                                    setState(() => _rutaArchivoAdjunto = null),
                              ),
                            ],
                          ),
                        ),

                      // Editor de comentario
                      if (_mostrarEditor) ...[
                        if (_rutaArchivoAdjunto != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16, color: Colors.orange.shade700),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'El archivo adjunto se eliminará al guardar si escribes un comentario.',
                                    style: TextStyle(
                                        color: Colors.orange, fontSize: 12.5),
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
                            initialText: _initialHtmlContent,
                            darkMode: Theme.of(context).brightness ==
                                Brightness.dark,
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
                        onPressed: _prepararYMostrarPreview,
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Guardar Aviso',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
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
            Icon(icon, size: 19, color: selected ? Colors.white : Colors.grey.shade500),
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
        DropdownButtonFormField<String>(
          value: value,
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
          isExpanded: true,
          items: items.map<DropdownMenuItem<String>>((String itemValue) {
            return DropdownMenuItem<String>(
              value: itemValue,
              child: Text(itemValue, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: items.isEmpty || value == null ? null : onChanged,
          validator: (val) {
            if (items.isNotEmpty && val == null) {
              return 'Debe seleccionar una opción.';
            }
            return null;
          },
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
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
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