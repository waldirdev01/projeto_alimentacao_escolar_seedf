import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/escola.dart';
import '../models/produto.dart';
import '../models/quantidade_refeicao.dart';
import '../models/relatorio_distribuicao.dart';

class PDFGenerator {
  /// Arredondamento bancário (arredonda para o par mais próximo quando termina em .5)
  /// Conforme regra da GECNE/DGOF para Notas de Empenho
  static int arredondamentoBancario(double valor) {
    final parteInteira = valor.floor();
    final parteDecimal = valor - parteInteira;

    if (parteDecimal < 0.5) {
      // Menor que 5: não modifica
      return parteInteira;
    } else if (parteDecimal > 0.5) {
      // Maior que 5: incrementa
      return parteInteira + 1;
    } else {
      // Igual a 5: verifica se o anterior é par ou ímpar
      if (parteInteira % 2 == 0) {
        // Par: não modifica
        return parteInteira;
      } else {
        // Ímpar: incrementa
        return parteInteira + 1;
      }
    }
  }

  static Future<Uint8List> generateRelatorioDistribuicao({
    required RelatorioDistribuicao relatorio,
    required List<QuantidadeRefeicao> quantidadesRefeicao,
  }) async {
    // Carregar fonte com suporte Unicode
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    // Obter quantidades ativas para os cabeçalhos das colunas
    final quantidadesAtivas = quantidadesRefeicao
        .where((q) => q.ativo)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            _buildHeader(relatorio),
            pw.SizedBox(height: 20),
            _buildTabelaRegionais(relatorio, quantidadesAtivas),
            pw.SizedBox(height: 20),
            _buildTabelaTotal(relatorio, quantidadesAtivas),
            pw.SizedBox(height: 20),
            _buildLegenda(),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeader(RelatorioDistribuicao relatorio) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'GOVERNO DO DISTRITO FEDERAL\nSECRETARIA DE ESTADO DE EDUCAÇÃO',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'DISTRIBUIÇÃO DE GÊNEROS ALIMENTÍCIOS',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Memória de Cálculo: Quantidades suficientes para atendimento de 200 dias letivos, ${relatorio.modalidade.displayName.toUpperCase()}',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _buildTabelaRegionais(
    RelatorioDistribuicao relatorio,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    // Resetar contador global no início
    _contadorItemGlobal = 1;

    return pw.Column(
      children: relatorio.dadosRegionais.map((dadosRegiao) {
        final tabela = _buildTabelaProdutos(
          dadosRegiao.produtos,
          quantidadesAtivas,
          _contadorItemGlobal,
        );

        return pw.Column(
          children: [
            pw.Text(
              dadosRegiao.nomeRegiao,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              dadosRegiao.descricaoRegionais,
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
            pw.SizedBox(height: 10),
            tabela,
            pw.SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  static int _contadorItemGlobal =
      1; // Contador global para numeração sequencial

  static pw.Widget _buildTabelaProdutos(
    List<DadosRelatorioProduto> produtos,
    List<QuantidadeRefeicao> quantidadesAtivas,
    int contadorInicial,
  ) {
    final linhasProdutos = <pw.TableRow>[];

    // Adicionar produtos com numeração sequencial
    for (final produto in produtos) {
      linhasProdutos.add(
        _buildLinhaProduto(contadorInicial, produto, quantidadesAtivas),
      );
      contadorInicial++;
    }

    // Atualizar contador global
    _contadorItemGlobal = contadorInicial;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30), // Item
        1: const pw.FlexColumnWidth(3), // Gênero Alimentício
        2: const pw.FlexColumnWidth(2), // Número de Alunos
        3: const pw.FlexColumnWidth(1.5), // Per Capita
        4: const pw.FlexColumnWidth(1.5), // Frequência
        5: const pw.FlexColumnWidth(2), // Quantidade por modalidade
        6: const pw.FlexColumnWidth(1.5), // Total
      },
      children: [
        _buildCabecalhoTabela(quantidadesAtivas),
        ...linhasProdutos,
        _buildLinhaTotal(produtos, quantidadesAtivas),
      ],
    );
  }

  static pw.TableRow _buildCabecalhoTabela(
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'Item',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'Gênero Alimentício',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Número de Alunos (1)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Per Capita (2)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Frequência (3)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Quantidade por modalidade (4)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'Quantidade Total',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildLinhaProduto(
    int item,
    DadosRelatorioProduto produto,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('$item', style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            produto.produto.nome,
            style: pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final alunos = produto.alunosPorQuantidadeRefeicao[qtd.id] ?? 0;
              return pw.Expanded(
                child: pw.Text(
                  alunos.toString(),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final perCapita =
                  produto.perCapitaPorQuantidadeRefeicao[qtd.id] ?? 0.0;
              return pw.Expanded(
                child: pw.Text(
                  perCapita.toStringAsFixed(3),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final frequencia =
                  produto.frequenciaPorQuantidadeRefeicao[qtd.id] ?? 0;
              return pw.Expanded(
                child: pw.Text(
                  frequencia.toString(),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final quantidade = produto.quantidadePorModalidade[qtd.id] ?? 0.0;
              return pw.Expanded(
                child: pw.Text(
                  quantidade.toStringAsFixed(0),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            produto.totalQuantidade.toStringAsFixed(0),
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildLinhaTotal(
    List<DadosRelatorioProduto> produtos,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'Total por modalidade',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final totalAlunos = produtos.fold<int>(0, (sum, produto) {
                return sum + (produto.alunosPorQuantidadeRefeicao[qtd.id] ?? 0);
              });
              return pw.Expanded(
                child: pw.Text(
                  totalAlunos.toString(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              return pw.Expanded(
                child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              return pw.Expanded(
                child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final totalQuantidade = produtos.fold<double>(0, (sum, produto) {
                return sum + (produto.quantidadePorModalidade[qtd.id] ?? 0.0);
              });
              return pw.Expanded(
                child: pw.Text(
                  totalQuantidade.toStringAsFixed(0),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            produtos
                .fold<double>(
                  0,
                  (sum, produto) => sum + produto.totalQuantidade,
                )
                .toStringAsFixed(0),
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTabelaTotal(
    RelatorioDistribuicao relatorio,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          'QUANTIDADE TOTAL NO ${relatorio.modalidade.displayName.toUpperCase()} (REGIÕES 1,2,3 e 4)',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30), // Itens
            1: const pw.FlexColumnWidth(2), // Total de Número de Alunos
            2: const pw.FlexColumnWidth(1.5), // Per Capita
            3: const pw.FlexColumnWidth(1.5), // Frequência
            4: const pw.FlexColumnWidth(2), // Total Qtde. por modalidade
          },
          children: [
            _buildCabecalhoTabelaTotal(quantidadesAtivas),
            ...relatorio.totalGeral.produtos.asMap().entries.map((entry) {
              final index = entry.key;
              final produto = entry.value;
              return _buildLinhaProdutoTotal(
                index + 1,
                produto,
                quantidadesAtivas,
              );
            }),
            _buildLinhaTotalGeral(
              relatorio.totalGeral.produtos,
              quantidadesAtivas,
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildCabecalhoTabelaTotal(
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(
            'Itens',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Total de Número de Alunos (1)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Per Capita (II)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Frequência (II)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            children: [
              pw.Text(
                'Total Qtde. por modalidade (III)',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('1 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('2 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('3 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                  pw.Expanded(
                    child: pw.Text('4 REF', style: pw.TextStyle(fontSize: 7)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildLinhaProdutoTotal(
    int item,
    DadosRelatorioProduto produto,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('$item', style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final alunos = produto.alunosPorQuantidadeRefeicao[qtd.id] ?? 0;
              return pw.Expanded(
                child: pw.Text(
                  alunos.toString(),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final perCapita =
                  produto.perCapitaPorQuantidadeRefeicao[qtd.id] ?? 0.0;
              return pw.Expanded(
                child: pw.Text(
                  perCapita.toStringAsFixed(3),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final frequencia =
                  produto.frequenciaPorQuantidadeRefeicao[qtd.id] ?? 0;
              return pw.Expanded(
                child: pw.Text(
                  frequencia.toString(),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final quantidade = produto.quantidadePorModalidade[qtd.id] ?? 0.0;
              return pw.Expanded(
                child: pw.Text(
                  quantidade.toStringAsFixed(0),
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildLinhaTotalGeral(
    List<DadosRelatorioProduto> produtos,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final totalAlunos = produtos.fold<int>(0, (sum, produto) {
                return sum + (produto.alunosPorQuantidadeRefeicao[qtd.id] ?? 0);
              });
              return pw.Expanded(
                child: pw.Text(
                  totalAlunos.toString(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              return pw.Expanded(
                child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              return pw.Expanded(
                child: pw.Text('', style: pw.TextStyle(fontSize: 8)),
              );
            }).toList(),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Row(
            children: quantidadesAtivas.take(4).map((qtd) {
              final totalQuantidade = produtos.fold<double>(0, (sum, produto) {
                return sum + (produto.quantidadePorModalidade[qtd.id] ?? 0.0);
              });
              return pw.Expanded(
                child: pw.Text(
                  totalQuantidade.toStringAsFixed(0),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegenda() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'LEGENDA:',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'tabelas elaboradas em planilhas de Excel 2007.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          '(1) Quantitativo de alunos matriculados referente ao ano letivo de 2024',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          '(2) Per capita significa: quantidade de alimento cru, necessária por aluno.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          '(3) Frequência anual na qual determinado gênero alimentício estará no cardápio.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          '(4) Quantidades = (Número de alunos X Per Capita X Frequência)kg.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Nota (1): A GECNE/DGOF não emite Notas de Empenhos com quantitativos que tenham casas decimais, portanto todas as formulas contem regras de arredondamento.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Nota (2): Regra de arredondamento:',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Se os algarismos decimais seguintes forem menor que 5, o anterior não se modifica.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Se os algarismos decimais seguintes forem maior que 5, o anterior incrementa-se em uma unidade.',
          style: pw.TextStyle(fontSize: 10),
        ),
        pw.Text(
          'Se os algarismos decimais seguintes forem igual a 5, deve-se verificar o anterior, se ele for par não se modifica, se ele for impar incrementa-se uma unidade.',
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  // ========== GERAÇÃO DE PDF PARA MEMÓRIA DE CÁLCULO ==========

  static Future<Uint8List> generateRelatorioMemoriaCalculo({
    required String anoLetivo,
    required int numeroMemoria,
    required String titulo,
    required String modalidade,
    required List<String> regioesSelecionadas,
    required Map<String, String> regioesNomes,
    required Map<String, List<String>> regionaisPorRegiao,
    required Map<String, Map<String, int>> alunosPorRegiaoModalidade,
    required Map<String, double> frequencias,
    required Map<String, Map<String, double>> frequenciasPorProduto,
    required List<QuantidadeRefeicao> quantidadesRefeicao,
    required List<Produto> produtosSelecionados,
  }) async {
    // Carregar fonte com suporte Unicode
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    // Resetar contador para cada PDF
    _contadorItemGlobal = 0;

    // Obter quantidades ativas
    final quantidadesAtivas = quantidadesRefeicao
        .where((q) => q.ativo)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            _buildHeaderMemoriaCalculo(
              anoLetivo,
              numeroMemoria,
              titulo,
              modalidade,
            ),
            pw.SizedBox(height: 20),
            // Tabelas por região
            ...regioesSelecionadas.map((regiaoId) {
              return pw.Column(
                children: [
                  _buildTabelaRegiao(
                    regiaoId,
                    regioesNomes[regiaoId] ?? regiaoId,
                    regionaisPorRegiao[regiaoId] ?? [],
                    alunosPorRegiaoModalidade[regiaoId] ?? {},
                    frequencias,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    produtosSelecionados,
                    modalidade,
                  ),
                  pw.SizedBox(height: 15),
                ],
              );
            }),
            // Tabela de total geral (soma de todas as regiões)
            _buildTabelaTotalRegioes(
              regioesSelecionadas,
              regioesNomes,
              modalidade,
              alunosPorRegiaoModalidade,
              frequencias,
              frequenciasPorProduto,
              quantidadesAtivas,
              produtosSelecionados,
            ),
            pw.SizedBox(height: 20),
            _buildLegendaMemoriaCalculo(anoLetivo: anoLetivo),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static Future<Uint8List> generateConsolidadoMemoriaCalculo({
    required String anoLetivo,
    required int numeroMemoria,
    required String titulo,
    required String modalidade,
    required List<String> regioesSelecionadas,
    required Map<String, String> regioesNomes,
    required Map<String, Map<String, int>> alunosPorRegiaoModalidade,
    required Map<String, double> frequencias,
    required Map<String, Map<String, double>> frequenciasPorProduto,
    required List<QuantidadeRefeicao> quantidadesRefeicao,
    required List<Produto> produtosSelecionados,
  }) async {
    // Carregar fonte com suporte Unicode
    final fontData = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    final font = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    // Obter quantidades ativas
    final quantidadesAtivas = quantidadesRefeicao
        .where((q) => q.ativo)
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a3.landscape,
        margin: const pw.EdgeInsets.all(10),
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) {
          return [
            _buildHeaderConsolidado(
              anoLetivo,
              numeroMemoria,
              titulo,
              modalidade,
            ),
            pw.SizedBox(height: 10),
            _buildTabelaTotalMemoria(
              regioesSelecionadas,
              regioesNomes,
              alunosPorRegiaoModalidade,
              frequencias,
              quantidadesAtivas,
              produtosSelecionados,
            ),
            pw.SizedBox(height: 10),
            _buildLegendaMemoriaCalculo(anoLetivo: anoLetivo),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildHeaderMemoriaCalculo(
    String anoLetivo,
    int numeroMemoria,
    String titulo,
    String modalidade,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'SECRETARIA DE ESTADO DE EDUCAÇÃO DO DISTRITO FEDERAL',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'SUBSECRETARIA DE ADMINISTRAÇÃO GERAL',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'DIRETORIA DE ALIMENTAÇÃO ESCOLAR',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
          child: pw.Column(
            children: [
              pw.Text(
                '$titulo - Memória de Cálculo Gêneros Alimentícios',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildHeaderConsolidado(
    String anoLetivo,
    int numeroMemoria,
    String titulo,
    String modalidade,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'SECRETARIA DE ESTADO DE EDUCAÇÃO DO DISTRITO FEDERAL',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'SUBSECRETARIA DE ADMINISTRAÇÃO GERAL',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'DIRETORIA DE ALIMENTAÇÃO ESCOLAR',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
          child: pw.Column(
            children: [
              pw.Text(
                '$titulo - Consolidado 1',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _cellHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7),
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    pw.FontWeight? fontWeight,
    PdfColor? background,
    bool groupEndBorder = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(2),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : align == pw.TextAlign.right
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      decoration: pw.BoxDecoration(
        color: background,
        border: groupEndBorder
            ? pw.Border(
                right: pw.BorderSide(width: 1.2, color: PdfColors.black),
              )
            : null,
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6, fontWeight: fontWeight),
      ),
    );
  }

  static pw.Widget _buildTabelaRegiao(
    String regiaoId,
    String regiaoNome,
    List<String> regionaisNomes,
    Map<String, int> alunosPorQuantidade,
    Map<String, double> frequencias,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    List<Produto> produtosSelecionados,
    String modalidade,
  ) {
    final numQtds = quantidadesAtivas.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            color: PdfColors.grey200,
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'REGIÃO $regiaoId - $regiaoNome',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              if (regionaisNomes.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  'Coordenações Regionais de Ensino (CREs): ${regionaisNomes.join(', ')}',
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.7), // Item
            1: const pw.FlexColumnWidth(4), // Gênero Alimentício
            2: pw.FlexColumnWidth(numQtds * 0.6), // Número de Alunos
            3: pw.FlexColumnWidth(numQtds * 0.6), // Per Capita
            4: pw.FlexColumnWidth(numQtds * 0.6), // Frequência
            5: pw.FlexColumnWidth(numQtds * 0.8), // Quantidade por modalidade
            6: const pw.FlexColumnWidth(1), // Quantidade Total
          },
          children: [
            // Cabeçalho principal
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _cellHeader('Item'),
                _cellHeader('Gênero Alimentício'),
                _cellHeader('Número de Alunos (1)'),
                _cellHeader('Per Capita (2)'),
                _cellHeader('Frequência (3)'),
                _cellHeader('Quantidade por modalidade (4)'),
                _cellHeader('Quantidade Total'),
              ],
            ),
            // Sub-cabeçalhos
            pw.TableRow(
              children: [
                _cell(''),
                _cell(''),
                _buildSubCabecalho(quantidadesAtivas),
                _buildSubCabecalho(quantidadesAtivas),
                _buildSubCabecalho(quantidadesAtivas),
                _buildSubCabecalho(quantidadesAtivas),
                _cell(''),
              ],
            ),
            // Linhas dos produtos
            ...produtosSelecionados.map((produto) {
              _contadorItemGlobal++; // Incrementar contador global

              return pw.TableRow(
                children: [
                  _cell(
                    _contadorItemGlobal.toString(),
                    align: pw.TextAlign.center,
                  ),
                  _cell(produto.nome),
                  _buildColunaValores(alunosPorQuantidade, quantidadesAtivas),
                  _buildColunaPerCapita(produto, quantidadesAtivas),
                  _buildColunaFrequenciaPorProduto(
                    produto,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    modalidade,
                  ),
                  _buildColunaQuantidadesPorProduto(
                    alunosPorQuantidade,
                    produto,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    modalidade,
                  ),
                  _buildTotalLinhaPorProduto(
                    alunosPorQuantidade,
                    produto,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    modalidade,
                  ),
                ],
              );
            }),
            // Linha de total
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _cell(''),
                _cell('Total por modalidade', fontWeight: pw.FontWeight.bold),
                _cell(''),
                _cell(''),
                _cell(''),
                _buildColunaTotais(
                  alunosPorQuantidade,
                  produtosSelecionados,
                  frequenciasPorProduto,
                  quantidadesAtivas,
                  modalidade,
                ),
                _buildGrandeTotal(
                  alunosPorQuantidade,
                  produtosSelecionados,
                  frequenciasPorProduto,
                  quantidadesAtivas,
                  modalidade,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSubCabecalho(
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: quantidadesAtivas
          .map(
            (qtd) => pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(2),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  qtd.sigla,
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildColunaValores(
    Map<String, int> valores,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.Row(
      children: quantidadesAtivas
          .map(
            (qtd) => pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(2),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  (valores[qtd.id] ?? 0).toString(),
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _buildColunaPerCapita(
    Produto produto,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.Row(
      children: quantidadesAtivas
          .map(
            (qtd) => pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(2),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  produto
                      .getPerCapitaForDomain(
                        'gpae',
                        ModalidadeEnsino.preEscola,
                        qtd.id,
                      )
                      .toStringAsFixed(3),
                  style: const pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static String _getModalidadeEnumName(String modalidadeDisplayName) {
    // Converter display name para enum name
    for (final mod in ModalidadeEnsino.values) {
      if (mod.displayName == modalidadeDisplayName) {
        return mod.name;
      }
    }
    // Fallback para fundamental1 se não encontrar
    return ModalidadeEnsino.fundamental1.name;
  }

  static ModalidadeEnsino _getModalidadeEnum(String modalidadeDisplayName) {
    // Converter display name para enum
    for (final mod in ModalidadeEnsino.values) {
      if (mod.displayName == modalidadeDisplayName) {
        return mod;
      }
    }
    // Fallback para fundamental1 se não encontrar
    return ModalidadeEnsino.fundamental1;
  }

  static pw.Widget _buildColunaFrequenciaPorProduto(
    Produto produto,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    String modalidadeDisplayName,
  ) {
    final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
    final modalidadeEnumName = _getModalidadeEnumName(modalidadeDisplayName);

    return pw.Row(
      children: quantidadesAtivas.map((qtd) {
        // Construir a chave no formato 'modalidadeEnumName_qtdId'
        final chave = '${modalidadeEnumName}_${qtd.id}';
        final frequencia = frequenciasProduto[chave] ?? 0;

        return pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              frequencia.toInt().toString(),
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildColunaQuantidadesPorProduto(
    Map<String, int> alunos,
    Produto produto,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    String modalidadeDisplayName,
  ) {
    final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
    final modalidadeEnumName = _getModalidadeEnumName(modalidadeDisplayName);
    final modalidadeEnum = _getModalidadeEnum(modalidadeDisplayName);

    return pw.Row(
      children: quantidadesAtivas.map((qtd) {
        final numAlunos = alunos[qtd.id] ?? 0;
        final perCapita = produto.getPerCapitaForDomain(
          'gpae',
          modalidadeEnum,
          qtd.id,
        );
        // Construir a chave no formato 'modalidadeEnumName_qtdId'
        final chave = '${modalidadeEnumName}_${qtd.id}';
        final freq = frequenciasProduto[chave] ?? 0;
        final quantidadeCalculada = numAlunos * perCapita * freq;
        final quantidade = arredondamentoBancario(quantidadeCalculada);

        return pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              quantidade.toString(),
              style: const pw.TextStyle(fontSize: 7),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTotalLinhaPorProduto(
    Map<String, int> alunos,
    Produto produto,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    String modalidadeDisplayName,
  ) {
    final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
    final modalidadeEnumName = _getModalidadeEnumName(modalidadeDisplayName);
    final modalidadeEnum = _getModalidadeEnum(modalidadeDisplayName);
    int total = 0;
    for (final qtd in quantidadesAtivas) {
      final numAlunos = alunos[qtd.id] ?? 0;
      final perCapita = produto.getPerCapitaForDomain(
        'gpae',
        modalidadeEnum,
        qtd.id,
      );
      // Construir a chave no formato 'modalidadeEnumName_qtdId'
      final chave = '${modalidadeEnumName}_${qtd.id}';
      final freq = frequenciasProduto[chave] ?? 0;
      final quantidadeCalculada = numAlunos * perCapita * freq;
      total += arredondamentoBancario(quantidadeCalculada);
    }
    return _cell(total.toString(), align: pw.TextAlign.center);
  }

  static pw.Widget _buildColunaTotais(
    Map<String, int> alunos,
    List<Produto> produtos,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    String modalidadeDisplayName,
  ) {
    final modalidadeEnumName = _getModalidadeEnumName(modalidadeDisplayName);
    final modalidadeEnum = _getModalidadeEnum(modalidadeDisplayName);

    return pw.Row(
      children: quantidadesAtivas.map((qtd) {
        int total = 0;
        for (final produto in produtos) {
          final numAlunos = alunos[qtd.id] ?? 0;
          final perCapita = produto.getPerCapitaForDomain(
            'gpae',
            modalidadeEnum,
            qtd.id,
          );
          // Construir a chave no formato 'modalidadeEnumName_qtdId'
          final chave = '${modalidadeEnumName}_${qtd.id}';
          final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
          final freq = frequenciasProduto[chave] ?? 0;
          final quantidadeCalculada = numAlunos * perCapita * freq;
          total += arredondamentoBancario(quantidadeCalculada);
        }

        return pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              total.toString(),
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildGrandeTotal(
    Map<String, int> alunos,
    List<Produto> produtos,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    String modalidadeDisplayName,
  ) {
    final modalidadeEnumName = _getModalidadeEnumName(modalidadeDisplayName);
    final modalidadeEnum = _getModalidadeEnum(modalidadeDisplayName);

    int grandeTotal = 0;
    for (final produto in produtos) {
      for (final qtd in quantidadesAtivas) {
        final numAlunos = alunos[qtd.id] ?? 0;
        final perCapita = produto.getPerCapitaForDomain(
          'gpae',
          modalidadeEnum,
          qtd.id,
        );
        // Construir a chave no formato 'modalidadeEnumName_qtdId'
        final chave = '${modalidadeEnumName}_${qtd.id}';
        final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
        final freq = frequenciasProduto[chave] ?? 0;
        final quantidadeCalculada = numAlunos * perCapita * freq;
        grandeTotal += arredondamentoBancario(quantidadeCalculada);
      }
    }
    return _cell(
      grandeTotal.toString(),
      align: pw.TextAlign.center,
      fontWeight: pw.FontWeight.bold,
    );
  }

  static pw.Widget _buildTabelaTotalMemoria(
    List<String> regioesSelecionadas,
    Map<String, String> regioesNomes,
    Map<String, Map<String, int>> alunosPorRegiaoModalidade,
    Map<String, double> frequencias,
    List<QuantidadeRefeicao> quantidadesAtivas,
    List<Produto> produtosSelecionados,
  ) {
    final numRefs = quantidadesAtivas.length;
    final Map<int, pw.TableColumnWidth> columnWidths = {
      0: const pw.FixedColumnWidth(40), // Itens
      1: const pw.FlexColumnWidth(3), // Gênero Alimentício
    };
    int columnIndex = 2;
    for (int i = 0; i < 6; i++) {
      // For each modality
      // REFs
      for (int j = 0; j < numRefs; j++) {
        columnWidths[columnIndex++] = const pw.FixedColumnWidth(35);
      }
      // Lanches
      columnWidths[columnIndex++] = const pw.FixedColumnWidth(30);
      columnWidths[columnIndex++] = const pw.FixedColumnWidth(30);
      columnWidths[columnIndex++] = const pw.FixedColumnWidth(30);
      // Total Modalidade
      columnWidths[columnIndex++] = const pw.FixedColumnWidth(40);
    }
    columnWidths[columnIndex] = const pw.FixedColumnWidth(50); // TOTAL GLOBAL

    // Calcular totais por Tipo de refeição
    final Map<String, int> totaisAlunos = {};
    for (final qtd in quantidadesAtivas) {
      int total = 0;
      for (final regiao in alunosPorRegiaoModalidade.values) {
        total += regiao[qtd.id] ?? 0;
      }
      totaisAlunos[qtd.id] = total;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            color: PdfColors.grey200,
          ),
          child: pw.Text(
            'MEMÓRIA DE CÁLCULO CONSOLIDADA (REGIÕES ${regioesSelecionadas.join(', ')}) QUANTIDADE GLOBAL',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
          columnWidths: columnWidths,
          children: [
            _buildCabecalhoConsolidadoTop(quantidadesAtivas),
            _buildCabecalhoConsolidado(quantidadesAtivas),
            ...produtosSelecionados.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final produto = entry.value;
              // Exibir os itens correspondentes em cada região (ex.: 1, 3, 5, 7)
              final numProdutos = produtosSelecionados.length;
              final itensTexto = List.generate(
                regioesSelecionadas.length,
                (k) => index + k * numProdutos,
              ).join(', ');
              return pw.TableRow(
                children: [
                  _cell(itensTexto, align: pw.TextAlign.center),
                  _cellGenero(produto),
                  // Dados para cada modalidade (6 modalidades)
                  ...List.generate(6, (modalidadeIndex) {
                    final modalidade = [
                      'PRÉ ESCOLA',
                      'FUNDAMENTAL',
                      'ESPECIAL',
                      'CRECHE',
                      'MÉDIO',
                      'E.J.A.',
                    ][modalidadeIndex];
                    return [
                      // REFs (1 REF, 2 REF, 3 REF, 4 REF)
                      ...quantidadesAtivas.map(
                        (qtd) => _cell(
                          _calcularQuantidadeConsolidada(
                            produto,
                            qtd,
                            modalidade,
                            frequencias,
                            totaisAlunos,
                          ).toString(),
                          align: pw.TextAlign.center,
                        ),
                      ),
                      // Lanche Fácil, Lanche, Jantar
                      _cell('', align: pw.TextAlign.center), // Lanche Fácil
                      _cell('', align: pw.TextAlign.center), // Lanche
                      _cell('', align: pw.TextAlign.center), // Jantar
                      // Total da modalidade (destacado)
                      _cell(
                        _calcularTotalModalidade(
                          produto,
                          modalidade,
                          frequencias,
                          totaisAlunos,
                          quantidadesAtivas,
                        ).toString(),
                        align: pw.TextAlign.center,
                        fontWeight: pw.FontWeight.bold,
                        background: PdfColors.grey200,
                        groupEndBorder: true,
                      ),
                    ];
                  }).expand((x) => x),
                  // TOTAL GLOBAL
                  _cell(
                    _calcularTotalGlobal(
                      produto,
                      frequencias,
                      totaisAlunos,
                    ).toString(),
                    align: pw.TextAlign.center,
                    fontWeight: pw.FontWeight.bold,
                    background: PdfColors.grey300,
                  ),
                ],
              );
            }),
            // Linhas de total por modalidade
            ...List.generate(6, (modalidadeIndex) {
              final modalidade = [
                'PRÉ ESCOLA',
                'FUNDAMENTAL',
                'ESPECIAL',
                'CRECHE',
                'MÉDIO',
                'E.J.A.',
              ][modalidadeIndex];

              return pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  _cell(''),
                  _cell('TOTAL $modalidade', fontWeight: pw.FontWeight.bold),
                  // Dados para cada modalidade (6 modalidades)
                  ...List.generate(6, (i) {
                    if (i == modalidadeIndex) {
                      // Para a modalidade atual, mostrar os totais
                      return [
                        // REFs
                        ...quantidadesAtivas.map(
                          (qtd) => _cell(
                            _calcularTotalConsolidadoREF(
                              qtd,
                              modalidade,
                              produtosSelecionados,
                              frequencias,
                              totaisAlunos,
                            ).toString(),
                            align: pw.TextAlign.center,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        // Lanche Fácil, Lanche, Jantar (vazios por enquanto)
                        _cell('', align: pw.TextAlign.center),
                        _cell('', align: pw.TextAlign.center),
                        _cell('', align: pw.TextAlign.center),
                        // Total da modalidade (destacado)
                        _cell(
                          _calcularTotalConsolidadoModalidade(
                            modalidade,
                            produtosSelecionados,
                            frequencias,
                            totaisAlunos,
                            quantidadesAtivas,
                          ).toString(),
                          align: pw.TextAlign.center,
                          fontWeight: pw.FontWeight.bold,
                          background: PdfColors.grey200,
                          groupEndBorder: true,
                        ),
                      ];
                    } else {
                      // Para outras modalidades, células vazias
                      return List.generate(
                        quantidadesAtivas.length +
                            4, // REFs + 3 lanches + Total
                        (j) => _cell('', align: pw.TextAlign.center),
                      );
                    }
                  }).expand((x) => x),
                  // TOTAL GLOBAL (vazio para linhas de modalidade)
                  _cell('', align: pw.TextAlign.center),
                ],
              );
            }),
            // Linha de total global final
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _cell(''),
                _cell('TOTAL GLOBAL', fontWeight: pw.FontWeight.bold),
                // Totais para cada modalidade
                ...List.generate(6, (modalidadeIndex) {
                  final modalidade = [
                    'PRÉ ESCOLA',
                    'FUNDAMENTAL',
                    'ESPECIAL',
                    'CRECHE',
                    'MÉDIO',
                    'E.J.A.',
                  ][modalidadeIndex];
                  return [
                    // REFs
                    ...quantidadesAtivas.map(
                      (qtd) => _cell(
                        _calcularTotalConsolidadoREF(
                          qtd,
                          modalidade,
                          produtosSelecionados,
                          frequencias,
                          totaisAlunos,
                        ).toString(),
                        align: pw.TextAlign.center,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    // Lanche Fácil, Lanche, Jantar (vazios por enquanto)
                    _cell('', align: pw.TextAlign.center),
                    _cell('', align: pw.TextAlign.center),
                    _cell('', align: pw.TextAlign.center),
                    // Total da modalidade (destacado)
                    _cell(
                      _calcularTotalConsolidadoModalidade(
                        modalidade,
                        produtosSelecionados,
                        frequencias,
                        totaisAlunos,
                        quantidadesAtivas,
                      ).toString(),
                      align: pw.TextAlign.center,
                      fontWeight: pw.FontWeight.bold,
                      background: PdfColors.grey200,
                      groupEndBorder: true,
                    ),
                  ];
                }).expand((x) => x),
                // TOTAL GLOBAL FINAL
                _cell(
                  _calcularTotalConsolidadoFinal(
                    produtosSelecionados,
                    frequencias,
                    totaisAlunos,
                  ).toString(),
                  align: pw.TextAlign.center,
                  fontWeight: pw.FontWeight.bold,
                  background: PdfColors.grey300,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.TableRow _buildCabecalhoConsolidado(
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _cellHeader('Itens'),
        _cellHeader('Gênero Alimentício'),
        // Cabeçalhos para cada modalidade (6 modalidades)
        ...List.generate(6, (modalidadeIndex) {
          return [
            // REFs (1 REF, 2 REF, 3 REF, 4 REF)
            ...quantidadesAtivas.map((qtd) => _cellHeader(qtd.sigla)),
            // Lanche Fácil, Lanche, Jantar
            _cellHeader('L. Fácil'),
            _cellHeader('Lanche'),
            _cellHeader('Jantar'),
            // Total da modalidade
            pw.Container(
              padding: const pw.EdgeInsets.all(5),
              alignment: pw.Alignment.center,
              color: PdfColors.grey200,
              child: pw.Text(
                'Total',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
          ];
        }).expand((x) => x),
        // TOTAL GLOBAL
        pw.Container(
          padding: const pw.EdgeInsets.all(5),
          alignment: pw.Alignment.center,
          color: PdfColors.grey300,
          child: pw.Text(
            'TOTAL\nGLOBAL',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
      ],
    );
  }

  static pw.TableRow _buildCabecalhoConsolidadoTop(
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    final int colsPorModalidade =
        quantidadesAtivas.length + 4; // REFs + 3 lanches + Total
    // Monta uma linha superior apenas com os títulos de grupos; as duas primeiras colunas ficam vazias
    final List<pw.Widget> cells = [
      _cellHeader(''), // Item (vazio na linha superior)
      _cellHeader(''), // Gênero (vazio na linha superior)
    ];

    for (int modalidadeIndex = 0; modalidadeIndex < 6; modalidadeIndex++) {
      final titulo = [
        'PRÉ-ESCOLA',
        'FUNDAMENTAL',
        'ESPECIAL',
        'CRECHE',
        'MÉDIO',
        'E.J.A.',
      ][modalidadeIndex];
      // Título do grupo
      cells.add(_cellHeader(titulo));
      // Completar as demais colunas do grupo com células vazias para alinhar
      for (int i = 1; i < colsPorModalidade; i++) {
        cells.add(_cellHeader(''));
      }
    }

    // TOTAL GLOBAL no final
    cells.add(_cellHeader(''));

    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: cells,
    );
  }

  static int _calcularQuantidadeConsolidada(
    Produto produto,
    QuantidadeRefeicao qtd,
    String modalidade,
    Map<String, double> frequencias,
    Map<String, int> totaisAlunos,
  ) {
    // Mapear modalidade string para enum
    ModalidadeEnsino modalidadeEnum;
    switch (modalidade) {
      case 'PRÉ ESCOLA':
        modalidadeEnum = ModalidadeEnsino.preEscola;
        break;
      case 'FUNDAMENTAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'ESPECIAL':
        modalidadeEnum =
            ModalidadeEnsino.fundamental1; // Fallback para especial
        break;
      case 'CRECHE':
        modalidadeEnum = ModalidadeEnsino.preEscola; // Fallback para creche
        break;
      case 'MÉDIO':
        modalidadeEnum = ModalidadeEnsino.ensinoMedio;
        break;
      case 'E.J.A.':
        modalidadeEnum = ModalidadeEnsino.eja;
        break;
      default:
        modalidadeEnum = ModalidadeEnsino.fundamental1;
    }

    final alunos = totaisAlunos[qtd.id] ?? 0;
    final perCapita = produto.getPerCapitaForDomain(
      'gpae',
      modalidadeEnum,
      qtd.id,
    );
    final frequencia = frequencias[qtd.id] ?? 0;
    final quantidadeCalculada = alunos * perCapita * frequencia;
    return arredondamentoBancario(quantidadeCalculada);
  }

  static int _calcularTotalModalidade(
    Produto produto,
    String modalidade,
    Map<String, double> frequencias,
    Map<String, int> totaisAlunos,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;
    for (final qtd in frequencias.keys) {
      // Buscar a QuantidadeRefeicao real da lista
      final qtdRef = quantidadesAtivas.firstWhere(
        (q) => q.id == qtd,
        orElse: () => QuantidadeRefeicao(
          id: qtd,
          nome: qtd,
          sigla: qtd,
          descricao: qtd,
          ativo: true,
        ),
      );

      total += _calcularQuantidadeConsolidada(
        produto,
        qtdRef,
        modalidade,
        frequencias,
        totaisAlunos,
      );
    }
    return total;
  }

  static int _calcularTotalGlobal(
    Produto produto,
    Map<String, double> frequencias,
    Map<String, int> totaisAlunos,
  ) {
    // Calcular total global baseado nas quantidades de alunos e per capita
    double total = 0;
    for (final qtd in frequencias.keys) {
      final alunos = totaisAlunos[qtd] ?? 0;
      final perCapita = produto.getPerCapitaForDomain(
        'gpae',
        ModalidadeEnsino.fundamental1,
        qtd,
      );
      final frequencia = frequencias[qtd] ?? 0;
      total += alunos * perCapita * frequencia;
    }
    return arredondamentoBancario(total);
  }

  static int _calcularTotalConsolidadoREF(
    QuantidadeRefeicao qtd,
    String modalidade,
    List<Produto> produtosSelecionados,
    Map<String, double> frequencias,
    Map<String, int> totaisAlunos,
  ) {
    int total = 0;
    for (final produto in produtosSelecionados) {
      total += _calcularQuantidadeConsolidada(
        produto,
        qtd,
        modalidade,
        frequencias,
        totaisAlunos,
      );
    }
    return total;
  }

  static int _calcularTotalConsolidadoModalidade(
    String modalidade,
    List<Produto> produtosSelecionados,
    Map<String, double> frequencias,
    Map<String, int> totaisAlunos,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;
    for (final produto in produtosSelecionados) {
      total += _calcularTotalModalidade(
        produto,
        modalidade,
        frequencias,
        totaisAlunos,
        quantidadesAtivas,
      );
    }
    return total;
  }

  static int _calcularTotalConsolidadoFinal(
    List<Produto> produtosSelecionados,
    Map<String, double> frequencias,
    Map<String, int> totaisAlunos,
  ) {
    // Calcular total final somando todos os produtos
    int total = 0;
    for (final produto in produtosSelecionados) {
      total += _calcularTotalGlobal(produto, frequencias, totaisAlunos);
    }
    return total;
  }

  static pw.Widget _buildTabelaTotalRegioes(
    List<String> regioesSelecionadas,
    Map<String, String> regioesNomes,
    String modalidade,
    Map<String, Map<String, int>> alunosPorRegiaoModalidade,
    Map<String, double> frequencias,
    Map<String, Map<String, double>> frequenciasPorProduto,
    List<QuantidadeRefeicao> quantidadesAtivas,
    List<Produto> produtosSelecionados,
  ) {
    // Calcular totais somando todas as regiões
    final Map<String, int> alunosTotais = {};
    for (final qtd in quantidadesAtivas) {
      int total = 0;
      for (final regiaoId in regioesSelecionadas) {
        final alunosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
        total += alunosRegiao[qtd.id] ?? 0;
      }
      alunosTotais[qtd.id] = total;
    }

    final numQtds = quantidadesAtivas.length;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(),
            color: PdfColors.grey200,
          ),
          child: pw.Text(
            'QUANTITATIVO TOTAL NA ${modalidade.toUpperCase()} (REGIÕES ${regioesSelecionadas.join(', ')})',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.7), // Item
            1: const pw.FlexColumnWidth(4), // Gênero Alimentício
            2: pw.FlexColumnWidth(numQtds * 0.6), // Número de Alunos
            3: pw.FlexColumnWidth(numQtds * 0.6), // Per Capita
            4: pw.FlexColumnWidth(numQtds * 0.6), // Frequência
            5: pw.FlexColumnWidth(numQtds * 0.8), // Quantidade por modalidade
            6: const pw.FlexColumnWidth(1), // Quantidade Total
          },
          children: [
            // Cabeçalho principal
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _cellHeader('Item'),
                _cellHeader('Gênero Alimentício'),
                _cellHeader('Número de Alunos (1)'),
                _cellHeader('Per Capita (2)'),
                _cellHeader('Frequência (3)'),
                _cellHeader('Quantidade por modalidade (4)'),
                _cellHeader('Quantidade Total'),
              ],
            ),
            // Sub-cabeçalhos
            pw.TableRow(
              children: [
                _cell(''),
                _cell(''),
                _buildSubCabecalho(quantidadesAtivas),
                _buildSubCabecalho(quantidadesAtivas),
                _buildSubCabecalho(quantidadesAtivas),
                _buildSubCabecalho(quantidadesAtivas),
                _cell(''),
              ],
            ),
            // Linhas dos produtos
            ...produtosSelecionados.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final produto = entry.value;

              return pw.TableRow(
                children: [
                  _cell(index.toString(), align: pw.TextAlign.center),
                  _cell(produto.nome),
                  _buildColunaValores(alunosTotais, quantidadesAtivas),
                  _buildColunaPerCapita(produto, quantidadesAtivas),
                  _buildColunaFrequenciaPorProduto(
                    produto,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    modalidade,
                  ),
                  _buildColunaQuantidadesPorProduto(
                    alunosTotais,
                    produto,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    modalidade,
                  ),
                  _buildTotalLinhaPorProduto(
                    alunosTotais,
                    produto,
                    frequenciasPorProduto,
                    quantidadesAtivas,
                    modalidade,
                  ),
                ],
              );
            }),
            // Linha de total
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _cell(''),
                _cell('Total por modalidade', fontWeight: pw.FontWeight.bold),
                _cell(''),
                _cell(''),
                _cell(''),
                _buildColunaTotais(
                  alunosTotais,
                  produtosSelecionados,
                  frequenciasPorProduto,
                  quantidadesAtivas,
                  modalidade,
                ),
                _buildGrandeTotal(
                  alunosTotais,
                  produtosSelecionados,
                  frequenciasPorProduto,
                  quantidadesAtivas,
                  modalidade,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLegendaMemoriaCalculo({String anoLetivo = '2024'}) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LEGENDA:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '(1) Quantitativo de alunos matriculados referente ao ano letivo de $anoLetivo.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '(2) Per capita significa: quantidade de alimento cru, necessária por aluno.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '(3) Frequência anual na qual determinado gênero alimentício estará no cardápio.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            '(4) Quantidades = (Número de alunos X Per Capita X Frequência)kg.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Nota (1): A GECNE/DGOF não emite Notas de Empenhos com quantitativos que tenham casas decimais, portanto todas as fórmulas contem regras de arredondamento.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Nota (2): Regra de arredondamento:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'Se os algarismos decimais seguintes forem menor que 5, o anterior não se modifica.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Se os algarismos decimais seguintes forem maior que 5, o anterior incrementa-se em uma unidade.',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            'Se os algarismos decimais seguintes forem igual a 5, deve-se verificar o anterior, se ele for par não se modifica, se ele for impar incrementa-se uma unidade.',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cellGenero(Produto produto) {
    final secundario = [
      if ((produto.marca ?? '').isNotEmpty) 'Marca: ${produto.marca}',
      if ((produto.fabricante ?? '').isNotEmpty) 'Fab.: ${produto.fabricante}',
    ].join('  ');

    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(produto.nome, style: pw.TextStyle(fontSize: 8)),
          if (secundario.isNotEmpty)
            pw.Text(
              secundario,
              style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
        ],
      ),
    );
  }
}
