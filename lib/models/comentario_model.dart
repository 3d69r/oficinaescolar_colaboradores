// lib/models/comentario.dart

/// Enum para definir los tipos de comentarios de manera segura.
enum TipoComentario {
  problema,
  idea,
  desacuerdo,
  felicitacion,
  sugerencia,
}

/// Clase que representa el objeto de un comentario.
class Comentario {
  final TipoComentario tipo;
  final String texto;

  Comentario({required this.tipo, required this.texto});
}