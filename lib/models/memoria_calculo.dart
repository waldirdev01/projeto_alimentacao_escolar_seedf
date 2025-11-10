// Enum para status de produto dentro de uma memória de cálculo
enum StatusProdutoMemoria {
  emAquisicao,
  adquirido,
  fracassado,
  deserto;

  String get displayName {
    switch (this) {
      case StatusProdutoMemoria.emAquisicao:
        return 'Em Aquisição';
      case StatusProdutoMemoria.adquirido:
        return 'Adquirido';
      case StatusProdutoMemoria.fracassado:
        return 'Fracassado';
      case StatusProdutoMemoria.deserto:
        return 'Deserto';
    }
  }
}

class MemoriaCalculo {
  final String id;
  final String anoLetivo;
  final int numero;
  final String titulo;
  final String descricao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final DateTime dataCriacao;
  final List<String> produtosSelecionados;
  final List<String> modalidadesSelecionadas;
  final List<String> regioesSelecionadas;
  final Map<String, Map<String, double>>
  frequenciaPorModalidadeQuantidade; // modalidade_quantidade -> frequência (LEGADO)
  // Multi-domínios: ex.: gpae, distribuicao, etc.
  // Estrutura: domainId -> modalidade_quantidade -> frequência (LEGADO)
  final Map<String, Map<String, Map<String, double>>> frequenciaByDomain;
  // NOVO: Frequência individual por produto
  // Estrutura: produtoId -> modalidade_quantidade -> frequência
  final Map<String, Map<String, double>> frequenciaPorProduto;
  // Status de cada produto nesta memória de cálculo (gerenciado pela DAE)
  // Estrutura: produtoId -> status
  final Map<String, StatusProdutoMemoria> statusProdutos;
  // Dados de alunos "congelados" no momento da criação da memória
  // Estrutura: regiaoId -> modalidade -> quantidadeRefeicaoId -> número de alunos
  final Map<String, Map<String, Map<String, int>>> dadosAlunosCongelados;

  MemoriaCalculo({
    required this.id,
    required this.anoLetivo,
    required this.numero,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.dataCriacao,
    required this.produtosSelecionados,
    required this.modalidadesSelecionadas,
    required this.regioesSelecionadas,
    required this.frequenciaPorModalidadeQuantidade,
    this.frequenciaByDomain = const {},
    this.frequenciaPorProduto = const {},
    Map<String, StatusProdutoMemoria>? statusProdutos,
    this.dadosAlunosCongelados = const {},
  }) : statusProdutos = statusProdutos ?? {};

  MemoriaCalculo copyWith({
    String? id,
    String? anoLetivo,
    int? numero,
    String? titulo,
    String? descricao,
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataCriacao,
    List<String>? produtosSelecionados,
    List<String>? modalidadesSelecionadas,
    List<String>? regioesSelecionadas,
    Map<String, Map<String, double>>? frequenciaPorModalidadeQuantidade,
    Map<String, Map<String, Map<String, double>>>? frequenciaByDomain,
    Map<String, Map<String, double>>? frequenciaPorProduto,
    Map<String, StatusProdutoMemoria>? statusProdutos,
    Map<String, Map<String, Map<String, int>>>? dadosAlunosCongelados,
  }) {
    return MemoriaCalculo(
      id: id ?? this.id,
      anoLetivo: anoLetivo ?? this.anoLetivo,
      numero: numero ?? this.numero,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      produtosSelecionados: produtosSelecionados ?? this.produtosSelecionados,
      modalidadesSelecionadas:
          modalidadesSelecionadas ?? this.modalidadesSelecionadas,
      regioesSelecionadas: regioesSelecionadas ?? this.regioesSelecionadas,
      frequenciaPorModalidadeQuantidade:
          frequenciaPorModalidadeQuantidade ??
          this.frequenciaPorModalidadeQuantidade,
      frequenciaByDomain: frequenciaByDomain ?? this.frequenciaByDomain,
      frequenciaPorProduto: frequenciaPorProduto ?? this.frequenciaPorProduto,
      statusProdutos: statusProdutos ?? this.statusProdutos,
      dadosAlunosCongelados:
          dadosAlunosCongelados ?? this.dadosAlunosCongelados,
    );
  }

