import 'distribuicao.dart';
import 'escola.dart';
import 'produto.dart';

class RelatorioDistribuicao {
  final Distribuicao distribuicao;
  final ModalidadeEnsino modalidade;
  final List<DadosRelatorioRegional> dadosRegionais;
  final DadosRelatorioTotal totalGeral;

  RelatorioDistribuicao({
    required this.distribuicao,
    required this.modalidade,
    required this.dadosRegionais,
    required this.totalGeral,
  });
}

class DadosRelatorioRegional {
  final String nomeRegiao;
  final String descricaoRegionais;
  final List<DadosRelatorioProduto> produtos;

  DadosRelatorioRegional({
    required this.nomeRegiao,
    required this.descricaoRegionais,
    required this.produtos,
  });

  int get totalAlunos {
    if (produtos.isEmpty) return 0;
    return produtos.first.totalAlunos;
  }

  double get totalQuantidade {
    return produtos.fold(0.0, (sum, produto) => sum + produto.totalQuantidade);
  }
}

class DadosRelatorioProduto {
  final Produto produto;
  final Map<String, int>
  alunosPorQuantidadeRefeicao; // quantidadeRefeicaoId -> alunos
  final Map<String, double>
  perCapitaPorQuantidadeRefeicao; // quantidadeRefeicaoId -> per capita
  final Map<String, int>
  frequenciaPorQuantidadeRefeicao; // quantidadeRefeicaoId -> frequencia
  final Map<String, double>
  quantidadePorModalidade; // quantidadeRefeicaoId -> quantidade

  DadosRelatorioProduto({
    required this.produto,
    required this.alunosPorQuantidadeRefeicao,
    required this.perCapitaPorQuantidadeRefeicao,
    required this.frequenciaPorQuantidadeRefeicao,
    required this.quantidadePorModalidade,
  });

  int get totalAlunos {
    return alunosPorQuantidadeRefeicao.values.fold(
      0,
      (sum, alunos) => sum + alunos,
    );
  }

  double get totalQuantidade {
    return quantidadePorModalidade.values.fold(0.0, (sum, qtd) => sum + qtd);
  }
}

class DadosRelatorioTotal {
  final List<DadosRelatorioProduto> produtos;

  DadosRelatorioTotal({required this.produtos});

  int get totalAlunos {
    return produtos.fold(0, (sum, produto) => sum + produto.totalAlunos);
  }

  double get totalQuantidade {
    return produtos.fold(0.0, (sum, produto) => sum + produto.totalQuantidade);
  }
}

class RelatorioBuilder {
  static Future<RelatorioDistribuicao> buildRelatorio({
    required Distribuicao distribuicao,
    required ModalidadeEnsino modalidade,
    required List<Produto> produtos,
    required List<Escola> escolas,
    required Map<String, Map<String, int>> alunosPorRegiaoModalidade,
    required Map<String, Map<String, int>> frequenciaPorQuantidadeRefeicao,
  }) async {
    final dadosRegionais = <DadosRelatorioRegional>[];

    // Agrupar escolas por região
    final escolasPorRegiao = <String, List<Escola>>{};
    for (final escola in escolas) {
      if (!escolasPorRegiao.containsKey(escola.regionalId)) {
        escolasPorRegiao[escola.regionalId] = [];
      }
      escolasPorRegiao[escola.regionalId]!.add(escola);
    }

    // Para cada região selecionada na distribuição
    for (final regiaoId in distribuicao.regioesSelecionadas) {
      final dadosProdutos = <DadosRelatorioProduto>[];

      // Para cada produto selecionado na distribuição
      for (final produtoId in distribuicao.produtosSelecionados) {
        final produto = produtos.firstWhere((p) => p.id == produtoId);

        final alunosPorQtd = <String, int>{};
        final perCapitaPorQtd = <String, double>{};
        final frequenciaPorQtd = <String, int>{};
        final quantidadePorQtd = <String, double>{};

        // Para cada Tipo de refeição
        for (final qtdRefId
            in produto.perCapita.keys
                .where((key) => key.startsWith('${modalidade.name}_'))
                .map((key) => key.split('_')[1])) {
          final alunos =
              alunosPorRegiaoModalidade[regiaoId]?[modalidade.name] ?? 0;
          final perCapita = produto.getPerCapita(modalidade, qtdRefId);
          final frequencia =
              frequenciaPorQuantidadeRefeicao[produtoId]?[qtdRefId] ?? 0;

          alunosPorQtd[qtdRefId] = alunos;
          perCapitaPorQtd[qtdRefId] = perCapita;
          frequenciaPorQtd[qtdRefId] = frequencia;

          // Cálculo: alunos * per capita * frequência
          quantidadePorQtd[qtdRefId] = (alunos * perCapita * frequencia)
              .roundToDouble();
        }

        dadosProdutos.add(
          DadosRelatorioProduto(
            produto: produto,
            alunosPorQuantidadeRefeicao: alunosPorQtd,
            perCapitaPorQuantidadeRefeicao: perCapitaPorQtd,
            frequenciaPorQuantidadeRefeicao: frequenciaPorQtd,
            quantidadePorModalidade: quantidadePorQtd,
          ),
        );
      }
    }

    // Calcular total geral
    final produtosTotal = <DadosRelatorioProduto>[];
    for (final produtoId in distribuicao.produtosSelecionados) {
      final produto = produtos.firstWhere((p) => p.id == produtoId);

      final alunosPorQtd = <String, int>{};
      final perCapitaPorQtd = <String, double>{};
      final frequenciaPorQtd = <String, int>{};
      final quantidadePorQtd = <String, double>{};

      for (final qtdRefId
          in produto.perCapita.keys
              .where((key) => key.startsWith('${modalidade.name}_'))
              .map((key) => key.split('_')[1])) {
        int totalAlunos = 0;
        double perCapita = produto.getPerCapita(modalidade, qtdRefId);
        int frequencia =
            frequenciaPorQuantidadeRefeicao[produtoId]?[qtdRefId] ?? 0;

        // Somar alunos de todas as regiões
        for (final regiaoId in distribuicao.regioesSelecionadas) {
          totalAlunos +=
              alunosPorRegiaoModalidade[regiaoId]?[modalidade.name] ?? 0;
        }

        alunosPorQtd[qtdRefId] = totalAlunos;
        perCapitaPorQtd[qtdRefId] = perCapita;
        frequenciaPorQtd[qtdRefId] = frequencia;
        quantidadePorQtd[qtdRefId] = (totalAlunos * perCapita * frequencia)
            .roundToDouble();
      }

      produtosTotal.add(
        DadosRelatorioProduto(
          produto: produto,
          alunosPorQuantidadeRefeicao: alunosPorQtd,
          perCapitaPorQuantidadeRefeicao: perCapitaPorQtd,
          frequenciaPorQuantidadeRefeicao: frequenciaPorQtd,
          quantidadePorModalidade: quantidadePorQtd,
        ),
      );
    }

    return RelatorioDistribuicao(
      distribuicao: distribuicao,
      modalidade: modalidade,
      dadosRegionais: dadosRegionais,
      totalGeral: DadosRelatorioTotal(produtos: produtosTotal),
    );
  }
}
