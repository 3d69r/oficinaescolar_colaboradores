class Articulo {
  final String producto;
  final double precioUnit;
  final String categoria;
  final double precioPrimaria;
  final double precioSecundaria;
  final double precioBachillerato;

  Articulo({
    required this.producto,
    required this.precioUnit,
    required this.categoria,
    required this.precioPrimaria,
    required this.precioSecundaria,
    required this.precioBachillerato,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      producto: json['producto'] as String? ?? '',
      // Usamos .toString() para asegurar que double.tryParse reciba un String
      // y un fallback a 0.0 por si el valor es nulo o no se puede parsear
      precioUnit: double.tryParse(json['precio_unit'].toString()) ?? 0.0,
      categoria: json['categoria'] as String? ?? '',
      precioPrimaria: double.tryParse(json['cafeteria_vta_precio_primaria'].toString()) ?? 0.0,
      precioSecundaria: double.tryParse(json['cafeteria_vta_precio_secundaria'].toString()) ?? 0.0,
      precioBachillerato: double.tryParse(json['cafeteria_vta_precio_bachillerato'].toString()) ?? 0.0,
    );
  }
}