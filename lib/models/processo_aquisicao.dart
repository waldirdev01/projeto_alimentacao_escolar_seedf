// Enum para as fases do processo de aquisição
enum FaseProcessoAquisicao {
  processoIniciado,
  editalPublicado,
  analisePropostas,
  resultadoFinal,
  publicado;

  String get displayName {
    switch (this) {
      case FaseProcessoAquisicao.processoIniciado:
        return 'Processo Iniciado';
      case FaseProcessoAquisicao.editalPublicado:
        return 'Edital Publicado';
      case FaseProcessoAquisicao.analisePropostas:
        return 'Análise das Propostas';
      case FaseProcessoAquisicao.resultadoFinal:
        return 'Resultado Final';
      case FaseProcessoAquisicao.publicado:
        return 'Publicado';
    }
  }

  String get descricao {
    switch (this) {
      case FaseProcessoAquisicao.processoIniciado:
        return 'Processo de aquisição foi iniciado';
      case FaseProcessoAquisicao.editalPublicado:
        return 'Edital foi publicado para licitação';
      case FaseProcessoAquisicao.analisePropostas:
        return 'Análise das propostas recebidas';
      case FaseProcessoAquisicao.resultadoFinal:
        return 'Resultado final da licitação';
      case FaseProcessoAquisicao.publicado:
        return 'Processo finalizado e publicado';
    }
  }
}

// Enum para status do processo
enum StatusProcessoAquisicao {
  ativo,
  concluido,
  cancelado;

  String get displayName {
    switch (this) {
      case StatusProcessoAquisicao.ativo:
        return 'Ativo';
      case StatusProcessoAquisicao.concluido:
        return 'Concluído';
      case StatusProcessoAquisicao.cancelado:
        return 'Cancelado';
    }
  }
}

class ProcessoAquisicao {
  final String id;
  final String anoLetivo;
  final String titulo;
  final String descricao;
  final String memoriaCalculoId; // ID da memória de cálculo associada
  final FaseProcessoAquisicao faseAtual;
  final StatusProcessoAquisicao status;
  final DateTime dataCriacao;
  final DateTime? dataConclusao;
  final String? observacoes; // Observações gerais do processo
  final Map<FaseProcessoAquisicao, FaseProcesso> fases; // Detalhes de cada fase

  ProcessoAquisicao({
    required this.id,
    required this.anoLetivo,
    required this.titulo,
    required this.descricao,
    required this.memoriaCalculoId,
    required this.faseAtual,
    required this.status,
    required this.dataCriacao,
    this.dataConclusao,
    this.observacoes,
    required this.fases,
  });

  ProcessoAquisicao copyWith({
    String? id,
    String? anoLetivo,
    String? titulo,
    String? descricao,
    String? memoriaCalculoId,
    FaseProcessoAquisicao? faseAtual,
    StatusProcessoAquisicao? status,
    DateTime? dataCriacao,
    DateTime? dataConclusao,
    String? observacoes,
    Map<FaseProcessoAquisicao, FaseProcesso>? fases,
  }) {
    return ProcessoAquisicao(
      id: id ?? this.id,
      anoLetivo: anoLetivo ?? this.anoLetivo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      memoriaCalculoId: memoriaCalculoId ?? this.memoriaCalculoId,
      faseAtual: faseAtual ?? this.faseAtual,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      observacoes: observacoes ?? this.observacoes,
      fases: fases ?? this.fases,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anoLetivo': anoLetivo,
      'titulo': titulo,
      'descricao': descricao,
      'memoriaCalculoId': memoriaCalculoId,
      'faseAtual': faseAtual.name,
      'status': status.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataConclusao': dataConclusao?.toIso8601String(),
      'observacoes': observacoes,
      'fases': fases.map((key, value) => MapEntry(key.name, value.toJson())),
    };
  }

