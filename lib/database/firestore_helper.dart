import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/quantidades_refeicao_data.dart';
import '../data/regioes_data.dart';
import '../models/ano_letivo.dart';
import '../models/quadro_tecnico_descritivo.dart';
import '../models/distribuicao.dart';
import '../models/escola.dart';
import '../models/fonte_pagamento.dart';
import '../models/fornecedor.dart';
import '../models/memoria_calculo.dart';
import '../models/processo_aquisicao.dart';
import '../models/produto.dart';
import '../models/quantidade_refeicao.dart';
import '../models/regiao.dart';

class FirestoreHelper {
  static final FirestoreHelper _instance = FirestoreHelper._internal();
  factory FirestoreHelper() => _instance;
  FirestoreHelper._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // Coleções
  static const String _anosLetivosCollection = 'anos_letivos';
  static const String _regioesCollection = 'regioes';
  static const String _quantidadesRefeicaoCollection = 'quantidades_refeicao';
  static const String _produtosCollection = 'produtos';
  static const String _fornecedoresCollection = 'fornecedores';
  static const String _fontesPagamentoCollection = 'fontes_pagamento';
  static const String _escolasCollection = 'escolas';
  static const String _dadosAlunosCollection = 'dados_alunos';
  static const String _distribuicoesCollection = 'distribuicoes';
  static const String _memoriasCalculoCollection = 'memorias_calculo';
  static const String _processosAquisicaoCollection = 'processos_aquisicao';
  static const String _quadrosTecnicosCollection =
      'quadros_tecnicos_descritivos';

  // Inicializar dados padrão
  Future<void> initializeDefaultData() async {
    // Verificar e inserir Tipo  de Refeição
    final quantidadesSnapshot = await _firestore
        .collection(_quantidadesRefeicaoCollection)
        .get();
    if (quantidadesSnapshot.docs.isEmpty) {
      final quantidades = QuantidadesRefeicaoData.getQuantidadesIniciais();
      for (final quantidade in quantidades) {
        await _firestore
            .collection(_quantidadesRefeicaoCollection)
            .doc(quantidade.id)
            .set(quantidade.toJson());
      }
    }

    // Verificar e inserir regiões
    final regioesSnapshot = await _firestore
        .collection(_regioesCollection)
        .get();
    if (regioesSnapshot.docs.isEmpty) {
      final regioes = RegioesData.getRegioesIniciais();
      for (final regiao in regioes) {
        await _firestore
            .collection(_regioesCollection)
            .doc(regiao.id)
            .set(regiao.toJson());
      }
    }
  }

  // Anos Letivos
  Future<List<AnoLetivo>> getAnosLetivos() async {
    final snapshot = await _firestore.collection(_anosLetivosCollection).get();
    return snapshot.docs.map((doc) => AnoLetivo.fromJson(doc.data())).toList();
  }

  Future<void> saveAnoLetivo(AnoLetivo anoLetivo) async {
    await _firestore
        .collection(_anosLetivosCollection)
        .doc(anoLetivo.id)
        .set(anoLetivo.toJson());
  }

  Future<void> updateAnoLetivo(AnoLetivo anoLetivo) async {
    await _firestore
        .collection(_anosLetivosCollection)
        .doc(anoLetivo.id)
        .update(anoLetivo.toJson());
  }

  Future<void> deleteAnoLetivo(String id) async {
    await _firestore.collection(_anosLetivosCollection).doc(id).delete();
  }

  // Regiões
  Future<List<Regiao>> getRegioes() async {
    final snapshot = await _firestore.collection(_regioesCollection).get();
    return snapshot.docs.map((doc) => Regiao.fromJson(doc.data())).toList();
  }

  Future<void> saveRegiao(Regiao regiao) async {
    await _firestore
        .collection(_regioesCollection)
        .doc(regiao.id)
        .set(regiao.toJson());
  }

  Future<void> updateRegioes(List<Regiao> regioes) async {
    final batch = _firestore.batch();
    for (final regiao in regioes) {
      batch.set(
        _firestore.collection(_regioesCollection).doc(regiao.id),
        regiao.toJson(),
      );
    }
    await batch.commit();
  }

