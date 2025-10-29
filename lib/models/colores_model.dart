import 'package:flutter/material.dart';

// Método auxiliar para convertir String a Color, con un fallback
Color _hexToColor(String? hexCode, {Color defaultColor = Colors.indigoAccent}) {
  if (hexCode == null || hexCode.isEmpty) {
    return defaultColor;
  }

  final hexString = hexCode.replaceAll('#', '');
  final fullHex = 'FF$hexString';
  
  // 🔑 CORRECCIÓN CLAVE: Usar int.tryParse para manejar formatos inválidos
  final int? colorValue = int.tryParse(fullHex, radix: 16);
  
  if (colorValue == null) {
    // Si la conversión falla (no es un hex válido), devuelve el color por defecto
    return defaultColor; 
  }
  
  return Color(colorValue);
}

class Colores {
  final String appColorHeader;
  final String appColorFooter;
  final String appColorBackground;
  final String appColorBotones;
  final String appCredColorHeader1;
  final String appCredColorHeader2;
  final String appCredColorLetra1;
  final String appCredColorLetra2;
  final String appCredColorBackground1;
  final String appCredColorBackground2;
  

  Colores({
    required this.appColorHeader,
    required this.appColorFooter,
    required this.appColorBackground,
    required this.appColorBotones,
    required this.appCredColorHeader1,
    required this.appCredColorHeader2,
    required this.appCredColorLetra1,
    required this.appCredColorLetra2,
    required this.appCredColorBackground1,
    required this.appCredColorBackground2
  });
 
  factory Colores.fromMap(Map<String, dynamic> data) {
    return Colores(
      // Ahora el valor por defecto se maneja en el método utilitario de la UI.
      appColorHeader: data['app_color_header'] ?? '', 
      appColorFooter: data['app_color_footer'] ?? '',
      appColorBackground: data['app_color_background'] ?? '',
      appColorBotones: data['app_color_botones'] ?? '',
      appCredColorHeader1: data['app_cred_color_header_1'] ?? '',
      appCredColorHeader2: data['app_cred_color_header_2'] ?? '',
      appCredColorLetra1: data['app_cred_color_letra_1'] ?? '',
      appCredColorLetra2: data['app_cred_color_letra_2'] ?? '',
      appCredColorBackground1: data['app_cred_color_background_1'] ?? '',
      appCredColorBackground2: data['app_cred_color_background_2'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'app_color_header': appColorHeader,
      'app_color_footer': appColorFooter,
      'app_color_background': appColorBackground,
      'app_color_botones': appColorBotones,
      'app_cred_color_header_1': appCredColorHeader1,
      'app_cred_color_header_2': appCredColorHeader2,
      'app_cred_color_letra_1' : appCredColorLetra1,
      'app_cred_color_letra_2' : appCredColorLetra2,
      'app_cred_color_background_1': appCredColorBackground1,
      'app_cred_color_background_2': appCredColorBackground2,
    };
  }

  // --- NUEVOS MÉTODOS GETTER PARA USAR EN LA UI ---
  Color get headerColor => _hexToColor(appColorHeader);
  Color get footerColor => _hexToColor(appColorFooter);
  Color get backgroundColor => _hexToColor(appColorBackground);
  Color get botonesColor => _hexToColor(appColorBotones);
  Color get credHeaderColor1 => _hexToColor(appCredColorHeader1);
  Color get credHeaderColor2 => _hexToColor(appCredColorHeader2);
  Color get credLetraColor1 => _hexToColor(appCredColorLetra1);
  Color get credLetraColor2 => _hexToColor(appCredColorLetra2);
  Color get credBackground1 => _hexToColor(appCredColorBackground1);
  Color get credBackground2 => _hexToColor(appCredColorBackground2);

}


