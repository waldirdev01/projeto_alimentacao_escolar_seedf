class FontePagamento {
  final String id;
  final String nome;
  final String observacao;
  final double valor;
  final bool ativo;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;

  const FontePagamento({
    required this.id,
    required this.nome,
    required this.observacao,
    required this.valor,
    this.ativo = true,
    required this.dataCriacao,
    required this.dataAtualizacao,
  });

  FontePagamento copyWith({
    String? id,
    String? nome,
    String? observacao,
    double? valor,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? dataAtualizacao,
  }) {
    return FontePagamento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      observacao: observacao ?? this.observacao,
      valor: valor ?? this.valor,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'observacao': observacao,
      'valor': valor,
      'ativo': ativo,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
    };
  }

  factory FontePagamento.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is Map && value.containsKey('_seconds')) {
        final seconds = value['_seconds'] as int? ?? 0;
        final nanos = value['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanos ~/ 1000000),
        );
      }
      return DateTime.now();
    }

    return FontePagamento(
      id: json['id'],
      nome: json['nome'] ?? '',
      observacao: json['observacao'] ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      ativo: json['ativo'] ?? true,
      dataCriacao: _parseDate(json['dataCriacao']),
      dataAtualizacao: _parseDate(json['dataAtualizacao']),
    );
  }
}

