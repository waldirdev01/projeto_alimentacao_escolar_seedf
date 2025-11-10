import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/escola.dart';
import '../models/produto.dart';
import '../models/quantidade_refeicao.dart';

class ExcelGenerator {
  static Future<Uint8List> generateConsolidadoMemoriaCalculo({
    required String anoLetivo,
    required int numeroMemoria,
    required String titulo,
    required List<String> regioesSelecionadas,
    required Map<String, String> regioesNomes,
    required Map<String, Map<String, Map<String, int>>>
    alunosPorRegiaoModalidade,
    required Map<String, double> frequencias,
    required Map<String, Map<String, double>> frequenciasPorProduto,
    required List<QuantidadeRefeicao> quantidadesRefeicao,
    required List<Produto> produtosSelecionados,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Consolidado 1'];

    // Remover sheet padrão se existir
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final quantidadesAtivas = quantidadesRefeicao
        .where((q) => q.ativo)
        .toList();

    // Calcular totais por Tipo de refeição
    final Map<String, int> totaisAlunos = {};
    for (final qtd in quantidadesAtivas) {
      int total = 0;
      for (final regiao in alunosPorRegiaoModalidade.values) {
        for (final modalidade in regiao.values) {
          total += modalidade[qtd.id] ?? 0;
        }
      }
      totaisAlunos[qtd.id] = total;
    }

    int rowIndex = 0;

    // Cabeçalho - Título do documento
    _mergeCells(sheet, 0, 0, 0, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue(
        'SECRETARIA DE ESTADO DE EDUCAÇÃO DO DISTRITO FEDERAL',
      )
      ..cellStyle = _headerStyle();
    rowIndex++;

    _mergeCells(sheet, 1, 0, 1, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue('SUBSECRETARIA DE ADMINISTRAÇÃO GERAL')
      ..cellStyle = _headerStyle();
    rowIndex++;

    _mergeCells(sheet, 2, 0, 2, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue('DIRETORIA DE ALIMENTAÇÃO ESCOLAR')
      ..cellStyle = _headerStyle();
    rowIndex++;

    rowIndex++; // Linha em branco

    // Título principal idêntico à planilha detalhada
    _mergeCells(sheet, rowIndex, 0, rowIndex, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue(
        'Memória de Cálculo por Modalidade: Quantidades suficientes para atendimento de 200 dias letivos',
      )
      ..cellStyle = _titleStyle();
    rowIndex++;

    // Linha de escopo/níveis atendidos
    _mergeCells(sheet, rowIndex, 0, rowIndex, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue(
        'DISTRIBUIÇÃO DE GÊNEROS ALIMENTÍCIOS – Educação Infantil, Ensino Fundamental, Especial, Creche e Médio',
      )
      ..cellStyle = _subtitleStyle();
    rowIndex++;

    _mergeCells(sheet, rowIndex, 0, rowIndex, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue(
        'MEMÓRIA DE CÁLCULO CONSOLIDADA (REGIÕES ${regioesSelecionadas.join(', ')}) QUANTIDADE GLOBAL',
      )
      ..cellStyle = _subtitleStyle();
    rowIndex++;

    // Cabeçalho da tabela - Linha 1 (modalidades)
    int colIndex = 0;
    final modalidades = [
      'PRÉ-ESCOLA',
      'FUNDAMENTAL',
      'ESPECIAL',
      'CRECHE',
      'MÉDIO',
      'E.J.A.',
    ];

    // Mesclar verticalmente "Itens" e "Gênero Alimentício" (duas linhas de cabeçalho)
    _mergeCells(sheet, rowIndex, 0, rowIndex + 1, 0);
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex),
      )
      ..value = TextCellValue('Itens')
      ..cellStyle = _columnHeaderStyle();

    _mergeCells(sheet, rowIndex, 1, rowIndex + 1, 1);
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex),
      )
      ..value = TextCellValue('Gênero Alimentício')
      ..cellStyle = _columnHeaderStyle();

    for (final modalidade in modalidades) {
      final colsPorModalidade =
          quantidadesAtivas.length + 4; // REFs + 3 lanches + Total
      final startCol = colIndex;
      final endCol = colIndex + colsPorModalidade - 1;

      _mergeCells(sheet, rowIndex, startCol, rowIndex, endCol);
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: rowIndex),
        )
        ..value = TextCellValue(modalidade)
        ..cellStyle = _modalityHeaderStyle();

      colIndex += colsPorModalidade;
    }

    // TOTAL GLOBAL mesclado verticalmente nas duas linhas do cabeçalho
    _mergeCells(sheet, rowIndex, colIndex, rowIndex + 1, colIndex);
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
      )
      ..value = TextCellValue('TOTAL GLOBAL')
      ..cellStyle = _totalHeaderStyle();

    rowIndex++;

    // Cabeçalho da tabela - Linha 2 (REFs, Lanches, Total)
    colIndex = 0;

    sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex++,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle =
        _columnHeaderStyle();

    sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex++,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle =
        _columnHeaderStyle();

    for (int i = 0; i < 6; i++) {
      // REFs
      for (final qtd in quantidadesAtivas) {
        sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex++,
              rowIndex: rowIndex,
            ),
          )
          ..value = TextCellValue(qtd.sigla)
          ..cellStyle = _subHeaderStyle();
      }

