class ColeccionModel {
  final int id;
  final String pathFotoUsuario;
  final String? notas;
  final String nombreVariedad;

  ColeccionModel({
    required this.id,
    required this.pathFotoUsuario,
    this.notas,
    required this.nombreVariedad,
  });

  factory ColeccionModel.fromJson(Map<String, dynamic> json) {
    return ColeccionModel(
      id: json['id_coleccion'],
      pathFotoUsuario: json['path_foto_usuario'] ?? '',
      notas: json['notas'],
      // Si el backend no envía el nombre anidado, usa un genérico
      nombreVariedad: json['variedad'] != null ? json['variedad']['nombre'] : 'Variedad detectada',
    );
  }
}