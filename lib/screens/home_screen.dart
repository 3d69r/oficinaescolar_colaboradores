import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:oficinaescolar_colaboradores/screens/webs_interes_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Importa tus constantes, providers y modelos
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/models/colaborador_model.dart'; 

// Importa tus pantallas
import 'contactos_screen.dart';
import 'avisos_screen.dart';
import 'cafeteria_screen.dart';
import 'perfil_screen.dart';
import 'datos_escuela_screen.dart';
import 'comentarios_screen.dart';
import 'asistencia_screen.dart'; 
import 'materias_screen.dart'; 
import 'subir_avisos_screen.dart'; // ✅ [NUEVO] Importar pantalla de Subir Avisos

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _pageIndex = 0;
  late UserProvider _userProvider;
  bool _isInitialPageIndexSet = false;

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen: initState - Inicializando pantalla de inicio.');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _userProvider = Provider.of<UserProvider>(context, listen: false);
      await _loadAllData();
      _userProvider.autoRefreshTrigger.addListener(_onAutoRefreshTriggered);
    });
  }

  @override
  void dispose() {
    debugPrint('HomeScreen: dispose - Limpiando recursos de HomeScreen.');
    _userProvider.autoRefreshTrigger.removeListener(_onAutoRefreshTriggered);
    super.dispose();
  }

  Future<void> _onAutoRefreshTriggered() async {
    debugPrint('HomeScreen: Señal de auto-refresco recibida. Recargando datos...');
    await _userProvider.initializeAllUserData();
  }

  Future<void> _loadAllData() async {
    debugPrint('HomeScreen: _loadAllData - Iniciando carga inicial de todos los datos.');
    await _userProvider.initializeAllUserData();
  }

  void _abrirDatosEscuela() {
    debugPrint('HomeScreen: _abrirDatosEscuela - Navegando a DatosEscuelaScreen.');
    final escuelaModel = _userProvider.escuelaModel;
    if (escuelaModel != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DatosEscuelaScreen(escuela: escuelaModel),
        ),
      );
    } else {
      _showSnackBar('Los datos de la escuela aún no están disponibles.');
      debugPrint('HomeScreen: Error: escuelaModel es nulo al intentar abrir DatosEscuelaScreen.');
    }
  }

  void _showSnackBar(String message, {Color backgroundColor = Colors.red}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String nombresApellidoPat(ColaboradorModel? colaborador) { 
    if (colaborador == null) {
      return 'Cargando...';
    }
    List<String> nameParts = [];
    if (colaborador.nombre.isNotEmpty) {
      nameParts.add(colaborador.nombre);
    }
    if (colaborador.apellidoPat.isNotEmpty) {
      nameParts.add(colaborador.apellidoPat);
    }
    /*if (colaborador.apellidoMat.isNotEmpty) {
      nameParts.add(colaborador.apellidoMat);
    }*/
    final fullName = nameParts.join(' ').trim();
    return fullName.isEmpty ? 'Nombre no disponible' : fullName;
  }

  Map<String, dynamic> _buildDynamicMenu(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final List<String> permisos =
        userProvider.escuelaModel?.appPermisos
            .split(',')
            .map((e) => e.trim())
            .toList() ??
        [];

    final List<Widget> dynamicPages = [];
    final List<Widget> dynamicNavItems = [];
    
    // ✅ [AGREGADO] Se añade la pantalla y el ícono para subir avisos si el permiso está presente
    if (permisos.contains('Directorio')) {//CAMBIAR NOMBRE
      dynamicPages.add(const SubirAvisosScreen());
      dynamicNavItems.add(
        const Icon(Icons.campaign_outlined, size: 30, color: Colors.white),
      );
    }
    if (permisos.contains('Sitios de Interes')) {
      dynamicPages.add(WebsInteresScreen(escuela: userProvider.escuelaModel!));
      dynamicNavItems.add(
        const Icon(Icons.public, size: 30, color: Colors.white),
      );
    }
    if (permisos.contains('Cafeteria')) {
      dynamicPages.add(const AsistenciaScreen());
      dynamicNavItems.add(
        const Icon(Icons.check_circle_outline, size: 30, color: Colors.white),
      );
    }
    if (permisos.contains('Materias')) {
      dynamicPages.add(const MateriasScreen());
      dynamicNavItems.add(
        const Icon(Icons.class_outlined, size: 30, color: Colors.white),
      );
    }
    if (permisos.contains('SUBIR ARCHIVOS')) {
      dynamicPages.add(const ContactosScreen());
      dynamicNavItems.add(
        const Icon(Icons.contact_phone, size: 30, color: Colors.white),
      );
    }
    if (permisos.contains('Avisos')) {
      dynamicPages.add(const AvisosView());
      dynamicNavItems.add(
        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications, size: 30, color: Colors.white),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final unreadCount = userProvider.unreadAvisosCount;
                return unreadCount > 0
                    ? Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      );
    }
    if (permisos.contains('Asistencia')) {
      dynamicPages.add(const CafeteriaView());
      dynamicNavItems.add(
        const Icon(Icons.local_cafe, size: 30, color: Colors.white),
      );
    }

    return {'pages': dynamicPages, 'items': dynamicNavItems};
  }

  /// --- Método para construir el Drawer ---
  Widget _buildEndDrawer(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colaborador = userProvider.colaboradorModel;
    final escuela = userProvider.escuelaModel;

    String buildFullName(ColaboradorModel? colaborador) {
      if (colaborador == null) {
        return 'Cargando...';
      }
      List<String> nameParts = [];
      /*if (colaborador.primerNombre.isNotEmpty) {
        nameParts.add(colaborador.primerNombre);
      }*/
      if (colaborador.apellidoPat.isNotEmpty) {
        nameParts.add(colaborador.apellidoPat);
      }
      if (colaborador.apellidoMat.isNotEmpty) {
        nameParts.add(colaborador.apellidoMat);
      }

      final fullName = nameParts.join(' ').trim();
      return fullName.isEmpty ? 'Nombre no disponible' : fullName;
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 120,
            decoration: BoxDecoration(color: userProvider.colores.headerColor),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        colaborador?.rutaFoto.isNotEmpty ?? false
                            ? CachedNetworkImageProvider(
                              '${ApiConstants.assetsBaseUrl}${colaborador!.rutaFoto}',
                            )
                            : null,
                    child: colaborador?.rutaFoto.isEmpty ?? true
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    buildFullName(colaborador),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi perfil'),
            onTap: () {
              Navigator.pop(context);
              if (colaborador != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PerfilScreen(),
                  ),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Datos de escuela'),
            onTap: () {
              Navigator.pop(context);
              _abrirDatosEscuela();
            },
          ),
          ListTile(
            leading: const Icon(Icons.comment),
            title: const Text('Comentarios'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ComentariosScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Sitios de interes'),
            onTap: () {
              Navigator.pop(context);
              if (escuela != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebsInteresScreen(escuela: escuela),
                  ),
                );
              } else {
                _showSnackBar('Los datos de la escuela aún no están disponibles.');
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              Navigator.pop(context);
              debugPrint('HomeScreen: Cerrar sesión presionado. Actualizando token a inactivo y limpiando UserProvider.');

              final idColaborador = userProvider.colaboradorModel?.idColaborador;
              final escuela = userProvider.escuela;
              final tokenFirebase = await FirebaseMessaging.instance.getToken();

              if (idColaborador != null && tokenFirebase != null && tokenFirebase.isNotEmpty) {
                try {
                  await userProvider.actualizarInfoToken(
                    escuela: escuela,
                    idColaborador: idColaborador,
                    tokenCelular: tokenFirebase,
                    status: 'inactivo',
                  );
                } catch (e) {
                  debugPrint('Error al actualizar token a inactivo: $e');
                }
              }

              await userProvider.clearUserData();
              if (mounted) {
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _userProvider = Provider.of<UserProvider>(context);

    if (_userProvider.colaboradorModel == null || _userProvider.escuelaModel == null) {
      debugPrint('HomeScreen: build - Datos de colaborador o escuela nulos. Mostrando CircularProgressIndicator.');
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final menuData = _buildDynamicMenu(context);
    final List<Widget> dynamicPages = menuData['pages'];
    final List<Widget> dynamicNavItems = menuData['items'];

    if (!_isInitialPageIndexSet && dynamicPages.isNotEmpty) {
      final avisosIndex = dynamicPages.indexWhere((page) => page is AvisosView);
      _pageIndex = (avisosIndex != -1) ? avisosIndex : 0;
      _isInitialPageIndexSet = true;
    }
    
    final ColaboradorModel? colaborador = _userProvider.colaboradorModel;

    final String schoolLogoUrl =
        _userProvider.escuelaModel?.rutaLogo.isNotEmpty ?? false
            ? '${ApiConstants.assetsBaseUrl}${_userProvider.escuelaModel?.rutaLogo}'
            : '';

    final colores = _userProvider.colores;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colores.headerColor,
          toolbarHeight: 60,
          title: Row(
            children: [
              if (schoolLogoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: schoolLogoUrl,
                  height: 50,
                  width: 50,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) {
                    debugPrint('HomeScreen: Error al cargar imagen del logo (CachedNetworkImage): $error');
                    return const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 40,
                    );
                  },
                )
              else
                const Icon(Icons.wifi_off, color: Colors.white, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nombresApellidoPat(colaborador),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ),
          ],
        ),
        body: dynamicPages.isNotEmpty
            ? dynamicPages[_pageIndex]
            : const Center(child: Text('No hay vistas disponibles')),
        bottomNavigationBar: dynamicNavItems.isNotEmpty
            ? CurvedNavigationBar(
              index: _pageIndex,
              height: 60.0,
              backgroundColor: Colors.transparent,
              color: colores.footerColor,
              buttonBackgroundColor: colores.footerColor,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              items: dynamicNavItems,
              onTap: (index) {
                setState(() {
                  _pageIndex = index;
                });
              },
            )
            : null,
        endDrawer: _buildEndDrawer(context),
      ),
    );
  }
}