  // Helper para obter status de um produto (padrão: emAquisicao)
  StatusProdutoMemoria getStatusProduto(String produtoId) {
    return statusProdutos[produtoId] ?? StatusProdutoMemoria.emAquisicao;
  }

  // Helper para obter frequência por domínio (LEGADO - mantido por compatibilidade)
  double getFrequenciaForDomain(
    String domainId,
    String modalidadeQuantidadeKey,
  ) {
    final mapaDominio = frequenciaByDomain[domainId];
    if (mapaDominio != null) {
      // Procurar a chave diretamente ou em qualquer modalidade
      for (final modalidadeMap in mapaDominio.values) {
        if (modalidadeMap.containsKey(modalidadeQuantidadeKey)) {
          return modalidadeMap[modalidadeQuantidadeKey] ?? 0.0;
        }
      }
    }
    // Fallback para o mapa legado
    for (final modalidadeMap in frequenciaPorModalidadeQuantidade.values) {
      if (modalidadeMap.containsKey(modalidadeQuantidadeKey)) {
        return modalidadeMap[modalidadeQuantidadeKey] ?? 0.0;
      }
    }
    return 0.0;
  }

  // NOVO: Helper para obter frequência de um produto específico
  double getFrequenciaProduto(
    String produtoId,
    String modalidadeQuantidadeKey,
  ) {
    final frequenciasProduto = frequenciaPorProduto[produtoId];
    if (frequenciasProduto != null &&
        frequenciasProduto.containsKey(modalidadeQuantidadeKey)) {
      return frequenciasProduto[modalidadeQuantidadeKey] ?? 0.0;
    }
    // Fallback para frequência global (legado)
    return getFrequenciaForDomain('gpae', modalidadeQuantidadeKey);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anoLetivo': anoLetivo,
      'numero': numero,
      'titulo': titulo,
      'descricao': descricao,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'dataCriacao': dataCriacao.toIso8601String(),
      'produtosSelecionados': produtosSelecionados,
      'modalidadesSelecionadas': modalidadesSelecionadas,
      'regioesSelecionadas': regioesSelecionadas,
      'frequenciaPorModalidadeQuantidade': frequenciaPorModalidadeQuantidade
          .map(
            (key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v))),
          ),
      'frequenciaByDomain': frequenciaByDomain.map(
        (domain, modalidades) => MapEntry(
          domain,
          modalidades.map(
            (mod, qtds) => MapEntry(mod, qtds.map((k, v) => MapEntry(k, v))),
          ),
        ),
      ),
      'frequenciaPorProduto': frequenciaPorProduto.map(
        (produtoId, frequencias) =>
            MapEntry(produtoId, frequencias.map((k, v) => MapEntry(k, v))),
      ),
      'statusProdutos': statusProdutos.map(
        (key, value) => MapEntry(key, value.name),
      ),
      'dadosAlunosCongelados': dadosAlunosCongelados.map(
        (regiaoKey, regiaoValue) => MapEntry(
          regiaoKey,
          regiaoValue.map(
            (modalidadeKey, modalidadeValue) => MapEntry(
              modalidadeKey,
              modalidadeValue.map(
                (quantidadeKey, quantidadeValue) =>
                    MapEntry(quantidadeKey, quantidadeValue),
              ),
            ),
          ),
        ),
      ),
    };
  }

  factory MemoriaCalculo.fromJson(Map<String, dynamic> json) {
    // Normalizar frequenciaByDomain
    final Map<String, Map<String, Map<String, double>>> fbd = {};
    final dynamicFbd = json['frequenciaByDomain'];
    if (dynamicFbd is Map) {
      dynamicFbd.forEach((domain, modalidades) {
        if (modalidades is Map) {
          fbd[domain as String] = {};
          modalidades.forEach((mod, qtds) {
            if (qtds is Map) {
              fbd[domain]![mod as String] = Map<String, double>.from(qtds);
            }
          });
        }
      });
    }

    // Normalizar statusProdutos
    final Map<String, StatusProdutoMemoria> statusProdutosMap = {};
    final dynamicStatus = json['statusProdutos'];
    if (dynamicStatus is Map) {
      dynamicStatus.forEach((produtoId, statusName) {
        try {
          final status = StatusProdutoMemoria.values.firstWhere(
            (e) => e.name == statusName,
            orElse: () => StatusProdutoMemoria.emAquisicao,
          );
          statusProdutosMap[produtoId as String] = status;
        } catch (_) {
          statusProdutosMap[produtoId as String] =
              StatusProdutoMemoria.emAquisicao;
        }
      });
    }

    // Normalizar frequenciaPorProduto
    final Map<String, Map<String, double>> fpp = {};
    final dynamicFpp = json['frequenciaPorProduto'];
    if (dynamicFpp is Map) {
      dynamicFpp.forEach((produtoId, frequencias) {
        if (frequencias is Map) {
          fpp[produtoId as String] = Map<String, double>.from(frequencias);
        }
      });
    }

    return MemoriaCalculo(
      id: json['id'],
      anoLetivo: json['anoLetivo'],
      numero: json['numero'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      produtosSelecionados: List<String>.from(
        json['produtosSelecionados'] ?? [],
      ),
      modalidadesSelecionadas: List<String>.from(
        json['modalidadesSelecionadas'] ?? [],
      ),
      regioesSelecionadas: List<String>.from(json['regioesSelecionadas'] ?? []),
      frequenciaPorModalidadeQuantidade:
          (json['frequenciaPorModalidadeQuantidade'] as Map<String, dynamic>? ??
                  {})
              .map(
                (key, value) => MapEntry(key, Map<String, double>.from(value)),
              ),
      frequenciaByDomain: fbd,
      frequenciaPorProduto: fpp,
      statusProdutos: statusProdutosMap,
      dadosAlunosCongelados:
          (json['dadosAlunosCongelados'] as Map<String, dynamic>? ?? {}).map(
            (regiaoKey, regiaoValue) => MapEntry(
              regiaoKey,
              (regiaoValue as Map<String, dynamic>).map(
                (modalidadeKey, modalidadeValue) => MapEntry(
                  modalidadeKey,
                  (modalidadeValue as Map<String, dynamic>).map(
                    (qtdKey, qtdValue) => MapEntry(qtdKey, qtdValue as int),
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

// Classe para armazenar dados de alunos por região e distribuição
class DadosAlunosPorRegiao {
  final String regiaoId;
  final String regiaoNome;
  final Map<String, int> alunosPorModalidade; // modalidade -> total de alunos
  final Map<String, Map<String, int>>
  alunosPorModalidadeQuantidade; // modalidade -> quantidade -> alunos

  DadosAlunosPorRegiao({
    required this.regiaoId,
    required this.regiaoNome,
    required this.alunosPorModalidade,
    required this.alunosPorModalidadeQuantidade,
  });

  Map<String, dynamic> toJson() {
    return {
      'regiaoId': regiaoId,
      'regiaoNome': regiaoNome,
      'alunosPorModalidade': alunosPorModalidade,
      'alunosPorModalidadeQuantidade': alunosPorModalidadeQuantidade.map(
        (key, value) => MapEntry(key, value.map((k, v) => MapEntry(k, v))),
      ),
    };
  }

  factory DadosAlunosPorRegiao.fromJson(Map<String, dynamic> json) {
    return DadosAlunosPorRegiao(
      regiaoId: json['regiaoId'],
      regiaoNome: json['regiaoNome'],
      alunosPorModalidade: Map<String, int>.from(
        json['alunosPorModalidade'] ?? {},
      ),
      alunosPorModalidadeQuantidade:
          (json['alunosPorModalidadeQuantidade'] as Map<String, dynamic>? ?? {})
              .map((key, value) => MapEntry(key, Map<String, int>.from(value))),
    );
  }
}
