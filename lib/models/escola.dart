class Escola {
  final String id;
  final String nome;
  final String codigo;
  final String regionalId;
  final DateTime dataCriacao;
  final bool ativo;

  Escola({
    required this.id,
    required this.nome,
    required this.codigo,
    required this.regionalId,
    required this.dataCriacao,
    this.ativo = true,
  });

  Escola copyWith({
    String? id,
    String? nome,
    String? codigo,
    String? regionalId,
    DateTime? dataCriacao,
    bool? ativo,
  }) {
    return Escola(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      codigo: codigo ?? this.codigo,
      regionalId: regionalId ?? this.regionalId,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'codigo': codigo,
      'regionalId': regionalId,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ativo': ativo,
    };
  }

  factory Escola.fromJson(Map<String, dynamic> json) {
    return Escola(
      id: json['id'],
      nome: json['nome'],
      codigo: json['codigo'],
      regionalId: json['regionalId'],
      dataCriacao: DateTime.parse(json['dataCriacao']),
      ativo: json['ativo'] ?? true,
    );
  }
}

class DadosAlunos {
  final String id;
  final String escolaId;
  final String distribuicaoId;
  final String anoLetivo;
  final int numeroDistribuicao;
  final Map<String, DadosModalidade> modalidades; // modalidade -> dados
  final DateTime dataAtualizacao;
  final bool enviado;

  DadosAlunos({
    required this.id,
    required this.escolaId,
    required this.distribuicaoId,
    required this.anoLetivo,
    required this.numeroDistribuicao,
    required this.modalidades,
    required this.dataAtualizacao,
    this.enviado = false,
  });

  DadosAlunos copyWith({
    String? id,
    String? escolaId,
    String? distribuicaoId,
    String? anoLetivo,
    int? numeroDistribuicao,
    Map<String, DadosModalidade>? modalidades,
    DateTime? dataAtualizacao,
    bool? enviado,
  }) {
    return DadosAlunos(
      id: id ?? this.id,
      escolaId: escolaId ?? this.escolaId,
      distribuicaoId: distribuicaoId ?? this.distribuicaoId,
      anoLetivo: anoLetivo ?? this.anoLetivo,
      numeroDistribuicao: numeroDistribuicao ?? this.numeroDistribuicao,
      modalidades: modalidades ?? this.modalidades,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      enviado: enviado ?? this.enviado,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'escolaId': escolaId,
      'distribuicaoId': distribuicaoId,
      'anoLetivo': anoLetivo,
      'numeroDistribuicao': numeroDistribuicao,
      'modalidades': modalidades.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
      'enviado': enviado,
    };
  }

  factory DadosAlunos.fromJson(Map<String, dynamic> json) {
    final modalidadesJson = json['modalidades'] as Map<String, dynamic>;
    final modalidades = modalidadesJson.map(
      (key, value) => MapEntry(key, DadosModalidade.fromJson(value)),
    );

    return DadosAlunos(
      id: json['id'],
      escolaId: json['escolaId'],
      distribuicaoId: json['distribuicaoId'] ?? '',
      anoLetivo: json['anoLetivo'],
      numeroDistribuicao: json['numeroDistribuicao'],
      modalidades: modalidades,
      dataAtualizacao: DateTime.parse(json['dataAtualizacao']),
      enviado: json['enviado'] ?? false,
    );
  }
}

class DadosModalidade {
  final String modalidade;
  final int matriculados;
  final Map<String, int>
  quantidadeRefeicoes; // quantidadeRefeicaoId -> alunos que fazem

  DadosModalidade({
    required this.modalidade,
    required this.matriculados,
    required this.quantidadeRefeicoes,
  });

  DadosModalidade copyWith({
    String? modalidade,
    int? matriculados,
    Map<String, int>? quantidadeRefeicoes,
  }) {
    return DadosModalidade(
      modalidade: modalidade ?? this.modalidade,
      matriculados: matriculados ?? this.matriculados,
      quantidadeRefeicoes: quantidadeRefeicoes ?? this.quantidadeRefeicoes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'modalidade': modalidade,
      'matriculados': matriculados,
      'quantidadeRefeicoes': quantidadeRefeicoes,
    };
  }

  factory DadosModalidade.fromJson(Map<String, dynamic> json) {
    return DadosModalidade(
      modalidade: json['modalidade'],
      matriculados: json['matriculados'],
      quantidadeRefeicoes: Map<String, int>.from(json['quantidadeRefeicoes']),
    );
  }

  // Calcula total de alunos que fazem pelo menos uma refeição
  int get totalAlunosLancham {
    if (quantidadeRefeicoes.isEmpty) return 0;
    return quantidadeRefeicoes.values.reduce((a, b) => a + b);
  }
}

// Enum para modalidades de ensino
enum ModalidadeEnsino {
  preEscola('Pré-escola'),
  fundamental1('Fundamental 1'),
  fundamental2('Fundamental 2'),
  ensinoMedio('Ensino Médio'),
  eja('EJA');

  const ModalidadeEnsino(this.displayName);
  final String displayName;
}
