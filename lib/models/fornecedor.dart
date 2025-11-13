class Fornecedor {
  final String id;
  final String nome;
  final String? cnpj;
  final String? inscricaoEstadual;
  final String? responsavel;
  final String? telefone;
  final String? email;
  final String? endereco;
  final String? observacoes;
  final bool ativo;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  Fornecedor({
    required this.id,
    required this.nome,
    this.cnpj,
    this.inscricaoEstadual,
    this.responsavel,
    this.telefone,
    this.email,
    this.endereco,
    this.observacoes,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  })  : ativo = ativo ?? true,
        criadoEm = criadoEm ?? DateTime.now(),
        atualizadoEm = atualizadoEm ?? DateTime.now();

  Fornecedor copyWith({
    String? id,
    String? nome,
    String? cnpj,
    String? inscricaoEstadual,
    String? responsavel,
    String? telefone,
    String? email,
    String? endereco,
    String? observacoes,
    bool? ativo,
    DateTime? criadoEm,
    DateTime? atualizadoEm,
  }) {
    return Fornecedor(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      cnpj: cnpj ?? this.cnpj,
      inscricaoEstadual: inscricaoEstadual ?? this.inscricaoEstadual,
      responsavel: responsavel ?? this.responsavel,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      endereco: endereco ?? this.endereco,
      observacoes: observacoes ?? this.observacoes,
      ativo: ativo ?? this.ativo,
      criadoEm: criadoEm ?? this.criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cnpj': cnpj,
      'inscricaoEstadual': inscricaoEstadual,
      'responsavel': responsavel,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
      'observacoes': observacoes,
      'ativo': ativo,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  factory Fornecedor.fromJson(Map<String, dynamic> json) {
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

    return Fornecedor(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? 'Fornecedor',
      cnpj: json['cnpj'] as String?,
      inscricaoEstadual: json['inscricaoEstadual'] as String?,
      responsavel: json['responsavel'] as String?,
      telefone: json['telefone'] as String?,
      email: json['email'] as String?,
      endereco: json['endereco'] as String?,
      observacoes: json['observacoes'] as String?,
      ativo: json['ativo'] as bool? ?? true,
      criadoEm: _parseDate(json['criadoEm']),
      atualizadoEm: _parseDate(json['atualizadoEm']),
    );
  }
}

