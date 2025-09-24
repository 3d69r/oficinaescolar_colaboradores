import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Cambiamos a StatefulWidget para manejar el estado de la animación y la orientación
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  // Animación para el giro de la credencial
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;
  bool _isHorizontalCredential = false; // Estado para la orientación de la credencial

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  // Función para procesar el texto de la credencial y dividirlo en líneas
  List<Widget> _buildCredencialTextWidgets(String? textoCredencial) {
    if (textoCredencial == null || textoCredencial.isEmpty) {
      return [
        /*const Text(
          'Texto de la escuela',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        )*/
      ];
    }
    final List<String> lines = textoCredencial.split('|');

    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Text(
          line.trim(),
          textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 14),
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

          return Scaffold(
            appBar: AppBar(
              title: const Text('Mi Perfil', style: TextStyle(color: Colors.white)),
              backgroundColor: colores.headerColor,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Vertical'),
                      Switch(
                        value: _isHorizontalCredential,
                        onChanged: (value) {
                          setState(() {
                            _isHorizontalCredential = value;
                          });
                        },
                        activeTrackColor: colores.headerColor,
                      ),
                      const Text('Horizontal'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        final isUnderHalf = _animation.value < 0.5;
                        final rotationY = _animation.value * (isUnderHalf ? 3.14159 : -3.14159);
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(rotationY),
                          child: isUnderHalf
                              ? _buildFrontSide(colaborador, escuela, colores)
                              : Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..rotateY(3.14159),
                                  child: _buildBackSide(colaborador, escuela, colores),
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

   Widget _buildFrontSide(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) {
    return _isHorizontalCredential
        ? SingleChildScrollView( // <-- Permite el scroll horizontal
            scrollDirection: Axis.horizontal,
            child: SizedBox( // <-- Contenedor de ancho fijo para el scroll
                width: 400,
                child: _buildFrontHorizontal(colaborador, escuela, colores),
            ),
          )
        : _buildFrontVertical(colaborador, escuela, colores);
  }

  Widget _buildBackSide(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) {
    return _isHorizontalCredential
        ? SingleChildScrollView( // <-- Permite el scroll horizontal
            scrollDirection: Axis.horizontal,
            child: SizedBox( // <-- Contenedor de ancho fijo para el scroll
                width: 400,
                child: _buildBackHorizontal(colaborador, escuela, colores),
            ),
          )
        : _buildBackVertical(colaborador, escuela, colores);
  }

  Widget _buildFrontVertical(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) {
    return Container(
      width: 300,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        //color: colores.backgroundColor,
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
                colors: [colores.credHeaderColor2, colores.credHeaderColor2],
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
                  if (escuela.rutaLogo.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaLogo}',
                      width: 60,
                      height: 60,
                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => const Icon(Icons.school, color: Colors.white),
                    ),
                  const Spacer(),
                  const Text(
                    'CREDENCIAL DE IDENTIFICACIÓN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Text(
                  colaborador.nombreCompleto.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: colores.credLetraColor1, // <-- Se añade esta línea
                  ),
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 20),
                Text(
                  colaborador.curp,
                  style:  TextStyle(fontSize: 17,  letterSpacing: .5,fontWeight: FontWeight.bold, color: colores.credLetraColor1),
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 1),
                 Text(
                  'CURP',
                  style: const TextStyle(fontSize: 17,  letterSpacing: 2, fontWeight: FontWeight.bold ),
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 1),
                Text(
                  colaborador.escolaridad ?? 'N/A',
                  style:  TextStyle(fontSize: 17,  letterSpacing: .5,fontWeight: FontWeight.bold, color: colores.credLetraColor1 ),
                  overflow: TextOverflow.visible,
                ),
                
                const SizedBox(height: 1),
                Text(
                  'CURA',
                  style: const TextStyle(fontSize: 17,  letterSpacing: 2, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 5),
                Text(
                  colaborador.afiliacion ?? 'N/A',
                  style:  TextStyle(fontSize: 17,  fontWeight: FontWeight.bold, color: colores.credLetraColor1),
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 5),
                Text(
                  'VIGENTE HASTA',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontHorizontal(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) {
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
            height: 70,
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
                  if (escuela.rutaLogo.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaLogo}',
                      width: 60,
                      height: 60,
                      placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => const Icon(Icons.school, color: Colors.white),
                    ),
                  const Spacer(),
                  const Text(
                    'CREDENCIAL  DE IDENTIFICACIÓN',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
            child: Row(
              children: [
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        colaborador.nombreCompleto.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: colores.credHeaderColor1, 
                        ),
                        overflow: TextOverflow.visible,
                      ),
                      const SizedBox(height: 10),
                       // Uso de RichText para el CURP
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 17, color: Colors.black),
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'CURP: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: colaborador.curp ?? 'N/A',
                            style: TextStyle(color: colores.credLetraColor1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Uso de RichText para el CURA
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 17, color: Colors.black),
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'CURA: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: colaborador.escolaridad ?? 'N/A',
                            style: TextStyle(color: colores.credLetraColor1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Uso de RichText para la vigencia
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 17, color: Colors.black),
                        children: <TextSpan>[
                          const TextSpan(
                            text: 'VIGENTE HASTA: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: colaborador.afiliacion ?? 'N/A',
                            style: TextStyle(color: colores.credLetraColor1),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackVertical(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) {
  return Container(
    width: 300,
    height: 500,
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
            if (colaborador.curp != null && colaborador.curp!.isNotEmpty)
              QrImageView(
                data: colaborador.curp!,
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
                  children: _buildCredencialTextWidgets(
                    colaborador.message,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Franja blanca con la imagen
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            height: 70, // Altura de la franja
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: escuela.rutaFirma.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaFirma}',
                    fit: BoxFit.contain, 
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                  )
                : const Center(child: Text('Firma no disponible')), // Mensaje si no hay firma
          ),
        ),
      ],
    ),
  );
}


Widget _buildBackHorizontal(ColaboradorModel colaborador, EscuelaModel escuela, Colores colores) {
  return Container(
    width: 500,
    height: 250,
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildCredencialTextWidgets(
                    colaborador.message,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (colaborador.curp != null && colaborador.curp!.isNotEmpty)
                    QrImageView(
                      data: colaborador.curp!,
                      version: QrVersions.auto,
                      size: 120.0,
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
                ],
              ),
            ),
          ],
        ),
        // Franja blanca con la imagen
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 50, // Altura de la franja
            decoration: BoxDecoration(
              color: Colors.white,
              
            ),
            child: escuela.rutaFirma.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: '${ApiConstants.assetsBaseUrl}${escuela.rutaFirma}',
                    fit: BoxFit.contain, 
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 30),
                  )
                : const Center(child: Text('Firma no disponible')),
          ),
        ),
      ],
    ),
  );
}
}