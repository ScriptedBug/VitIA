class PredictionModel {
  final String variedad;
  final double confianza;

  PredictionModel({required this.variedad, required this.confianza});

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      variedad: json['variedad'] ?? 'Desconocida',
      confianza: (json['confianza'] ?? 0.0).toDouble(),
    );
  }
}