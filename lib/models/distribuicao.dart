import 'etapa_distribuicao.dart';

// Status de Aquisição - A DEFINIR
// (Movido para StatusProdutoMemoria em memoria_calculo.dart)
// enum StatusAquisicao {
//   aguardandoAquisicao('Aguardando Aquisição'),
//   emLicitacao('Em Licitação'),
//   adquirido('Adquirido'),
//   liberado('Liberado'),
//   esgotado('Esgotado'),
//   cancelado('Cancelado');
//
//   const StatusAquisicao(this.displayName);
//   final String displayName;
// }

// Enum para status da distribuição
enum StatusDistribuicao {
  planejada('Planejada'),
  liberada('Liberada para Escolas'),
  emAndamento('Em Andamento'),
  concluida('Concluída'),
  cancelada('Cancelada');

  const StatusDistribuicao(this.displayName);
  final String displayName;
}

class Distribuicao {
  final String id;
  final String anoLetivo;
  final int numero;
  final String titulo;
  final String descricao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final StatusDistribuicao status;
  final DateTime dataCriacao;
  final DateTime? dataLiberacao;
  final List<String> regioesSelecionadas;
  final List<String> modalidadesSelecionadas;
  final List<String> produtosSelecionados;
  final Map<String, Map<String, int>>
  alunosPorRegiaoModalidade; // regiao -> modalidade -> quantidade
  final Map<String, Map<String, int>>
  frequenciaPorQuantidadeRefeicao; // produtoId -> quantidadeRefeicaoId -> frequencia
  final List<String>
  escolasQueEnviaramDados; // IDs das escolas que enviaram dados
  final List<EtapaDistribuicao> etapas; // Etapas do processo de distribuição

  Distribuicao({
    required this.id,
    required this.anoLetivo,
    required this.numero,
    required this.titulo,
    required this.descricao,
    required this.dataInicio,
    required this.dataFim,
    required this.status,
    required this.dataCriacao,
    this.dataLiberacao,
    required this.regioesSelecionadas,
    required this.modalidadesSelecionadas,
    required this.produtosSelecionados,
    required this.alunosPorRegiaoModalidade,
    required this.frequenciaPorQuantidadeRefeicao,
    this.escolasQueEnviaramDados = const [],
    this.etapas = const [],
  });

