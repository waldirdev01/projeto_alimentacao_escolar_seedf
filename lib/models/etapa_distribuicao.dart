enum TipoEtapaDistribuicao {
  quantidadesAlunos('Quantidades de Alunos'),
  pdga('PDGA - Plano de Distribuição de Gêneros Alimentícios'),
  pdgp('PDGP - Plano de Distribuição de Gêneros Perisháveis'),
  cardapios('Cardápios');

  const TipoEtapaDistribuicao(this.displayName);
  final String displayName;
}

class EtapaDistribuicao {
  final String id;
  final String distribuicaoId;
  final TipoEtapaDistribuicao tipo;
  final String titulo;
  final String descricao;
  final DateTime dataLimite;
  final bool ativa;
  final bool concluida;
  final DateTime dataCriacao;
  final DateTime? dataConclusao;
  final List<String> responsaveis; // IDs dos usuários responsáveis
  final Map<String, dynamic> dadosEtapa; // Dados específicos da etapa

  EtapaDistribuicao({
    required this.id,
    required this.distribuicaoId,
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.dataLimite,
    this.ativa = true,
    this.concluida = false,
    required this.dataCriacao,
    this.dataConclusao,
    this.responsaveis = const [],
    this.dadosEtapa = const {},
  });

  EtapaDistribuicao copyWith({
    String? id,
    String? distribuicaoId,
    TipoEtapaDistribuicao? tipo,
    String? titulo,
    String? descricao,
    DateTime? dataLimite,
    bool? ativa,
    bool? concluida,
    DateTime? dataCriacao,
    DateTime? dataConclusao,
    List<String>? responsaveis,
    Map<String, dynamic>? dadosEtapa,
  }) {
    return EtapaDistribuicao(
      id: id ?? this.id,
      distribuicaoId: distribuicaoId ?? this.distribuicaoId,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataLimite: dataLimite ?? this.dataLimite,
      ativa: ativa ?? this.ativa,
      concluida: concluida ?? this.concluida,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      responsaveis: responsaveis ?? this.responsaveis,
      dadosEtapa: dadosEtapa ?? this.dadosEtapa,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'distribuicaoId': distribuicaoId,
      'tipo': tipo.name,
      'titulo': titulo,
      'descricao': descricao,
      'dataLimite': dataLimite.toIso8601String(),
      'ativa': ativa,
      'concluida': concluida,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataConclusao': dataConclusao?.toIso8601String(),
      'responsaveis': responsaveis,
      'dadosEtapa': dadosEtapa,
    };
  }

  factory EtapaDistribuicao.fromJson(Map<String, dynamic> json) {
    return EtapaDistribuicao(
      id: json['id'],
      distribuicaoId: json['distribuicaoId'],
      tipo: TipoEtapaDistribuicao.values.firstWhere(
        (t) => t.name == json['tipo'],
        orElse: () => TipoEtapaDistribuicao.quantidadesAlunos,
      ),
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataLimite: DateTime.parse(json['dataLimite']),
      ativa: json['ativa'] ?? true,
      concluida: json['concluida'] ?? false,
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataConclusao: json['dataConclusao'] != null
          ? DateTime.parse(json['dataConclusao'])
          : null,
      responsaveis: List<String>.from(json['responsaveis'] ?? []),
      dadosEtapa: Map<String, dynamic>.from(json['dadosEtapa'] ?? {}),
    );
  }

  bool get isDataLimiteUltrapassada {
    return DateTime.now().isAfter(dataLimite);
  }

  bool get isDataLimiteProxima {
    final diasRestantes = dataLimite.difference(DateTime.now()).inDays;
    return diasRestantes <= 3 && diasRestantes >= 0;
  }

  String get dataLimiteTexto {
    return '${dataLimite.day.toString().padLeft(2, '0')}/${dataLimite.month.toString().padLeft(2, '0')}/${dataLimite.year}';
  }
}
