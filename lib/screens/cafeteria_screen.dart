import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Importa tus constantes de API y tu provider
import 'package:oficinaescolar_colaboradores/providers/user_provider.dart';
import 'package:oficinaescolar_colaboradores/config/api_constants.dart';

// Importa los modelos necesarios
import 'package:oficinaescolar_colaboradores/models/articulo_model.dart';
import 'package:oficinaescolar_colaboradores/models/escuela_model.dart';

/// Clase [CafeteriaView]
///
/// Muestra el estado de cuenta de la cafetería para un alumno,
/// permite filtrar por período y ver listas de precios y cuentas bancarias.
/// Los datos se obtienen de forma reactiva desde el [UserProvider],
/// que gestiona la caché local y las llamadas a la API.

class CafeteriaView extends StatefulWidget {
  // [MODIFICACIÓN] Se elimina el parámetro idColaborador del constructor.
  const CafeteriaView({super.key});

  @override
  State<CafeteriaView> createState() => _CafeteriaViewState();
}

class _CafeteriaViewState extends State<CafeteriaView>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = false;
  String? _errorMessage;

  late UserProvider _userProvider;
  late VoidCallback _autoRefreshListener;
  Timer? _autoRefreshTimer;

  DateTime? _lastManualRefreshTime;

  // Formateador de moneda (ajusta según tu región si es necesario)
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_MX',
    symbol: '\$',
  );

  @override
  void initState() {
    super.initState();
    debugPrint(
      'CafeteriaView: initState - Inicializando pantalla de cafetería.',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userProvider = Provider.of<UserProvider>(context, listen: false);

      _autoRefreshListener = () {
        debugPrint(
          'CafeteriaView: Gatillo de auto-refresco detectado. Recargando datos de cafetería (silenciosamente)...',
        );
        _loadAllCafeteriaData(forceReload: true);
      };

      _userProvider.autoRefreshTrigger.addListener(_autoRefreshListener);

      // 💡 [CORRECCIÓN ALTERNATIVA]: Usar condicionales de compilación de Dart.
      bool shouldForceReload = false;
      
      // La web no es una plataforma de "IO" (Input/Output). 
      // Si NO es Android, iOS, Linux, o Windows, asumimos que es Web/Desktop
      if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows) {
        shouldForceReload = false; // Móvil/Desktop con DB local
      } else {
        shouldForceReload = true; // Web o plataforma sin soporte DB
      }

      _loadAllCafeteriaData(forceReload: shouldForceReload);

      _startAutoRefreshTimer();
    });
  }

  @override
  void dispose() {
    debugPrint(
      'CafeteriaView: dispose - Removiendo listener de auto-refresco.',
    );
    _userProvider.autoRefreshTrigger.removeListener(_autoRefreshListener);

    debugPrint(
      'CafeteriaView: dispose - Cancelando temporizador de auto-refresco.',
    );
    _autoRefreshTimer?.cancel();

    super.dispose();
  }

  // [ELIMINADO] El método didUpdateWidget ya no es necesario.
  // @override
  // void didUpdateWidget(covariant CafeteriaView oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (widget.idColaborador != oldWidget.idColaborador) {
  //     debugPrint(
  //       'CafeteriaView didUpdateWidget: ID Alumno cambió de ${oldWidget.idColaborador} a ${widget.idColaborador}. Recargando datos.',
  //     );
  //     _loadAllCafeteriaData(forceReload: false);
  //   }
  // }

  void _startAutoRefreshTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: ApiConstants.minutosRecarga),
      (timer) {
        debugPrint(
          'CafeteriaView: Disparando auto-refresco por temporizador (${ApiConstants.minutosRecarga} minutos).',
        );
        _loadAllCafeteriaData(forceReload: true);
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

  Future<void> _loadAllCafeteriaData({bool forceReload = false}) async {
    debugPrint(
      'CafeteriaView: _loadAllCafeteriaData llamado (forceReload: $forceReload).',
    );

    // [MODIFICACIÓN] Obtener idColaborador del provider
    final String? idColaborador = _userProvider.colaboradorModel?.idColaborador;

    if (idColaborador == null ||
        _userProvider.escuela.isEmpty ||
        _userProvider.idEmpresa.isEmpty ||
        _userProvider.fechaHora.isEmpty ||
        _userProvider.idCiclo.isEmpty) {
      debugPrint(
        'UserProvider: Datos de sesión o alumno incompletos para Cafetería.',
      );
      setState(() {
        _errorMessage =
            'Error: Datos de sesión o alumno no disponibles para Cafetería.';
        _isLoading = false;
      });
      _showSnackBar(_errorMessage!, backgroundColor: Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _userProvider.fetchAndLoadSchoolData(forceRefresh: forceReload);

      await _userProvider.fetchAndLoadArticulosCafData(
        'cafeteria',
        forceRefresh: forceReload,
      );

      final List<PeriodoCafeteria> availablePeriods =
          _userProvider.escuelaModel?.cafPeriodos ?? [];
      String? effectivePeriodId = _userProvider.selectedCafeteriaPeriodId;
      String? effectiveCicloId = _userProvider.selectedCafeteriaCicloId;

      if (effectivePeriodId == null ||
          !availablePeriods.any((p) => p.idPeriodo == effectivePeriodId)) {
        if (_userProvider.escuelaModel?.cafPeriodoActual.isNotEmpty == true &&
            availablePeriods.any(
              (p) =>
                  p.idPeriodo == _userProvider.escuelaModel!.cafPeriodoActual,
            )) {
          final matchingPeriod = availablePeriods.firstWhere(
            (p) => p.idPeriodo == _userProvider.escuelaModel!.cafPeriodoActual,
          );
          effectivePeriodId = matchingPeriod.idPeriodo;
          effectiveCicloId = matchingPeriod.idCiclo;
        } else if (availablePeriods.any((p) => p.activo == '1')) {
          final activePeriod = availablePeriods.firstWhere(
            (p) => p.activo == '1',
          );
          effectivePeriodId = activePeriod.idPeriodo;
          effectiveCicloId = activePeriod.idCiclo;
        } else if (availablePeriods.isNotEmpty) {
          effectivePeriodId = availablePeriods.first.idPeriodo;
          effectiveCicloId = availablePeriods.first.idCiclo;
        } else {
          effectivePeriodId = 'NULL';
          effectiveCicloId =
              _userProvider.idCiclo.isNotEmpty ? _userProvider.idCiclo : 'NULL';
        }
      }

      if (effectiveCicloId == null || effectiveCicloId.isEmpty) {
        effectiveCicloId =
            _userProvider.idCiclo.isNotEmpty ? _userProvider.idCiclo : 'NULL';
      }

      if (_userProvider.selectedCafeteriaPeriodId != effectivePeriodId ||
          _userProvider.selectedCafeteriaCicloId != effectiveCicloId) {
        await _userProvider.setSelectedCafeteriaPeriod(
          effectivePeriodId,
          effectiveCicloId,
        );
      } else {
        // [MODIFICACIÓN] Pasar el idColaborador desde el provider
        await _userProvider.fetchAndLoadCafeteriaMovimientosData(
          idColaborador: idColaborador,
          idPeriodo: effectivePeriodId,
          idCiclo: effectiveCicloId,
          forceRefresh: forceReload,
        );
      }

      if (!mounted) {
        debugPrint(
          'CafeteriaView: _loadAllCafeteriaData - Widget no montado después de cargar datos.',
        );
        return;
      }

      debugPrint(
        'CafeteriaView: Todos los datos cargados exitosamente desde UserProvider.',
      );
    } catch (e) {
      if (!mounted) {
        debugPrint(
          'CafeteriaView: _loadAllCafeteriaData - Widget no montado durante manejo de excepción.',
        );
        return;
      }
      debugPrint('CafeteriaView: Excepción general al cargar datos: $e');
      setState(() {
        _errorMessage =
            'Error al cargar datos de cafetería: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      _showSnackBar(_errorMessage!, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadMovimientosFromSelection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final String periodToFetch =
        _userProvider.selectedCafeteriaPeriodId ?? 'NULL';
    String cicloToFetch =
        _userProvider.selectedCafeteriaCicloId ?? _userProvider.idCiclo;

    final String? idColaborador = _userProvider.colaboradorModel?.idColaborador;

    if (cicloToFetch.isEmpty) {
      cicloToFetch = 'NULL';
    }

    if (idColaborador == null ||
        _userProvider.escuela.isEmpty ||
        _userProvider.idEmpresa.isEmpty ||
        cicloToFetch.isEmpty ||
        _userProvider.fechaHora.isEmpty) {
      debugPrint(
        'UserProvider: Datos incompletos para recargar movimientos por selección.',
      );
      _showSnackBar(
        'Error: Datos incompletos para recargar movimientos.',
        backgroundColor: Colors.orange,
      );
      setState(() {
        _errorMessage = 'Datos incompletos para recargar movimientos.';
        _isLoading = false;
      });
      return;
    }

    try {
      // [MODIFICACIÓN] Pasar el idColaborador desde el provider
      await _userProvider.fetchAndLoadCafeteriaMovimientosData(
        idColaborador: idColaborador,
        idPeriodo: periodToFetch,
        idCiclo: cicloToFetch,
        forceRefresh: true,
      );

      if (!mounted) {
        debugPrint(
          'CafeteriaView: _reloadMovimientosFromSelection - Widget no montado después de cargar movimientos.',
        );
        return;
      }
    } catch (e) {
      if (!mounted) {
        debugPrint(
          'CafeteriaView: _reloadMovimientosFromSelection - Widget no montado durante manejo de excepción.',
        );
        return;
      }
      debugPrint(
        'CafeteriaView: Excepción al recargar movimientos por selección: $e',
      );
      setState(() {
        _errorMessage =
            'Error al recargar movimientos: ${e.toString().replaceFirst('Exception: ', '')}';
      });
      _showSnackBar(_errorMessage!, backgroundColor: Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBankAccountCard(CuentaBancaria cuenta) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 0,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(
            12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                cuenta.descripcion,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              SelectableText(
                'Banco: ${cuenta.banco}',
                style: const TextStyle(fontSize: 14),
              ),
              SelectableText(
                'Cuenta: ${cuenta.cuenta}',
                style: const TextStyle(fontSize: 14),
              ),
              SelectableText(
                'CLABE: ${cuenta.clabe}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBankAccountModal() {
    debugPrint('CafeteriaView: _showBankAccountModal llamado.');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final List<CuentaBancaria> cuentasCafeteria =
            _userProvider.escuelaModel?.cuentasBancariasCaf ?? [];

        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double screenHeight = MediaQuery.of(dialogContext).size.height;

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final colores = userProvider.colores;

        final double dialogWidth = screenWidth * 0.90;
        final double dialogHeight = screenHeight * 0.95;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 10.0,
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: dialogWidth,
              maxWidth: dialogWidth,
              minHeight: dialogHeight,
              maxHeight: dialogHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: colores.headerColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Información Bancaria',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      20.0,
                    ),
                    child: Builder(
                      builder: (BuildContext innerContentContext) {
                        if (_isLoading && cuentasCafeteria.isEmpty) {
                          return const SizedBox(
                            height: 150,
                            width: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else if (_errorMessage != null) {
                          return SizedBox(
                            height: 150,
                            width: 200,
                            child: Center(child: Text('Error: $_errorMessage')),
                          );
                        } else if (cuentasCafeteria.isEmpty) {
                          return const SizedBox(
                            height: 150,
                            width: 200,
                            child: Center(
                              child: Text(
                                'No hay información bancaria de cafetería disponible.',
                              ),
                            ),
                          );
                        } else {
                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: cuentasCafeteria
                                  .map(
                                    (cuenta) => _buildBankAccountCard(cuenta),
                                  )
                                  .toList(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(
                    20.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colores.botonesColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 30,
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showArticulosModal() {
    debugPrint('CafeteriaView: _showArticulosModal llamado.');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final List<Articulo> articulos = _userProvider.articulosCaf;
        final double screenWidth = MediaQuery.of(dialogContext).size.width;
        final double screenHeight = MediaQuery.of(dialogContext).size.height;
        final double dialogWidth = screenWidth * 0.90;
        final double dialogHeight = screenHeight * 0.95;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final colores = userProvider.colores;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 10.0,
          ),
          backgroundColor: Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: dialogWidth,
              maxWidth: dialogWidth,
              minHeight: dialogHeight,
              maxHeight: dialogHeight,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15.0,
                    horizontal: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: colores.headerColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Lista de Precios',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (BuildContext innerContentContext) {
                      if (_isLoading && articulos.isEmpty) {
                        return const SizedBox(
                          height: 150,
                          width: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (_errorMessage != null) {
                        return SizedBox(
                          height: 150,
                          width: 200,
                          child: Center(child: Text('Error: $_errorMessage')),
                        );
                      } else if (articulos.isEmpty) {
                        return const SizedBox(
                          height: 150,
                          width: 200,
                          child: Center(
                            child: Text(
                              'No se encontraron artículos de cafetería disponibles.',
                            ),
                          ),
                        );
                      } else {
                        final double rowHeight = 48.0;
                        final double headerHeight = 48.0;

                        final double actualListSizedBoxHeight =
                            (articulos.length * rowHeight + headerHeight).clamp(
                          0.0,
                          screenHeight * 0.95 -
                              150,
                        );

                        return SizedBox(
                          height: actualListSizedBoxHeight,
                          width: double.maxFinite,
                          child: Column(
                            children: [
                              Container(
                                color: colores.headerColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 16.0,
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Producto',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'Precio Unitario',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: articulos.length,
                                  itemBuilder: (context, index) {
                                    final articulo = articulos[index];
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                            horizontal: 16.0,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Text(articulo.producto),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  NumberFormat.currency(
                                                    locale: 'es_MX',
                                                    symbol: '\$',
                                                    decimalDigits: 2,
                                                  ).format(
                                                    articulo.precioUnit,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(
                    20.0,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colores.botonesColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 30,
                        ),
                      ),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    _userProvider = Provider.of<UserProvider>(context);

    final List<Map<String, dynamic>> movimientos =
        _userProvider.cafeteriaMovimientos;
    final List<PeriodoCafeteria> periodos =
        _userProvider.escuelaModel?.cafPeriodos ?? [];

    final double totalBalance = _userProvider.ultimoSaldoConocido;

    debugPrint(
      'CafeteriaView: build llamado. _isLoading: $_isLoading, _errorMessage: $_errorMessage, Movimientos(${movimientos.length}), Articulos(${_userProvider.articulosCaf.length}), Periodos(${periodos.length})',
    );
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final colores = userProvider.colores;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Cafetería',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: colores.headerColor,
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            final now = DateTime.now();
            // Verifica si ha pasado menos de un minuto desde la última recarga manual.
            if (_lastManualRefreshTime != null && now.difference(_lastManualRefreshTime!).inSeconds < 60) {
              debugPrint('CafeteriaView: Intento de recarga manual demasiado pronto.');
              _showSnackBar('Datos actualizados.', backgroundColor: Colors.green);
              return;
            }

            debugPrint('CafeteriaView: RefreshIndicator activado. Iniciando recarga forzada.');

            _showSnackBar(
              'Recargando datos...',
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.grey,
            );

            // Actualiza el tiempo de la última recarga manual.
            _lastManualRefreshTime = now;

            await _loadAllCafeteriaData(forceReload: true);

            if (_errorMessage == null) {
              _showSnackBar(
                'Datos actualizados.',
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              );
            }
          },
          child: _isLoading &&
                  movimientos.isEmpty &&
                  periodos.isEmpty &&
                  _errorMessage == null
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            'Error: $_errorMessage\n\nArrastra hacia abajo para reintentar.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        if (periodos.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Filtrar por Periodo',
                                border: OutlineInputBorder(),
                              ),
                             value: _userProvider.selectedCafeteriaPeriodId,
                              items: periodos.map((periodo) {
                                return DropdownMenuItem<String>(
                                  value: periodo.idPeriodo.toString(),
                                  child: Text(periodo.periodo.toString()),
                                );
                              }).toList(),
                              onChanged: (value) async {
                                final selectedPeriodObject = periodos.firstWhere(
                                  (p) => p.idPeriodo.toString() == value,
                                  orElse: () => PeriodoCafeteria(
                                    idPeriodo: 'NULL',
                                    periodo: 'Ninguno',
                                    fechaInicio: '',
                                    fechaTermino: '',
                                    activo: '',
                                    tipoPeriodo: '',
                                    idEmpresa: '',
                                    idCiclo: 'NULL',
                                  ),
                                );

                                await _userProvider.setSelectedCafeteriaPeriod(
                                  value,
                                  selectedPeriodObject.idCiclo,
                                );
                              },
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                'No hay periodos de cafetería disponibles.',
                              ),
                            ),
                          ),
                        const SizedBox(height: 15),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currencyFormatter.format(totalBalance),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const Text(
                                    'Saldo Actual',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: _showArticulosModal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colores.botonesColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(fontSize: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.fastfood,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _showBankAccountModal,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colores.botonesColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(fontSize: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(
                            height: 24, thickness: 1, color: Colors.grey),
                        if (movimientos.isEmpty && !_isLoading)
                          const Expanded(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'No se encontraron movimientos para el alumno seleccionado y filtros actuales.',
                                ),
                              ),
                            ),
                          )
                        else if (_isLoading)
                          const Expanded(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: movimientos.length,
                              itemBuilder: (context, index) {
                                final mov = movimientos[index];
                                final double cargo =
                                    mov['cargo'] as double? ?? 0.0;
                                final double abono =
                                    mov['abono'] as double? ?? 0.0;
                                final double saldoActual =
                                    mov['saldo'] as double? ?? 0.0;

                                double displayAmount = 0.0;
                                Color amountColor = Colors.black;
                                FontWeight amountFontWeight = FontWeight.normal;

                                if (cargo > 0 && abono > 0) {
                                  displayAmount = abono - cargo;
                                  if (displayAmount >= 0) {
                                    amountColor = Colors.black;
                                    amountFontWeight = FontWeight.bold;
                                  } else {
                                    amountColor = Colors.red;
                                    amountFontWeight = FontWeight.bold;
                                  }
                                } else if (cargo > 0) {
                                  displayAmount = -cargo;
                                  amountColor = Colors.red;
                                  amountFontWeight = FontWeight.normal;
                                } else if (abono > 0) {
                                  displayAmount = abono;
                                  amountColor = Colors.black;
                                  amountFontWeight = FontWeight.normal;
                                }

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              mov['descripcion'].toString(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            _currencyFormatter.format(
                                              displayAmount,
                                            ),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: amountFontWeight,
                                              color: amountColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 0.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              mov['fecha'].toString(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Text(
                                              'Saldo: ${_currencyFormatter.format(saldoActual)}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Divider(
                                        height: 16,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}