  // Tipo  de Refeição
  Future<List<QuantidadeRefeicao>> getQuantidadesRefeicao() async {
    final snapshot = await _firestore
        .collection(_quantidadesRefeicaoCollection)
        .get();
    return snapshot.docs
        .map((doc) => QuantidadeRefeicao.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveQuantidadeRefeicao(QuantidadeRefeicao quantidade) async {
    await _firestore
        .collection(_quantidadesRefeicaoCollection)
        .doc(quantidade.id)
        .set(quantidade.toJson());
  }

  Future<void> updateQuantidadeRefeicao(QuantidadeRefeicao quantidade) async {
    await _firestore
        .collection(_quantidadesRefeicaoCollection)
        .doc(quantidade.id)
        .update(quantidade.toJson());
  }

  Future<void> deleteQuantidadeRefeicao(String id) async {
    await _firestore
        .collection(_quantidadesRefeicaoCollection)
        .doc(id)
        .delete();
  }

  // Produtos
  Future<List<Produto>> getProdutos() async {
    final snapshot = await _firestore.collection(_produtosCollection).get();
    return snapshot.docs.map((doc) => Produto.fromJson(doc.data())).toList();
  }

  Future<void> saveProduto(Produto produto) async {
    await _firestore
        .collection(_produtosCollection)
        .doc(produto.id)
        .set(produto.toJson());
  }

  Future<void> updateProduto(Produto produto) async {
    await _firestore
        .collection(_produtosCollection)
        .doc(produto.id)
        .update(produto.toJson());
  }

  Future<void> deleteProduto(String id) async {
    await _firestore.collection(_produtosCollection).doc(id).delete();
  }

  // Fornecedores
  Future<List<Fornecedor>> getFornecedores() async {
    final snapshot = await _firestore.collection(_fornecedoresCollection).get();
    return snapshot.docs
        .map((doc) => Fornecedor.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveFornecedor(Fornecedor fornecedor) async {
    final fornecedorAtualizado = fornecedor.copyWith(
      criadoEm: DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    await _firestore
        .collection(_fornecedoresCollection)
        .doc(fornecedorAtualizado.id)
        .set(fornecedorAtualizado.toJson());
  }

  Future<void> updateFornecedor(Fornecedor fornecedor) async {
    final fornecedorAtualizado =
        fornecedor.copyWith(atualizadoEm: DateTime.now());

    await _firestore
        .collection(_fornecedoresCollection)
        .doc(fornecedorAtualizado.id)
        .update(fornecedorAtualizado.toJson());
  }

  Future<void> atualizarStatusFornecedor(String id, bool ativo) async {
    await _firestore.collection(_fornecedoresCollection).doc(id).update({
      'ativo': ativo,
      'atualizadoEm': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteFornecedor(String id) async {
    await _firestore.collection(_fornecedoresCollection).doc(id).delete();
  }

  // Fontes de Pagamento
  Future<List<FontePagamento>> getFontesPagamento() async {
    final snapshot =
        await _firestore.collection(_fontesPagamentoCollection).get();
    return snapshot.docs
        .map((doc) => FontePagamento.fromJson(doc.data()))
        .toList();
  }

  Future<List<FontePagamento>> getFontesPagamentoAtivas() async {
    final snapshot = await _firestore
        .collection(_fontesPagamentoCollection)
        .where('ativo', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => FontePagamento.fromJson(doc.data()))
        .toList();
  }

  Future<void> saveFontePagamento(FontePagamento fonte) async {
    final agora = DateTime.now();
    final fonteAtualizada = fonte.copyWith(
      dataCriacao: fonte.id.isEmpty ? agora : fonte.dataCriacao,
      dataAtualizacao: agora,
    );
    await _firestore
        .collection(_fontesPagamentoCollection)
        .doc(fonteAtualizada.id)
        .set(fonteAtualizada.toJson());
  }

  Future<void> updateFontePagamento(FontePagamento fonte) async {
    final fonteAtualizada = fonte.copyWith(
      dataAtualizacao: DateTime.now(),
    );
    await _firestore
        .collection(_fontesPagamentoCollection)
        .doc(fonteAtualizada.id)
        .update(fonteAtualizada.toJson());
  }

  Future<void> toggleFontePagamentoStatus(String id, bool ativo) async {
    await _firestore.collection(_fontesPagamentoCollection).doc(id).update({
      'ativo': ativo,
      'dataAtualizacao': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteFontePagamento(String id) async {
    await _firestore.collection(_fontesPagamentoCollection).doc(id).delete();
  }

  // Escolas
  Future<List<Escola>> getEscolas() async {
    final snapshot = await _firestore.collection(_escolasCollection).get();
    return snapshot.docs.map((doc) => Escola.fromJson(doc.data())).toList();
  }

  Future<void> saveEscola(Escola escola) async {
    await _firestore
        .collection(_escolasCollection)
        .doc(escola.id)
        .set(escola.toJson());
  }

  Future<void> updateEscola(Escola escola) async {
    await _firestore
        .collection(_escolasCollection)
        .doc(escola.id)
        .update(escola.toJson());
  }

  Future<void> deleteEscola(String id) async {
    await _firestore.collection(_escolasCollection).doc(id).delete();
  }

  // Dados de Alunos
  Future<List<DadosAlunos>> getDadosAlunos() async {
    final snapshot = await _firestore.collection(_dadosAlunosCollection).get();
    return snapshot.docs
        .map((doc) => DadosAlunos.fromJson(doc.data()))
        .toList();
  }

  Future<List<DadosAlunos>> getDadosAlunosPorEscola(String escolaId) async {
    final snapshot = await _firestore
        .collection(_dadosAlunosCollection)
        .where('escolaId', isEqualTo: escolaId)
        .get();
    return snapshot.docs
        .map((doc) => DadosAlunos.fromJson(doc.data()))
        .toList();
  }

  Future<DadosAlunos?> getDadosAlunosPorEscolaEDistribuicao(
    String escolaId,
    String distribuicaoId,
  ) async {
    final snapshot = await _firestore
        .collection(_dadosAlunosCollection)
        .where('escolaId', isEqualTo: escolaId)
        .where('distribuicaoId', isEqualTo: distribuicaoId)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DadosAlunos.fromJson(snapshot.docs.first.data());
  }

  Future<void> saveDadosAlunos(DadosAlunos dadosAlunos) async {
    await _firestore
        .collection(_dadosAlunosCollection)
        .doc(dadosAlunos.id)
        .set(dadosAlunos.toJson());
  }

  Future<void> updateDadosAlunos(DadosAlunos dadosAlunos) async {
    await _firestore
        .collection(_dadosAlunosCollection)
        .doc(dadosAlunos.id)
        .update(dadosAlunos.toJson());
  }

  // Distribuições
  Future<List<Distribuicao>> getDistribuicoes() async {
    final snapshot = await _firestore
        .collection(_distribuicoesCollection)
        .get();
    return snapshot.docs
        .map((doc) => Distribuicao.fromJson(doc.data()))
        .toList();
  }

  Future<List<Distribuicao>> getDistribuicoesPorAno(String anoLetivo) async {
    final snapshot = await _firestore
        .collection(_distribuicoesCollection)
        .where('anoLetivo', isEqualTo: anoLetivo)
        .get();
    return snapshot.docs
        .map((doc) => Distribuicao.fromJson(doc.data()))
        .toList();
  }

  Future<Distribuicao?> getDistribuicaoPorId(String id) async {
    final doc = await _firestore
        .collection(_distribuicoesCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return Distribuicao.fromJson(doc.data()!);
  }

  Future<void> saveDistribuicao(Distribuicao distribuicao) async {
    await _firestore
        .collection(_distribuicoesCollection)
        .doc(distribuicao.id)
        .set(distribuicao.toJson());
  }

  Future<void> updateDistribuicao(Distribuicao distribuicao) async {
    await _firestore
        .collection(_distribuicoesCollection)
        .doc(distribuicao.id)
        .set(distribuicao.toJson());
  }

  Future<void> deleteDistribuicao(String id) async {
    await _firestore.collection(_distribuicoesCollection).doc(id).delete();
  }

  // ========== MÉTODOS PARA MEMÓRIA DE CÁLCULO ==========

  Future<List<MemoriaCalculo>> getMemoriasCalculo() async {
    final snapshot = await _firestore
        .collection(_memoriasCalculoCollection)
        .get();
    return snapshot.docs
        .map((doc) => MemoriaCalculo.fromJson(doc.data()))
        .toList();
  }

  Future<List<MemoriaCalculo>> getMemoriasCalculoDisponibilizadas() async {
    final snapshot = await _firestore
        .collection(_memoriasCalculoCollection)
        .where('disponibilizadaParaDiae', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => MemoriaCalculo.fromJson(doc.data()))
        .toList();
  }

  Future<List<MemoriaCalculo>> getMemoriasCalculoPorAno(
    String anoLetivo,
  ) async {
    final snapshot = await _firestore
        .collection(_memoriasCalculoCollection)
        .where('anoLetivo', isEqualTo: anoLetivo)
        .get();
    return snapshot.docs
        .map((doc) => MemoriaCalculo.fromJson(doc.data()))
        .toList();
  }

  // Buscar memória de cálculo por ID
  Future<MemoriaCalculo?> getMemoriaCalculoPorId(String id) async {
    final doc = await _firestore
        .collection(_memoriasCalculoCollection)
        .doc(id)
        .get();

    if (doc.exists) {
      return MemoriaCalculo.fromJson(doc.data()!);
    }
    return null;
  }

  Future<MemoriaCalculo?> getMemoriaCalculo(String id) async {
    final doc = await _firestore
        .collection(_memoriasCalculoCollection)
        .doc(id)
        .get();
    if (doc.exists) {
      return MemoriaCalculo.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> saveMemoriaCalculo(MemoriaCalculo memoriaCalculo) async {
    await _firestore
        .collection(_memoriasCalculoCollection)
        .doc(memoriaCalculo.id)
        .set(memoriaCalculo.toJson());
  }

  Future<void> updateMemoriaCalculo(MemoriaCalculo memoriaCalculo) async {
    await _firestore
        .collection(_memoriasCalculoCollection)
        .doc(memoriaCalculo.id)
        .set(memoriaCalculo.toJson());
  }

  Future<void> deleteMemoriaCalculo(String id) async {
    await _firestore.collection(_memoriasCalculoCollection).doc(id).delete();
  }

  // Método para obter dados de alunos por região e distribuição
  Future<List<DadosAlunosPorRegiao>> getDadosAlunosPorRegiaoEDistribuicao(
    String anoLetivo,
    int numeroDistribuicao,
  ) async {
    // Buscar dados de alunos da distribuição específica
    final dadosAlunos = await _firestore
        .collection(_dadosAlunosCollection)
        .where('anoLetivo', isEqualTo: anoLetivo)
        .where('numeroDistribuicao', isEqualTo: numeroDistribuicao)
        .get();

    // Buscar escolas para mapear regional -> região
    final escolas = await getEscolas();
    final regioes = await getRegioes();

    // Agrupar dados por região
    final Map<String, DadosAlunosPorRegiao> dadosPorRegiao = {};

    for (final dadoAluno in dadosAlunos.docs) {
      final dados = DadosAlunos.fromJson(dadoAluno.data());
      final escola = escolas.firstWhere((e) => e.id == dados.escolaId);
      final regional = regioes
          .expand((r) => r.regionais)
          .firstWhere((reg) => reg.id == escola.regionalId);
      final regiao = regioes.firstWhere(
        (r) => r.regionais.any((reg) => reg.id == regional.id),
      );

      if (!dadosPorRegiao.containsKey(regiao.id)) {
        dadosPorRegiao[regiao.id] = DadosAlunosPorRegiao(
          regiaoId: regiao.id,
          regiaoNome: regiao.nome,
          alunosPorModalidade: {},
          alunosPorModalidadeQuantidade: {},
        );
      }

      // Processar dados por modalidade
      for (final modalidadeEntry in dados.modalidades.entries) {
        final modalidade = modalidadeEntry.key;
        final dadosModalidade = modalidadeEntry.value;

        // Total por modalidade
        final totalModalidade = dadosModalidade.quantidadeRefeicoes.values
            .fold<int>(0, (total, qtd) => total + qtd);
        dadosPorRegiao[regiao.id]!.alunosPorModalidade[modalidade] =
            (dadosPorRegiao[regiao.id]!.alunosPorModalidade[modalidade] ?? 0) +
            totalModalidade;

        // Por Tipo de refeição
        if (!dadosPorRegiao[regiao.id]!.alunosPorModalidadeQuantidade
            .containsKey(modalidade)) {
          dadosPorRegiao[regiao.id]!.alunosPorModalidadeQuantidade[modalidade] =
              {};
        }

        for (final entry in dadosModalidade.quantidadeRefeicoes.entries) {
          final qtdAtual =
              dadosPorRegiao[regiao.id]!
                  .alunosPorModalidadeQuantidade[modalidade]![entry.key] ??
              0;
          dadosPorRegiao[regiao.id]!
                  .alunosPorModalidadeQuantidade[modalidade]![entry.key] =
              qtdAtual + entry.value;
        }
      }
    }

    return dadosPorRegiao.values.toList();
  }

  // ==================== PROCESSOS DE AQUISIÇÃO ====================

  // Salvar processo de aquisição
  Future<void> saveProcessoAquisicao(ProcessoAquisicao processo) async {
    await _firestore
        .collection(_processosAquisicaoCollection)
        .doc(processo.id)
        .set(processo.toJson());
  }

  // Buscar todos os processos de aquisição
  Future<List<ProcessoAquisicao>> getProcessosAquisicao() async {
    final snapshot = await _firestore
        .collection(_processosAquisicaoCollection)
        .orderBy('dataCriacao', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProcessoAquisicao.fromJson(doc.data()))
        .toList();
  }

  // Buscar processos de aquisição por ano letivo
  Future<List<ProcessoAquisicao>> getProcessosAquisicaoPorAno(
    String anoLetivo,
  ) async {
    final snapshot = await _firestore
        .collection(_processosAquisicaoCollection)
        .where('anoLetivo', isEqualTo: anoLetivo)
        .orderBy('dataCriacao', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProcessoAquisicao.fromJson(doc.data()))
        .toList();
  }

  // Buscar processo de aquisição por ID
  Future<ProcessoAquisicao?> getProcessoAquisicaoPorId(String id) async {
    final doc = await _firestore
        .collection(_processosAquisicaoCollection)
        .doc(id)
        .get();

    if (doc.exists) {
      return ProcessoAquisicao.fromJson(doc.data()!);
    }
    return null;
  }

  // Buscar processos de aquisição por memória de cálculo
  Future<List<ProcessoAquisicao>> getProcessosAquisicaoPorMemoria(
    String memoriaId,
  ) async {
    final snapshot = await _firestore
        .collection(_processosAquisicaoCollection)
        .where('memoriaCalculoId', isEqualTo: memoriaId)
        .orderBy('dataCriacao', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProcessoAquisicao.fromJson(doc.data()))
        .toList();
  }

  // Atualizar fase do processo
  Future<void> atualizarFaseProcesso(
    String processoId,
    FaseProcessoAquisicao novaFase,
    FaseProcesso dadosFase,
  ) async {
    final processo = await getProcessoAquisicaoPorId(processoId);
    if (processo == null) return;

    final fasesAtualizadas = Map<FaseProcessoAquisicao, FaseProcesso>.from(
      processo.fases,
    );
    fasesAtualizadas[novaFase] = dadosFase;

    final processoAtualizado = processo.copyWith(
      faseAtual: novaFase,
      fases: fasesAtualizadas,
    );

    await saveProcessoAquisicao(processoAtualizado);
  }

  // Concluir processo de aquisição
  Future<void> concluirProcessoAquisicao(String processoId) async {
    final processo = await getProcessoAquisicaoPorId(processoId);
    if (processo == null) return;

    final processoAtualizado = processo.copyWith(
      status: StatusProcessoAquisicao.concluido,
      dataConclusao: DateTime.now(),
    );

    await saveProcessoAquisicao(processoAtualizado);

    // Atualizar status dos produtos na memória de cálculo
    await _atualizarStatusProdutosMemoria(processo.memoriaCalculoId);
  }

  // Atualizar status dos produtos na memória de cálculo
  Future<void> _atualizarStatusProdutosMemoria(String memoriaId) async {
    try {
      final memoria = await getMemoriaCalculoPorId(memoriaId);
      if (memoria == null) return;

      // Atualizar todos os produtos para "adquirido"
      final statusAtualizados = <String, StatusProdutoMemoria>{};
      for (final produtoId in memoria.produtosSelecionados) {
        statusAtualizados[produtoId] = StatusProdutoMemoria.adquirido;
      }

      final memoriaAtualizada = memoria.copyWith(
        statusProdutos: statusAtualizados,
      );

      await saveMemoriaCalculo(memoriaAtualizada);
    } catch (e) {
      print('Erro ao atualizar status dos produtos: $e');
    }
  }

  // Deletar processo de aquisição
  Future<void> deleteProcessoAquisicao(String id) async {
    await _firestore.collection(_processosAquisicaoCollection).doc(id).delete();
  }

  // ==================== QUADRO TÉCNICO DESCRITIVO (QTD) ====================

  Future<void> saveQuadroTecnicoDescritivo(
    QuadroTecnicoDescritivo quadro,
  ) async {
    await _firestore
        .collection(_quadrosTecnicosCollection)
        .doc(quadro.id)
        .set(quadro.toJson());
  }

  Future<List<QuadroTecnicoDescritivo>> getQuadrosTecnicosPorProcesso(
    String processoId,
  ) async {
    final snapshot = await _firestore
        .collection(_quadrosTecnicosCollection)
        .where('processoId', isEqualTo: processoId)
        .orderBy('dataCriacao')
        .get();

    return snapshot.docs
        .map((doc) => QuadroTecnicoDescritivo.fromJson(doc.data()))
        .toList();
  }

  Future<List<QuadroTecnicoDescritivo>> getQuadrosTecnicosPorMemoria(
    String memoriaId,
  ) async {
    final snapshot = await _firestore
        .collection(_quadrosTecnicosCollection)
        .where('memoriaCalculoId', isEqualTo: memoriaId)
        .orderBy('dataCriacao')
        .get();

    return snapshot.docs
        .map((doc) => QuadroTecnicoDescritivo.fromJson(doc.data()))
        .toList();
  }

  Future<void> deleteQuadroTecnico(String id) async {
    await _firestore.collection(_quadrosTecnicosCollection).doc(id).delete();
  }
}
