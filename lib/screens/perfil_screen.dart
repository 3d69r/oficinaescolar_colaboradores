import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Importación necesaria para abrir enlaces

// Cambiamos a StatefulWidget para manejar el estado de la animación y la orientación
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  // Animación para el giro de la credencial
  late AnimationController _controladorAnimacion; // Renombrado
  late Animation<double> _animacionGiro; // Renombrado
  bool _esFrente = true; // Renombrado

  @override
  void initState() {
    super.initState();
    _controladorAnimacion = AnimationController( // Renombrado
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animacionGiro = Tween<double>( // Renombrado
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controladorAnimacion, curve: Curves.easeInOut)); // Renombrado
  }

  @override
  void dispose() {
    _controladorAnimacion.dispose(); // Renombrado
    super.dispose();
  }

  void _girarCredencial() { // Renombrado
    if (_esFrente) {
      _controladorAnimacion.forward();
    } else {
      _controladorAnimacion.reverse();
    }
    setState(() {
      _esFrente = !_esFrente;
    });
  }

  // --- FUNCIÓN PARA ABRIR EL ENLACE DEL QR ---
  Future<void> _abrirUrl(String url, BuildContext context) async { // Renombrado
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El campo del QR está vacío o no es un enlace válido.')),
      );
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace: $url')),
      );
    }
  }
  // --- FIN DE FUNCIÓN ---

  // --- LÓGICA DINÁMICA DE CAMPOS ---
  
 List<Map<String, String>> _obtenerCamposCredencial(
      ColaboradorModel colaborador, EscuelaModel escuela) {
    
    // ⚠️ Se ignora la variable 'escuela' y su configuración, ya que los campos son fijos.
    
    final List<Map<String, String>> fields = [];

    // 1. CURP (Campo fijo)
    fields.add({
      'label': 'CURP',
      'value': colaborador.curp,
    });

    // 2. PUESTO (Campo fijo)
    fields.add({
      'label': 'PUESTO',
      'value': colaborador.puesto,
    });

    // 3. VIGENTE HASTA (Campo fijo, que antes se añadía al final)
    fields.add({
      'label': 'VIGENTE HASTA', 
      'value': escuela.cicloEscolar.fechaTermino,
    });

    return fields;
  }
  
  // Función para procesar el texto de la credencial y dividirlo en líneas
  List<Widget> _construirWidgetsTextoCredencial(String? textoCredencial, Colores colores) { // Renombrado
    if (textoCredencial == null || textoCredencial.isEmpty) {
      return [];
    }
    final List<String> lines = textoCredencial.split('|');

    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          line.trim(),
          textAlign: TextAlign.justify,
          style:  TextStyle(fontSize: 14, color: colores.credLetraColor2,),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final colores = userProvider.colores;
          final ColaboradorModel? colaborador = userProvider.currentColaboradorDetails;
          final EscuelaModel? escuela = userProvider.escuelaModel;

          if (colaborador == null || escuela == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
                backgroundColor: colores.headerColor,
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.white),
              ),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          
          final bool esGandhi = escuela.nombreComercial.toLowerCase().contains('gandhi'); // Condición

          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
              backgroundColor: colores.headerColor,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Center( 
                child: Column(
                  children: [
                    // --- SWITCH PARA GIRAR LA CREDENCIAL ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_esFrente ? 'Frente' : 'Reverso'),
                        Switch(
                          value: !_esFrente, 
                          onChanged: (value) {
                            _girarCredencial();
                          },
                          activeTrackColor: colores.headerColor,
                        ),
                        Text(_esFrente ? 'Reverso' : 'Frente'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Contenedor de la Credencial
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300, maxHeight: 500), 
                      child: GestureDetector(
                        onTap: _girarCredencial, 
                        child: AnimatedBuilder(
                          animation: _animacionGiro, 
                          builder: (context, child) {
                            final isUnderHalf = _animacionGiro.value < 0.5;
                            final rotationY = _animacionGiro.value * (isUnderHalf ? 3.14159 : -3.14159);
                            
                            Widget currentWidget = isUnderHalf
                                ? _obtenerCredencialFrontal(colaborador, escuela, colores, esGandhi) // Cambio aquí
                                : Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()..rotateY(3.14159),
                                    child: _obtenerCredencialReversa(colaborador, escuela, colores, esGandhi), // Cambio aquí
                                  );

                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(rotationY),
                              child: currentWidget,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // --- BOTÓN VALIDAR CREDENCIAL ---
                    if (colaborador.idCredencial.isNotEmpty)
                      SizedBox(
                        width: 250, 
                        child: ElevatedButton(
                          onPressed: () => _abrirUrl(colaborador.idCredencial, context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colores.botonesColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Validar Credencial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // --- FIN BOTÓN VALIDAR CREDENCIAL ---

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  //  METODOS DE DECISIÓN (CONDICIONAL)
  // =========================================================================

  Widget _obtenerCredencialFrontal(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores, bool esGandhi) {
    if (esGandhi) {
      return _construirFrenteVerticalGandhi(colaborador, escuela, colores);
    }
    return _construirFrenteVerticalDefault(colaborador, escuela, colores);
  }

  Widget _obtenerCredencialReversa(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores, bool esGandhi) {
    if (esGandhi) {
      return _construirReversoVerticalGandhi(colaborador, escuela, colores);
    }
    return _construirReversoVerticalDefault(colaborador, escuela, colores);
  }


  // =========================================================================
  //  DISEÑO GANDHI (LOGO CENTRADO, FRANJA TRICOLOR)
  // =========================================================================
  
  Widget _construirFrenteVerticalGandhi(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) { // Renombrado
    final List<Map<String, String>> fields = _obtenerCamposCredencial(colaborador, escuela);
    const double stripeHeight = 5.0; 
    const double radius = 15.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 65, 62, 62),
            offset: const Offset(5, 15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- ENCABEZADO (Logo Centrado) ---
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [colores.credHeaderColor1, colores.credHeaderColor2],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
              ),
            ),
            child: Center( 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    if (escuela.rutaLogoCred.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaLogoCred}',
                        width: 150,
                        height: 100,
                        placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                        errorWidget: (context, url, error) => const Icon(Icons.school, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // --- FIN ENCABEZADO ---

          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: colaborador.rutaFoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.assetsBaseUrl}${colaborador.rutaFoto}',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 20),
          Expanded( 
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      colaborador.nombreCompleto.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: colores.credLetraColor1,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 20),
                    
                    // LÓGICA DINÁMICA DE CAMPOS (VERTICAL)
                    ...fields.map((field) {
                      return Column(
                        children: [
                          // 1. ETIQUETA (LABEL): EN NEGRITAS
                          Text(
                            field['label']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17, 
                              letterSpacing: 2, 
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 1),
                          // 2. VALOR (VALUE): NORMAL
                          Text(
                            field['value']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17, 
                              letterSpacing: .5, 
                              color: colores.credLetraColor1,
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 5),
                        ],
                      );
                    }).toList(),
                    
                  ],
                ),
              ),
            ),
          ),
          // --- FRANJA TRICOLOR (Sin degradado, con bordes curvos) ---
          Container(
            height: stripeHeight, 
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colores.credHeaderColor2,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: colores.botonesColor,
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colores.credHeaderColor1,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(radius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // --- FIN NUEVA FRANJA TRICOLOR ---
        ],
      ),
    );
}

  Widget _construirReversoVerticalGandhi(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) { // Renombrado
    const double stripeHeight = 5.0;
    const double radius = 15.0; 

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [colores.credHeaderColor1, colores.credHeaderColor2],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 65, 62, 62),
            offset: const Offset(5, 15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Contenido principal (QR e información)
          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (colaborador.idCredencial.isNotEmpty)
                  QrImageView(
                    data: colaborador.idCredencial,
                    version: QrVersions.auto,
                    size: 150.0,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _construirWidgetsTextoCredencial(
                        escuela.appTextoCred, colores
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: stripeHeight), 
              ],
            ),
          ),
          
          // --- FRANJA TRICOLOR AGREGADA Y POSICIONADA ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: stripeHeight, 
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colores.credHeaderColor2,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(radius),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: colores.botonesColor,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colores.credHeaderColor1,
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(radius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  DISEÑO DEFAULT (LOGO Y TEXTO, FRANJA BLANCA CON FIRMA)
  // =========================================================================

  Widget _construirFrenteVerticalDefault(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) { // Renombrado
    final List<Map<String, String>> fields = _obtenerCamposCredencial(colaborador, escuela);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 65, 62, 62),
            offset: const Offset(5, 15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [colores.credHeaderColor1, colores.credHeaderColor2],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (escuela.rutaLogoCred.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaLogoCred}',
                      width: 60,
                      height: 60,
                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => const Icon(Icons.school, color: Colors.white),
                    ),
                  const Spacer(),
                  const Text(
                    'CREDENCIAL DE IDENTIFICACIÓN',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: colaborador.rutaFoto.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.assetsBaseUrl}${colaborador.rutaFoto}',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 20),
          Expanded( 
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Text(
                      colaborador.nombreCompleto.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: colores.credLetraColor1,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 20),
                    
                    // LÓGICA DINÁMICA DE CAMPOS (VERTICAL)
                    ...fields.map((field) {
                      return Column(
                        children: [
                          Text(
                            field['label']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17, 
                              letterSpacing: 2, 
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            field['value']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15, 
                              letterSpacing: .5, 
                              color: colores.credLetraColor1,
                              fontWeight: FontWeight.normal, 
                            ),
                            overflow: TextOverflow.visible,
                          ),
                          const SizedBox(height: 5), 
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirReversoVerticalDefault(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) { // Renombrado
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [colores.credHeaderColor1, colores.credHeaderColor2],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 65, 62, 62),
            offset: const Offset(5, 15),
            blurRadius: 30,
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (colaborador.idCredencial.isNotEmpty)
                QrImageView(
                  data: colaborador.idCredencial,
                  version: QrVersions.auto,
                  size: 150.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _construirWidgetsTextoCredencial(
                      escuela.appTextoCred, colores
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Franja blanca con la imagen (ORIGINAL)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              height: 70, 
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: escuela.rutaFirma.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaFirma}',
                      fit: BoxFit.contain, 
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                    )
                  : const Center(child: Text('Firma no disponible')), 
            ),
          ),
        ],
      ),
    );
  }
}