  Distribuicao copyWith({
    String? id,
    String? anoLetivo,
    int? numero,
    String? titulo,
    String? descricao,
    DateTime? dataInicio,
    DateTime? dataFim,
    StatusDistribuicao? status,
    DateTime? dataCriacao,
    DateTime? dataLiberacao,
    List<String>? regioesSelecionadas,
    List<String>? modalidadesSelecionadas,
    List<String>? produtosSelecionados,
    Map<String, Map<String, int>>? alunosPorRegiaoModalidade,
    Map<String, Map<String, int>>? frequenciaPorQuantidadeRefeicao,
    List<String>? escolasQueEnviaramDados,
    List<EtapaDistribuicao>? etapas,
  }) {
    return Distribuicao(
      id: id ?? this.id,
      anoLetivo: anoLetivo ?? this.anoLetivo,
      numero: numero ?? this.numero,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      status: status ?? this.status,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataLiberacao: dataLiberacao ?? this.dataLiberacao,
      regioesSelecionadas: regioesSelecionadas ?? this.regioesSelecionadas,
      modalidadesSelecionadas:
          modalidadesSelecionadas ?? this.modalidadesSelecionadas,
      produtosSelecionados: produtosSelecionados ?? this.produtosSelecionados,
      alunosPorRegiaoModalidade:
          alunosPorRegiaoModalidade ?? this.alunosPorRegiaoModalidade,
      frequenciaPorQuantidadeRefeicao:
          frequenciaPorQuantidadeRefeicao ??
          this.frequenciaPorQuantidadeRefeicao,
      escolasQueEnviaramDados:
          escolasQueEnviaramDados ?? this.escolasQueEnviaramDados,
      etapas: etapas ?? this.etapas,
    );
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
      'status': status.name,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataLiberacao': dataLiberacao?.toIso8601String(),
      'regioesSelecionadas': regioesSelecionadas,
      'modalidadesSelecionadas': modalidadesSelecionadas,
      'produtosSelecionados': produtosSelecionados,
      'alunosPorRegiaoModalidade': alunosPorRegiaoModalidade,
      'frequenciaPorQuantidadeRefeicao': frequenciaPorQuantidadeRefeicao,
      'escolasQueEnviaramDados': escolasQueEnviaramDados,
      'etapas': etapas.map((e) => e.toJson()).toList(),
    };
  }

  factory Distribuicao.fromJson(Map<String, dynamic> json) {
    return Distribuicao(
      id: json['id'],
      anoLetivo: json['anoLetivo'],
      numero: json['numero'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      status: StatusDistribuicao.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StatusDistribuicao.planejada,
      ),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataLiberacao: json['dataLiberacao'] != null
          ? DateTime.parse(json['dataLiberacao'])
          : null,
      regioesSelecionadas: List<String>.from(json['regioesSelecionadas'] ?? []),
      modalidadesSelecionadas: List<String>.from(
        json['modalidadesSelecionadas'] ?? [],
      ),
      produtosSelecionados: List<String>.from(
        json['produtosSelecionados'] ?? [],
      ),
      alunosPorRegiaoModalidade: json['alunosPorRegiaoModalidade'] != null
          ? Map<String, Map<String, int>>.from(
              (json['alunosPorRegiaoModalidade'] as Map).map(
                (key, value) => MapEntry(key, Map<String, int>.from(value)),
              ),
            )
          : {},
      frequenciaPorQuantidadeRefeicao:
          json['frequenciaPorQuantidadeRefeicao'] != null
          ? Map<String, Map<String, int>>.from(
              (json['frequenciaPorQuantidadeRefeicao'] as Map).map(
                (key, value) => MapEntry(key, Map<String, int>.from(value)),
              ),
            )
          : {},
      escolasQueEnviaramDados: json['escolasQueEnviaramDados'] != null
          ? List<String>.from(json['escolasQueEnviaramDados'])
          : [],
      etapas: json['etapas'] != null
          ? (json['etapas'] as List)
                .map((e) => EtapaDistribuicao.fromJson(e))
                .toList()
          : [],
    );
  }

  bool get isLiberadaParaEscolas {
    return status == StatusDistribuicao.liberada;
  }

  bool get isAtiva {
    return status == StatusDistribuicao.liberada ||
        status == StatusDistribuicao.emAndamento;
  }

  String get periodoTexto {
    return '${dataInicio.day.toString().padLeft(2, '0')}/${dataInicio.month.toString().padLeft(2, '0')} - ${dataFim.day.toString().padLeft(2, '0')}/${dataFim.month.toString().padLeft(2, '0')}';
  }

  // Métodos para trabalhar com etapas
  List<EtapaDistribuicao> get etapasAtivas {
    return etapas.where((e) => e.ativa).toList();
  }

  List<EtapaDistribuicao> get etapasConcluidas {
    return etapas.where((e) => e.concluida).toList();
  }

  EtapaDistribuicao? getEtapaPorTipo(TipoEtapaDistribuicao tipo) {
    try {
      return etapas.firstWhere((e) => e.tipo == tipo);
    } catch (e) {
      return null;
    }
  }

  bool isEtapaAtiva(TipoEtapaDistribuicao tipo) {
    final etapa = getEtapaPorTipo(tipo);
    return etapa != null && etapa.ativa && !etapa.concluida;
  }

  bool isEtapaConcluida(TipoEtapaDistribuicao tipo) {
    final etapa = getEtapaPorTipo(tipo);
    return etapa != null && etapa.concluida;
  }
}