      // Lanches (rótulos iguais aos da planilha original)
      sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex++,
            rowIndex: rowIndex,
          ),
        )
        ..value = TextCellValue('Candanga')
        ..cellStyle = _subHeaderStyle();

      sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex++,
            rowIndex: rowIndex,
          ),
        )
        ..value = TextCellValue('Lanche Fácil')
        ..cellStyle = _subHeaderStyle();

      sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex++,
            rowIndex: rowIndex,
          ),
        )
        ..value = TextCellValue('Jantar')
        ..cellStyle = _subHeaderStyle();

      // Total
      sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex++,
            rowIndex: rowIndex,
          ),
        )
        ..value = TextCellValue('Total')
        ..cellStyle = _totalColumnStyle();
    }

    sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle =
        _totalHeaderStyle();

    rowIndex++;

    // Dados dos produtos por região
    for (
      int regiaoIdx = 0;
      regiaoIdx < regioesSelecionadas.length;
      regiaoIdx++
    ) {
      final regiaoId = regioesSelecionadas[regiaoIdx];
      final regiaoNome = regioesNomes[regiaoId] ?? regiaoId;

      // Linha de cabeçalho da região
      colIndex = 0;
      _mergeCells(sheet, rowIndex, 0, rowIndex, 10);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = TextCellValue('REGIÃO $regiaoId - $regiaoNome')
        ..cellStyle = _regionHeaderStyle();
      rowIndex++;

      // Produtos da região
      for (int i = 0; i < produtosSelecionados.length; i++) {
        final produto = produtosSelecionados[i];
        colIndex = 0;

        // Item (numeração sequencial)
        final itemNumero = (regiaoIdx * produtosSelecionados.length) + i + 1;
        sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex++,
              rowIndex: rowIndex,
            ),
          )
          ..value = TextCellValue(itemNumero.toString())
          ..cellStyle = _dataCellStyle();

        // Gênero Alimentício
        final generoTexto = [
          produto.nome,
          if ((produto.marca ?? '').isNotEmpty) 'Marca: ${produto.marca}',
          if ((produto.fabricante ?? '').isNotEmpty)
            'Fab.: ${produto.fabricante}',
        ].join('\n');

        sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex++,
              rowIndex: rowIndex,
            ),
          )
          ..value = TextCellValue(generoTexto)
          ..cellStyle = _dataCellStyle();

        // Dados para cada modalidade
        for (int modalidadeIndex = 0; modalidadeIndex < 6; modalidadeIndex++) {
          final modalidade = modalidades[modalidadeIndex];

          // Alunos da região específica para a modalidade atual
          final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
          final alunosRegiao =
              dadosRegiao[_getModalidadeEnumName(modalidade)] ?? {};

          // REFs
          for (final qtd in quantidadesAtivas) {
            final quantidade = _calcularQuantidadeRegiaoPorProduto(
              produto,
              qtd,
              modalidade,
              frequenciasPorProduto,
              alunosRegiao,
            );
            sheet.cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex,
                ),
              )
              ..value = IntCellValue(quantidade)
              ..cellStyle = _numberCellStyle();
          }

          // Lanches (vazios)
          for (int j = 0; j < 3; j++) {
            sheet
                    .cell(
                      CellIndex.indexByColumnRow(
                        columnIndex: colIndex++,
                        rowIndex: rowIndex,
                      ),
                    )
                    .cellStyle =
                _numberCellStyle();
          }

          // Total da modalidade para a região
          final totalModalidade = _calcularTotalModalidadeRegiaoPorProduto(
            produto,
            modalidade,
            frequenciasPorProduto,
            alunosRegiao,
            quantidadesAtivas,
          );
          sheet.cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex++,
                rowIndex: rowIndex,
              ),
            )
            ..value = IntCellValue(totalModalidade)
            ..cellStyle = _totalCellStyle();
        }

        // Total global da região (soma de todas as modalidades)
        int totalGlobal = 0;
        for (final modalidade in modalidades) {
          final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
          final alunosRegiao =
              dadosRegiao[_getModalidadeEnumName(modalidade)] ?? {};
          totalGlobal += _calcularTotalGlobalRegiao(
            produto,
            frequencias,
            alunosRegiao,
          );
        }
        sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex,
              rowIndex: rowIndex,
            ),
          )
          ..value = IntCellValue(totalGlobal)
          ..cellStyle = _grandTotalCellStyle();

        rowIndex++;
      }

      // Adicionar linha de "Total por modalidade" para esta região
      colIndex = 0;

      // Coluna Itens (vazia)
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex++,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle =
          _totalRowStyle();

      // Coluna Gênero (nome do total)
      sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex++,
            rowIndex: rowIndex,
          ),
        )
        ..value = TextCellValue('Total por modalidade')
        ..cellStyle = _totalRowStyle();

      // Para cada modalidade (6 no total)
      for (int modalidadeIndex = 0; modalidadeIndex < 6; modalidadeIndex++) {
        final modalidade = modalidades[modalidadeIndex];

        // REFs
        for (final qtd in quantidadesAtivas) {
          final total = _calcularTotalRegiaoREF(
            qtd,
            modalidade,
            regiaoId,
            produtosSelecionados,
            frequencias,
            alunosPorRegiaoModalidade,
          );
          sheet.cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex++,
                rowIndex: rowIndex,
              ),
            )
            ..value = IntCellValue(total)
            ..cellStyle = _totalRowStyle();
        }

        // Lanches (vazios)
        for (int j = 0; j < 3; j++) {
          sheet
                  .cell(
                    CellIndex.indexByColumnRow(
                      columnIndex: colIndex++,
                      rowIndex: rowIndex,
                    ),
                  )
                  .cellStyle =
              _totalRowStyle();
        }

        // Total da modalidade para a região
        final totalModalidade = _calcularTotalRegiaoModalidade(
          modalidade,
          regiaoId,
          produtosSelecionados,
          frequencias,
          alunosPorRegiaoModalidade,
          quantidadesAtivas,
        );
        sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex++,
              rowIndex: rowIndex,
            ),
          )
          ..value = IntCellValue(totalModalidade)
          ..cellStyle = _totalRowStyle();
      }

      // Total Global da região (vazio para linhas de modalidade)
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: colIndex,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle =
          _totalRowStyle();

      rowIndex++;

      // Pular duas linhas antes da próxima região (exceto na última região)
      if (regiaoIdx < regioesSelecionadas.length - 1) {
        rowIndex += 2;
      }
    }

    // Cabeçalho da seção consolidada
    colIndex = 0;
    _mergeCells(sheet, rowIndex, 0, rowIndex, 10);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
      ..value = TextCellValue(
        'MEMÓRIA DE CÁLCULO CONSOLIDADA (REGIÕES ${regioesSelecionadas.join(', ')}) QUANTIDADE GLOBAL',
      )
      ..cellStyle = _subtitleStyle();
    rowIndex++;

    rowIndex++; // Linha em branco

    // Linha única de TOTAL GLOBAL
    colIndex = 0;

    sheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: colIndex++,
                rowIndex: rowIndex,
              ),
            )
            .cellStyle =
        _totalRowStyle();

    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex++, rowIndex: rowIndex),
      )
      ..value = TextCellValue('TOTAL GLOBAL')
      ..cellStyle = _totalRowStyle();

    for (int modalidadeIndex = 0; modalidadeIndex < 6; modalidadeIndex++) {
      final modalidade = modalidades[modalidadeIndex];

      // REFs
      for (final qtd in quantidadesAtivas) {
        final total = _calcularTotalConsolidadoREF(
          qtd,
          modalidade,
          produtosSelecionados,
          frequencias,
          frequenciasPorProduto,
          totaisAlunos,
        );
        sheet.cell(
            CellIndex.indexByColumnRow(
              columnIndex: colIndex++,
              rowIndex: rowIndex,
            ),
          )
          ..value = IntCellValue(total)
          ..cellStyle = _totalRowStyle();
      }

      // Lanches (vazios)
      for (int j = 0; j < 3; j++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: colIndex++,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            _totalRowStyle();
      }

      // Total da modalidade
      final totalModalidade = _calcularTotalConsolidadoModalidade(
        modalidade,
        produtosSelecionados,
        frequencias,
        frequenciasPorProduto,
        totaisAlunos,
        quantidadesAtivas,
      );
      sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: colIndex++,
            rowIndex: rowIndex,
          ),
        )
        ..value = IntCellValue(totalModalidade)
        ..cellStyle = _totalRowStyle();
    }

    // Total global final
    final totalFinal = _calcularTotalConsolidadoFinal(
      produtosSelecionados,
      frequencias,
      totaisAlunos,
    );
    sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex),
      )
      ..value = IntCellValue(totalFinal)
      ..cellStyle = _grandTotalCellStyle();

    // Ajustar largura das colunas
    sheet.setColumnWidth(0, 10); // Itens
    sheet.setColumnWidth(1, 30); // Gênero

    // ============================
    //          CONSOLIDADO 2
    // ============================
    final sheet2 = excel['Consolidado 2'];

    // Cabeçalhos superiores (mesmos do Consolidado 1)
    int row2 = 0;
    _mergeCells(sheet2, row2, 0, row2, 10);
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
      ..value = TextCellValue(
        'SECRETARIA DE ESTADO DE EDUCAÇÃO DO DISTRITO FEDERAL',
      )
      ..cellStyle = _headerStyle();
    row2++;

    _mergeCells(sheet2, row2, 0, row2, 10);
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
      ..value = TextCellValue('SUBSECRETARIA DE ADMINISTRAÇÃO GERAL')
      ..cellStyle = _headerStyle();
    row2++;

    _mergeCells(sheet2, row2, 0, row2, 10);
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
      ..value = TextCellValue('DIRETORIA DE ALIMENTAÇÃO ESCOLAR')
      ..cellStyle = _headerStyle();
    row2++;

    row2++;

    _mergeCells(sheet2, row2, 0, row2, 10);
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
      ..value = TextCellValue(
        'Memória de Cálculo por Modalidade: Quantidades suficientes para atendimento de 200 dias letivos',
      )
      ..cellStyle = _titleStyle();
    row2++;

    _mergeCells(sheet2, row2, 0, row2, 10);
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
      ..value = TextCellValue(
        'DISTRIBUIÇÃO DE GÊNEROS ALIMENTÍCIOS – Educação Infantil, Ensino Fundamental, Especial, Creche e Médio',
      )
      ..cellStyle = _subtitleStyle();
    row2++;

    row2++;

    // Para cada região: tabela somente com totais por modalidade
    for (int r = 0; r < regioesSelecionadas.length; r++) {
      final regiaoId = regioesSelecionadas[r];
      final regiaoNome = regioesNomes[regiaoId] ?? regiaoId;

      // Título da região
      _mergeCells(sheet2, row2, 0, row2, 10);
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
        ..value = TextCellValue('REGIÃO $regiaoId - $regiaoNome')
        ..cellStyle = _regionHeaderStyle();
      row2++;

      // Cabeçalho: Itens, Gênero, Totais de modalidades e Total Região
      int c = 0;
      sheet2
              .cell(
                CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
              )
              .cellStyle =
          _columnHeaderStyle();
      sheet2
              .cell(
                CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
              )
              .cellStyle =
          _columnHeaderStyle();

      for (final modalidade in [
        'PRÉ-ESCOLA',
        'FUNDAMENTAL',
        'ESPECIAL',
        'CRECHE',
        'MÉDIO',
        'E.J.A.',
      ]) {
        sheet2.cell(
            CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
          )
          ..value = TextCellValue('Total $modalidade')
          ..cellStyle = _columnHeaderStyle();
      }

      sheet2
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row2))
          .value = TextCellValue(
        'TOTAL REGIÃO',
      );
      sheet2
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row2))
              .cellStyle =
          _totalHeaderStyle();
      row2++;

      // Linhas de produtos (somente totais por modalidade)
      for (int i = 0; i < produtosSelecionados.length; i++) {
        final produto = produtosSelecionados[i];
        c = 0;
        final itemNumero = (r * produtosSelecionados.length) + i + 1;

        sheet2.cell(
            CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
          )
          ..value = IntCellValue(itemNumero)
          ..cellStyle = _dataCellStyle();

        final generoTexto = [
          produto.nome,
          if ((produto.marca ?? '').isNotEmpty) 'Marca: ${produto.marca}',
          if ((produto.fabricante ?? '').isNotEmpty)
            'Fab.: ${produto.fabricante}',
        ].join('\n');
        sheet2.cell(
            CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
          )
          ..value = TextCellValue(generoTexto)
          ..cellStyle = _dataCellStyle();

        int somaProdutoRegiao = 0;
        for (final modalidade in [
          'PRÉ-ESCOLA',
          'FUNDAMENTAL',
          'ESPECIAL',
          'CRECHE',
          'MÉDIO',
          'E.J.A.',
        ]) {
          final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
          final alunosRegiao =
              dadosRegiao[_getModalidadeEnumName(modalidade)] ?? {};
          final totalMod = _calcularTotalModalidadeRegiaoPorProduto(
            produto,
            modalidade,
            frequenciasPorProduto,
            alunosRegiao,
            quantidadesAtivas,
          );
          somaProdutoRegiao += totalMod;
          sheet2.cell(
              CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
            )
            ..value = IntCellValue(totalMod)
            ..cellStyle = _numberCellStyle();
        }

        sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row2))
          ..value = IntCellValue(somaProdutoRegiao)
          ..cellStyle = _grandTotalCellStyle();
        row2++;
      }

      // Linha TOTAL por região (somatório por modalidade + total da região)
      c = 0;
      sheet2
              .cell(
                CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
              )
              .cellStyle =
          _totalRowStyle();
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2))
        ..value = TextCellValue('TOTAL')
        ..cellStyle = _totalRowStyle();

      int totalRegiaoGeral = 0;
      for (final modalidade in [
        'PRÉ-ESCOLA',
        'FUNDAMENTAL',
        'ESPECIAL',
        'CRECHE',
        'MÉDIO',
        'E.J.A.',
      ]) {
        int somaMod = 0;
        for (final produto in produtosSelecionados) {
          final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
          final alunosRegiao =
              dadosRegiao[_getModalidadeEnumName(modalidade)] ?? {};
          somaMod += _calcularTotalModalidadeRegiaoPorProduto(
            produto,
            modalidade,
            frequenciasPorProduto,
            alunosRegiao,
            quantidadesAtivas,
          );
        }
        totalRegiaoGeral += somaMod;
        sheet2.cell(
            CellIndex.indexByColumnRow(columnIndex: c++, rowIndex: row2),
          )
          ..value = IntCellValue(somaMod)
          ..cellStyle = _totalRowStyle();
      }

      sheet2
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row2))
          .value = IntCellValue(
        totalRegiaoGeral,
      );
      sheet2
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row2))
              .cellStyle =
          _totalRowStyle();
      row2++;

      // Pular duas linhas entre regiões
      if (r < regioesSelecionadas.length - 1) {
        row2 += 2;
      }
    }

    // Quadro final: consolidado global (por produto, por modalidade)
    _mergeCells(sheet2, row2, 0, row2, 10);
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row2))
      ..value = TextCellValue(
        'MEMÓRIA DE CÁLCULO CONSOLIDADA (REGIÕES ${regioesSelecionadas.join(', ')}) QUANTIDADE GLOBAL',
      )
      ..cellStyle = _subtitleStyle();
    row2++;
    row2++;

    // Cabeçalho do quadro global
    int cg = 0;
    sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
            .cellStyle =
        _columnHeaderStyle();
    sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
            .cellStyle =
        _columnHeaderStyle();
    for (final modalidade in [
      'PRÉ-ESCOLA',
      'FUNDAMENTAL',
      'ESPECIAL',
      'CRECHE',
      'MÉDIO',
      'E.J.A.',
    ]) {
      sheet2
          .cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
          .value = TextCellValue(
        'Total $modalidade',
      );
      sheet2
              .cell(
                CellIndex.indexByColumnRow(columnIndex: cg - 1, rowIndex: row2),
              )
              .cellStyle =
          _columnHeaderStyle();
    }
    sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: cg, rowIndex: row2))
            .cellStyle =
        _totalHeaderStyle();
    sheet2
        .cell(CellIndex.indexByColumnRow(columnIndex: cg, rowIndex: row2))
        .value = TextCellValue(
      'TOTAL GLOBAL',
    );
    row2++;

    // Linhas por produto no quadro global
    for (int i = 0; i < produtosSelecionados.length; i++) {
      final produto = produtosSelecionados[i];
      cg = 0;

      // Itens (1, 3, 5, 7 ...)
      final itensTexto = List.generate(
        regioesSelecionadas.length,
        (k) => i + 1 + k * produtosSelecionados.length,
      ).join(', ');
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
        ..value = TextCellValue(itensTexto)
        ..cellStyle = _dataCellStyle();

      // Gênero
      final generoTexto = [
        produto.nome,
        if ((produto.marca ?? '').isNotEmpty) 'Marca: ${produto.marca}',
        if ((produto.fabricante ?? '').isNotEmpty)
          'Fab.: ${produto.fabricante}',
      ].join('\n');
      sheet2.cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
        ..value = TextCellValue(generoTexto)
        ..cellStyle = _dataCellStyle();

      int somaGlobalProduto = 0;
      for (final modalidade in [
        'PRÉ-ESCOLA',
        'FUNDAMENTAL',
        'ESPECIAL',
        'CRECHE',
        'MÉDIO',
        'E.J.A.',
      ]) {
        int totalModGlobal = 0;
        for (final regiaoId in regioesSelecionadas) {
          final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
          final alunosRegiao =
              dadosRegiao[_getModalidadeEnumName(modalidade)] ?? {};
          totalModGlobal += _calcularTotalModalidadeRegiaoPorProduto(
            produto,
            modalidade,
            frequenciasPorProduto,
            alunosRegiao,
            quantidadesAtivas,
          );
        }
        somaGlobalProduto += totalModGlobal;
        sheet2.cell(
            CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2),
          )
          ..value = IntCellValue(totalModGlobal)
          ..cellStyle = _numberCellStyle();
      }

      sheet2
          .cell(CellIndex.indexByColumnRow(columnIndex: cg, rowIndex: row2))
          .value = IntCellValue(
        somaGlobalProduto,
      );
      sheet2
              .cell(CellIndex.indexByColumnRow(columnIndex: cg, rowIndex: row2))
              .cellStyle =
          _grandTotalCellStyle();
      row2++;
    }

    // Linha TOTAL GLOBAL (somatório de todas as linhas por modalidade)
    cg = 0;
    sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
            .cellStyle =
        _totalRowStyle();
    sheet2.cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
      ..value = TextCellValue('TOTAL GLOBAL')
      ..cellStyle = _totalRowStyle();

    int somaGlobalFinal = 0;
    for (final modalidade in [
      'PRÉ-ESCOLA',
      'FUNDAMENTAL',
      'ESPECIAL',
      'CRECHE',
      'MÉDIO',
      'E.J.A.',
    ]) {
      int somaMod = 0;
      for (final produto in produtosSelecionados) {
        for (final regiaoId in regioesSelecionadas) {
          final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
          final alunosRegiao =
              dadosRegiao[_getModalidadeEnumName(modalidade)] ?? {};
          somaMod += _calcularTotalModalidadeRegiaoPorProduto(
            produto,
            modalidade,
            frequenciasPorProduto,
            alunosRegiao,
            quantidadesAtivas,
          );
        }
      }
      somaGlobalFinal += somaMod;
      sheet2
          .cell(CellIndex.indexByColumnRow(columnIndex: cg++, rowIndex: row2))
          .value = IntCellValue(
        somaMod,
      );
      sheet2
              .cell(
                CellIndex.indexByColumnRow(columnIndex: cg - 1, rowIndex: row2),
              )
              .cellStyle =
          _totalRowStyle();
    }

    sheet2
        .cell(CellIndex.indexByColumnRow(columnIndex: cg, rowIndex: row2))
        .value = IntCellValue(
      somaGlobalFinal,
    );
    sheet2
            .cell(CellIndex.indexByColumnRow(columnIndex: cg, rowIndex: row2))
            .cellStyle =
        _grandTotalCellStyle();

    // Larguras principais
    sheet2.setColumnWidth(0, 10);
    sheet2.setColumnWidth(1, 30);

    return Uint8List.fromList(excel.encode()!);
  }

  // Converte o display da modalidade (ex.: "PRÉ-ESCOLA", "Fundamental")
  // para o nome do enum correspondente (ex.: "preEscola", "fundamental1").
  static String _getModalidadeEnumName(String modalidadeDisplayName) {
    for (final mod in ModalidadeEnsino.values) {
      if (mod.displayName.toUpperCase() ==
          modalidadeDisplayName.toUpperCase()) {
        return mod.name;
      }
    }
    // Fallback
    return ModalidadeEnsino.fundamental1.name;
  }

  static void _mergeCells(
    Sheet sheet,
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: startRow),
      CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: endRow),
    );
  }

  // Estilos
  static CellStyle _headerStyle() {
    return CellStyle(
      bold: true,
      fontSize: 12,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
  }

  static CellStyle _titleStyle() {
    return CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
    );
  }

  static CellStyle _subtitleStyle() {
    return CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
    );
  }

  static CellStyle _columnHeaderStyle() {
    return CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _modalityHeaderStyle() {
    return CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.blue,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _subHeaderStyle() {
    return CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.lightBlue,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _totalHeaderStyle() {
    return CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.yellow,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _totalColumnStyle() {
    return CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _dataCellStyle() {
    return CellStyle(
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _numberCellStyle() {
    return CellStyle(
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _totalCellStyle() {
    return CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Medium),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _grandTotalCellStyle() {
    return CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.yellow,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  static CellStyle _totalRowStyle() {
    return CellStyle(
      bold: true,
      fontSize: 9,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.lightBlue,
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      bottomBorder: Border(borderStyle: BorderStyle.Medium),
    );
  }

  static CellStyle _regionHeaderStyle() {
    return CellStyle(
      bold: true,
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('FFD9D9D9'),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      topBorder: Border(borderStyle: BorderStyle.Medium),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
    );
  }

  // Funções de cálculo (copiadas do PDFGenerator)
  static int arredondamentoBancario(double valor) {
    final parteInteira = valor.floor();
    final parteDecimal = valor - parteInteira;

    if (parteDecimal < 0.5) {
      return parteInteira;
    } else if (parteDecimal > 0.5) {
      return parteInteira + 1;
    } else {
      if (parteInteira % 2 == 0) {
        return parteInteira;
      } else {
        return parteInteira + 1;
      }
    }
  }

  static int _calcularQuantidadeRegiao(
    Produto produto,
    QuantidadeRefeicao qtd,
    String modalidade,
    Map<String, double> frequencias,
    Map<String, int> alunosRegiao,
  ) {
    ModalidadeEnsino modalidadeEnum;
    switch (modalidade) {
      case 'PRÉ-ESCOLA':
        modalidadeEnum = ModalidadeEnsino.preEscola;
        break;
      case 'FUNDAMENTAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'ESPECIAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'CRECHE':
        modalidadeEnum = ModalidadeEnsino.preEscola;
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

    final alunos = alunosRegiao[qtd.id] ?? 0;
    final perCapita = produto.getPerCapitaForDomain(
      'gpae',
      modalidadeEnum,
      qtd.id,
    );
    final frequencia = frequencias[qtd.id] ?? 0;
    final quantidadeCalculada = alunos * perCapita * frequencia;
    return arredondamentoBancario(quantidadeCalculada);
  }

  static int _calcularQuantidadeRegiaoPorProduto(
    Produto produto,
    QuantidadeRefeicao qtd,
    String modalidade,
    Map<String, Map<String, double>> frequenciasPorProduto,
    Map<String, int> alunosRegiao,
  ) {
    ModalidadeEnsino modalidadeEnum;
    switch (modalidade) {
      case 'PRÉ-ESCOLA':
        modalidadeEnum = ModalidadeEnsino.preEscola;
        break;
      case 'FUNDAMENTAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'ESPECIAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'CRECHE':
        modalidadeEnum = ModalidadeEnsino.preEscola;
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

    final alunos = alunosRegiao[qtd.id] ?? 0;
    final perCapita = produto.getPerCapitaForDomain(
      'gpae',
      modalidadeEnum,
      qtd.id,
    );

    // Usar frequência específica do produto, ou fallback para frequência global
    final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
    final chave = '${modalidadeEnum.name}_${qtd.id}';
    final frequencia = frequenciasProduto[chave] ?? 0;

    final quantidadeCalculada = alunos * perCapita * frequencia;
    return arredondamentoBancario(quantidadeCalculada);
  }

  static int _calcularTotalModalidadeRegiao(
    Produto produto,
    String modalidade,
    Map<String, double> frequencias,
    Map<String, int> alunosRegiao,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;
    for (final qtd in frequencias.keys) {
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

      total += _calcularQuantidadeRegiao(
        produto,
        qtdRef,
        modalidade,
        frequencias,
        alunosRegiao,
      );
    }
    return total;
  }

  static int _calcularTotalModalidadeRegiaoPorProduto(
    Produto produto,
    String modalidade,
    Map<String, Map<String, double>> frequenciasPorProduto,
    Map<String, int> alunosRegiao,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;

    for (final qtd in quantidadesAtivas) {
      total += _calcularQuantidadeRegiaoPorProduto(
        produto,
        qtd,
        modalidade,
        frequenciasPorProduto,
        alunosRegiao,
      );
    }
    return total;
  }

  static int _calcularTotalGlobalRegiao(
    Produto produto,
    Map<String, double> frequencias,
    Map<String, int> alunosRegiao,
  ) {
    double total = 0;
    for (final qtd in frequencias.keys) {
      final alunos = alunosRegiao[qtd] ?? 0;
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

  static int _calcularQuantidadeConsolidadaPorProduto(
    Produto produto,
    QuantidadeRefeicao qtd,
    String modalidade,
    Map<String, Map<String, double>> frequenciasPorProduto,
    Map<String, int> totaisAlunos,
  ) {
    ModalidadeEnsino modalidadeEnum;
    switch (modalidade) {
      case 'PRÉ-ESCOLA':
        modalidadeEnum = ModalidadeEnsino.preEscola;
        break;
      case 'FUNDAMENTAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'ESPECIAL':
        modalidadeEnum = ModalidadeEnsino.fundamental1;
        break;
      case 'CRECHE':
        modalidadeEnum = ModalidadeEnsino.preEscola;
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

    // Usar frequência específica do produto
    final frequenciasProduto = frequenciasPorProduto[produto.id] ?? {};
    final chave = '${modalidadeEnum.name}_${qtd.id}';
    final frequencia = frequenciasProduto[chave] ?? 0;

    final quantidadeCalculada = alunos * perCapita * frequencia;
    return arredondamentoBancario(quantidadeCalculada);
  }

  static int _calcularTotalModalidade(
    Produto produto,
    String modalidade,
    Map<String, double> frequencias,
    Map<String, Map<String, double>> frequenciasPorProduto,
    Map<String, int> totaisAlunos,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;
    for (final qtd in frequencias.keys) {
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

      total += _calcularQuantidadeConsolidadaPorProduto(
        produto,
        qtdRef,
        modalidade,
        frequenciasPorProduto,
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
    Map<String, Map<String, double>> frequenciasPorProduto,
    Map<String, int> totaisAlunos,
  ) {
    int total = 0;
    for (final produto in produtosSelecionados) {
      total += _calcularQuantidadeConsolidadaPorProduto(
        produto,
        qtd,
        modalidade,
        frequenciasPorProduto,
        totaisAlunos,
      );
    }
    return total;
  }

  static int _calcularTotalConsolidadoModalidade(
    String modalidade,
    List<Produto> produtosSelecionados,
    Map<String, double> frequencias,
    Map<String, Map<String, double>> frequenciasPorProduto,
    Map<String, int> totaisAlunos,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;
    for (final produto in produtosSelecionados) {
      total += _calcularTotalModalidade(
        produto,
        modalidade,
        frequencias,
        frequenciasPorProduto,
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
    int total = 0;
    for (final produto in produtosSelecionados) {
      total += _calcularTotalGlobal(produto, frequencias, totaisAlunos);
    }
    return total;
  }

  static int _calcularTotalRegiaoREF(
    QuantidadeRefeicao qtd,
    String modalidade,
    String regiaoId,
    List<Produto> produtosSelecionados,
    Map<String, double> frequencias,
    Map<String, Map<String, Map<String, int>>> alunosPorRegiaoModalidade,
  ) {
    int total = 0;
    final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
    final alunosRegiao = dadosRegiao[modalidade] ?? {};

    for (final produto in produtosSelecionados) {
      total += _calcularQuantidadeRegiao(
        produto,
        qtd,
        modalidade,
        frequencias,
        alunosRegiao,
      );
    }
    return total;
  }

  static int _calcularTotalRegiaoModalidade(
    String modalidade,
    String regiaoId,
    List<Produto> produtosSelecionados,
    Map<String, double> frequencias,
    Map<String, Map<String, Map<String, int>>> alunosPorRegiaoModalidade,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    int total = 0;
    final dadosRegiao = alunosPorRegiaoModalidade[regiaoId] ?? {};
    final alunosRegiao = dadosRegiao[modalidade] ?? {};

    for (final produto in produtosSelecionados) {
      total += _calcularTotalModalidadeRegiao(
        produto,
        modalidade,
        frequencias,
        alunosRegiao,
        quantidadesAtivas,
      );
    }
    return total;
  }
}
