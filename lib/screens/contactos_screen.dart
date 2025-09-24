import 'package:flutter/material.dart';
import 'package:oficinaescolar_colaboradores/models/colores_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';

//ESTA VISTA SE DEBE CORREGIR EL FILTRADO

class ContactosScreen extends StatefulWidget {
  const ContactosScreen({super.key});

  @override
  State<ContactosScreen> createState() => _ContactosScreenState();
}

class _ContactosScreenState extends State<ContactosScreen>
    with AutomaticKeepAliveClientMixin {
  String? _errorMessage;
  bool _isLoading = false;
  DateTime? _lastManualRefreshTime;

  late UserProvider _userProvider;
  late VoidCallback _autoRefreshListener;
  Timer? _autoRefreshTimer;

  late UserProvider userProvider;
  late Colores colores;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'ContactosScreen: initState - Inicializando pantalla de contactos.',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userProvider = Provider.of<UserProvider>(context, listen: false);

      _autoRefreshListener = () {
        debugPrint(
          'ContactosScreen: Gatillo de auto-refresco del UserProvider detectado. Recargando contactos...',
        );
        _loadContactos(forceReload: true);
      };

      _userProvider.autoRefreshTrigger.addListener(_autoRefreshListener);

      _loadContactos(forceReload: false);
      _startAutoRefreshTimer();
    });
  }

  @override
  void dispose() {
    debugPrint(
      'ContactosScreen: dispose - Cancelando temporizador de auto-refresco y removiendo listeners.',
    );
    _autoRefreshTimer?.cancel();
    _userProvider.autoRefreshTrigger.removeListener(_autoRefreshListener);
    super.dispose();
  }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: ApiConstants.minutosRecarga),
      (timer) {
        debugPrint(
          'ContactosScreen: Disparando auto-refresco por temporizador (${ApiConstants.minutosRecarga} minutos).',
        );
        _loadContactos(forceReload: true);
      },
    );
  }

  void _showSnackBar(
    String message, {
    Color backgroundColor = Colors.red,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: duration,
      ),
    );
  }

  Future<void> _loadContactos({bool forceReload = false}) async {
    debugPrint(
      'ContactosScreen: _loadContactos llamado (forceReload: $forceReload).',
    );

    if (_userProvider.escuela.isEmpty ||
        _userProvider.idEmpresa.isEmpty ||
        _userProvider.fechaHora.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Datos de sesión no disponibles para cargar contactos. Por favor, reinicia la aplicación o vuelve a iniciar sesión.';
          _isLoading = false;
        });
      }
      _showSnackBar(
        'Error: Datos de sesión no disponibles.',
        backgroundColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userProvider.fetchAndLoadSchoolData(forceRefresh: forceReload);

      if (!mounted) {
        debugPrint(
          'ContactosScreen: _loadContactos - Widget no montado después de la carga de datos del provider.',
        );
        return;
      }

      debugPrint(
        'ContactosScreen: Contactos cargados desde UserProvider: ${_userProvider.escuelaModel?.contactos.length ?? 0}',
      );
    } on SocketException {
      if (mounted) {
        setState(() {
          _errorMessage =
              'No hay conexión a internet. Mostrando datos cacheados.';
        });
      }
      _showSnackBar(
        'Sin conexión a internet. Mostrando datos cacheados.',
        backgroundColor: Colors.orange,
      );
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error al cargar contactos: ${e.toString().replaceFirst('Exception: ', '')}';
        });
      }
      _showSnackBar(_errorMessage!, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void hacerLlamada(String telefono) async {
    final uri = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      _showSnackBar(
        'No se pudo realizar la llamada al número $telefono',
        backgroundColor: Colors.orange,
      );
    }
  }

  void abrirWhatsApp(String telefono) async {
    final whatsappNumber = telefono.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent("Hola, necesito información.")}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      _showSnackBar(
        'No se pudo abrir WhatsApp con el número $telefono',
        backgroundColor: Colors.orange,
      );
    }
  }

  void enviarCorreo(String correo) async {
    final uri = Uri(scheme: 'mailto', path: correo);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      _showSnackBar(
        'No se pudo abrir la aplicación de correo para $correo',
        backgroundColor: Colors.orange,
      );
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildContactActionRow({
    IconData? icon,
    Widget? customIcon,
    required String contactText,
    required String actionText,
    required VoidCallback onTap,
    Color iconColor = Colors.indigoAccent,
    required Color buttonColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: 24, color: iconColor),
        if (customIcon != null) customIcon,
        const SizedBox(width: 12),
        Expanded(
          child: SelectableText(
            contactText,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            foregroundColor: Colors.white,
          ),
          child: Text(
            actionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

 @override
  Widget build(BuildContext context) {
    super.build(context);

    _userProvider = Provider.of<UserProvider>(context);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    final String userNivelEducativo =
        _userProvider.currentColaboradorDetails?.escolaridad ?? ''; //AQUI SE DEBE MODIFICAR 

    final List<Contacto> allContacts =
        _userProvider.escuelaModel?.contactos ?? [];

    final List<Contacto> filteredContacts =
        allContacts.where((contacto) {
          final String contactoNivel = contacto.adicional4;

          if (contactoNivel.isEmpty || contactoNivel.toLowerCase() == 'false') {
            return true;
          }

          return contactoNivel.toLowerCase() ==
              userNivelEducativo.toLowerCase();
        }).toList();

    debugPrint(
      'ContactosScreen: build llamado. _errorMessage: $_errorMessage, Contactos filtrados: ${filteredContacts.length}',
    );

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Directorio',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: colores.headerColor,
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // 💡 [MODIFICACIÓN CLAVE] Lógica de control de tiempo
            final now = DateTime.now();
            if (_lastManualRefreshTime != null &&
                now.difference(_lastManualRefreshTime!).inSeconds < 60) {
              debugPrint(
                'ContactosScreen: Intento de recarga manual demasiado pronto.',
              );
              _showSnackBar('Datos actualizados.', backgroundColor: Colors.green);
              return;
            }

            debugPrint(
              'ContactosScreen: RefreshIndicator activado. Iniciando recarga forzada.',
            );
            _showSnackBar(
              'Recargando contactos...',
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.grey,
            );

            _lastManualRefreshTime = now;

            await _loadContactos(forceReload: true);

            if (_errorMessage == null) {
              _showSnackBar(
                'Datos actualizados.',
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                _isLoading && filteredContacts.isEmpty && _errorMessage == null
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Error: $_errorMessage\n\nArrastra hacia abajo para reintentar.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Asegúrate de tener conexión a internet o que tus datos de sesión sean correctos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : filteredContacts.isEmpty
                    ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 60,
                                color: Colors.blueGrey,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No hay contactos disponibles para tu nivel educativo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Arrastra hacia abajo para intentar recargar.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredContacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final contacto = filteredContacts[index];
                        final bool hasTelefono = contacto.telefono.isNotEmpty;
                        final bool hasCorreo = contacto.correo.isNotEmpty;
                        final bool hasWhatsApp = contacto.adicional5.isNotEmpty;

                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.indigo.shade50],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  // ignore: deprecated_member_use
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contacto.nombreCat,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                  const SizedBox(height: 15),

                                  if (hasTelefono) ...[
                                    _buildContactActionRow(
                                      icon: Icons.phone,
                                      contactText: contacto.telefono,
                                      actionText: 'Llamar',
                                      onTap:
                                          () => hacerLlamada(contacto.telefono),
                                      iconColor: colores.headerColor,
                                      buttonColor: colores.botonesColor,
                                    ),
                                  ],

                                  if (hasTelefono &&
                                      (hasCorreo || hasWhatsApp)) ...[
                                    const SizedBox(height: 15),
                                    Divider(
                                      color: Colors.grey.shade300,
                                      height: 1,
                                    ),
                                    const SizedBox(height: 15),
                                  ],

                                  if (hasCorreo) ...[
                                    _buildContactActionRow(
                                      icon: Icons.email,
                                      contactText: contacto.correo,
                                      actionText: 'Enviar correo',
                                      onTap: () => enviarCorreo(contacto.correo),
                                      iconColor: colores.headerColor,
                                      buttonColor: colores.botonesColor,
                                    ),
                                  ],

                                  if (hasCorreo && hasWhatsApp) ...[
                                    const SizedBox(height: 15),
                                    Divider(
                                      color: Colors.grey.shade300,
                                      height: 1,
                                    ),
                                    const SizedBox(height: 15),
                                  ],

                                  // [MODIFICACIÓN] Nueva sección para WhatsApp con campo adicional_5
                                  if (hasWhatsApp) ...[
                                    _buildContactActionRow(
                                      customIcon: Image.asset(
                                        'assets/icons/logowhats.png',
                                        height: 28,
                                        width: 28,
                                      ),
                                      contactText: contacto.adicional5,
                                      actionText: 'Enviar WhatsApp',
                                      onTap:
                                          () =>
                                              abrirWhatsApp(contacto.adicional5),
                                      buttonColor: colores.botonesColor,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ),
    );
  }
}