  factory ProcessoAquisicao.fromJson(Map<String, dynamic> json) {
    return ProcessoAquisicao(
      id: json['id'] as String,
      anoLetivo: json['anoLetivo'] as String,
      titulo: json['titulo'] as String,
      descricao: json['descricao'] as String,
      memoriaCalculoId: json['memoriaCalculoId'] as String,
      faseAtual: FaseProcessoAquisicao.values.firstWhere(
        (e) => e.name == json['faseAtual'],
      ),
      status: StatusProcessoAquisicao.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      dataCriacao: DateTime.parse(json['dataCriacao'] as String),
      dataConclusao: json['dataConclusao'] != null
          ? DateTime.parse(json['dataConclusao'] as String)
          : null,
      observacoes: json['observacoes'] as String?,
      fases: (json['fases'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          FaseProcessoAquisicao.values.firstWhere((e) => e.name == key),
          FaseProcesso.fromJson(value as Map<String, dynamic>),
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'anoLetivo': anoLetivo,
      'titulo': titulo,
      'descricao': descricao,
      'memoriaCalculoId': memoriaCalculoId,
      'faseAtual': faseAtual.name,
      'status': status.name,
      'dataCriacao': dataCriacao,
      'dataConclusao': dataConclusao,
      'observacoes': observacoes,
      'fases': fases.map((key, value) => MapEntry(key.name, value.toMap())),
    };
  }

  factory ProcessoAquisicao.fromMap(Map<String, dynamic> map) {
    return ProcessoAquisicao(
      id: map['id'] as String,
      anoLetivo: map['anoLetivo'] as String,
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String,
      memoriaCalculoId: map['memoriaCalculoId'] as String,
      faseAtual: FaseProcessoAquisicao.values.firstWhere(
        (e) => e.name == map['faseAtual'],
      ),
      status: StatusProcessoAquisicao.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      dataCriacao: map['dataCriacao'] as DateTime,
      dataConclusao: map['dataConclusao'] as DateTime?,
      observacoes: map['observacoes'] as String?,
      fases: (map['fases'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          FaseProcessoAquisicao.values.firstWhere((e) => e.name == key),
          FaseProcesso.fromMap(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class FaseProcesso {
  final bool concluida;
  final DateTime? dataInicio;
  final DateTime? dataConclusao;
  final String? observacoes;
  final String? responsavel;

  FaseProcesso({
    required this.concluida,
    this.dataInicio,
    this.dataConclusao,
    this.observacoes,
    this.responsavel,
  });

  FaseProcesso copyWith({
    bool? concluida,
    DateTime? dataInicio,
    DateTime? dataConclusao,
    String? observacoes,
    String? responsavel,
  }) {
    return FaseProcesso(
      concluida: concluida ?? this.concluida,
      dataInicio: dataInicio ?? this.dataInicio,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      observacoes: observacoes ?? this.observacoes,
      responsavel: responsavel ?? this.responsavel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concluida': concluida,
      'dataInicio': dataInicio?.toIso8601String(),
      'dataConclusao': dataConclusao?.toIso8601String(),
      'observacoes': observacoes,
      'responsavel': responsavel,
    };
  }

  factory FaseProcesso.fromJson(Map<String, dynamic> json) {
    return FaseProcesso(
      concluida: json['concluida'] as bool,
      dataInicio: json['dataInicio'] != null
          ? DateTime.parse(json['dataInicio'] as String)
          : null,
      dataConclusao: json['dataConclusao'] != null
          ? DateTime.parse(json['dataConclusao'] as String)
          : null,
      observacoes: json['observacoes'] as String?,
      responsavel: json['responsavel'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'concluida': concluida,
      'dataInicio': dataInicio,
      'dataConclusao': dataConclusao,
      'observacoes': observacoes,
      'responsavel': responsavel,
    };
  }

  factory FaseProcesso.fromMap(Map<String, dynamic> map) {
    return FaseProcesso(
      concluida: map['concluida'] as bool,
      dataInicio: map['dataInicio'] as DateTime?,
      dataConclusao: map['dataConclusao'] as DateTime?,
      observacoes: map['observacoes'] as String?,
      responsavel: map['responsavel'] as String?,
    );
  }
}
