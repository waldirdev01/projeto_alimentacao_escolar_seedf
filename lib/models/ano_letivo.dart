class AnoLetivo {
  final String id;
  final int ano;
  final DateTime dataCriacao;
  final bool ativo;

  AnoLetivo({
    required this.id,
    required this.ano,
    required this.dataCriacao,
    this.ativo = true,
  });

  AnoLetivo copyWith({
    String? id,
    int? ano,
    DateTime? dataCriacao,
    bool? ativo,
  }) {
    return AnoLetivo(
      id: id ?? this.id,
      ano: ano ?? this.ano,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ano': ano,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ativo': ativo,
    };
  }

  factory AnoLetivo.fromJson(Map<String, dynamic> json) {
    return AnoLetivo(
      id: json['id'],
      ano: json['ano'],
      dataCriacao: DateTime.parse(json['dataCriacao']),
      ativo: json['ativo'] ?? true,
    );
  }
}
