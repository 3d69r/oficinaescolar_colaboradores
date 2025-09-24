import 'package:flutter/material.dart';

class InputDecorations {
  static InputDecoration inputDecoration({
    required String hintext,
    required String labeltext,
    required Icon icono
  }) {
    return InputDecoration(
      enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.indigoAccent)),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.indigoAccent, width: 3)),
          hintText: hintext,
          labelText: labeltext,
          prefixIcon: icono,
    );
  }
}