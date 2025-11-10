import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/escola.dart';
import '../../models/memoria_calculo.dart';
import '../../models/produto.dart';
import '../../models/quantidade_refeicao.dart';
import '../../models/regiao.dart';
import '../../services/excel_generator.dart';
import '../../services/pdf_generator.dart';
import 'widgets/memoria_calculo_detail_dialog.dart';

class MemoriasCalculoStatusScreen extends StatefulWidget {
  const MemoriasCalculoStatusScreen({super.key});

  @override
  State<MemoriasCalculoStatusScreen> createState() =>
      _MemoriasCalculoStatusScreenState();
}

class _MemoriasCalculoStatusScreenState
    extends State<MemoriasCalculoStatusScreen> {
  List<AnoLetivo> anosLetivos = [];
  Map<String, List<MemoriaCalculo>> memoriasPorAno = {};
  List<Produto> produtos = [];
  List<QuantidadeRefeicao> quantidadesRefeicao = [];
  List<Regiao> regioes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
    });

    try {
      final db = FirestoreHelper();
      final anosDb = await db.getAnosLetivos();
      final todasMemorias = await db.getMemoriasCalculo();
      final produtosDb = await db.getProdutos();
      final quantidadesDb = await db.getQuantidadesRefeicao();
      final regioesDb = await db.getRegioes();

      // Agrupar memórias por ano
      final Map<String, List<MemoriaCalculo>> agrupadas = {};
      for (final memoria in todasMemorias) {
        if (!agrupadas.containsKey(memoria.anoLetivo)) {
          agrupadas[memoria.anoLetivo] = [];
        }
        agrupadas[memoria.anoLetivo]!.add(memoria);
      }

      // Ordenar memórias por número
      for (final lista in agrupadas.values) {
        lista.sort((a, b) => a.numero.compareTo(b.numero));
      }

      setState(() {
        anosLetivos = anosDb;
        memoriasPorAno = agrupadas;
        produtos = produtosDb;
        quantidadesRefeicao = quantidadesDb;
        regioes = regioesDb;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  void _abrirDetalhesMemoria(MemoriaCalculo memoria) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => MemoriaCalculoDetailDialog(memoria: memoria),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Aquisições - Status dos Produtos'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : anosLetivos.isEmpty
          ? const Center(child: Text('Nenhum ano letivo cadastrado'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: anosLetivos.length,
              itemBuilder: (context, index) {
                final ano = anosLetivos[index];
                final memorias = memoriasPorAno[ano.ano.toString()] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      'Ano Letivo ${ano.ano}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      '${memorias.length} memória(s) de cálculo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    children: memorias.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Nenhuma memória de cálculo cadastrada',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ]
                        : memorias.map((memoria) {
                            // Calcular estatísticas de status
                            final totalProdutos =
                                memoria.produtosSelecionados.length;
                            final adquiridos = memoria.statusProdutos.values
                                .where(
                                  (s) => s == StatusProdutoMemoria.adquirido,
                                )
                                .length;
                            final emAquisicao =
                                totalProdutos -
                                memoria.statusProdutos.length +
                                memoria.statusProdutos.values
                                    .where(
                                      (s) =>
                                          s == StatusProdutoMemoria.emAquisicao,
                                    )
                                    .length;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  '${memoria.numero}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                  ),
                                ),
                              ),
                              title: Text(memoria.titulo),
                              subtitle: Text(
                                '$adquiridos/$totalProdutos adquiridos • $emAquisicao em aquisição',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (adquiridos == totalProdutos)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '✓ Completo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green[900],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.print, size: 20),
                                    color: Colors.purple,
                                    tooltip: 'Imprimir PDFs',
                                    onPressed: () => _gerarPDFsMemoria(memoria),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () => _abrirDetalhesMemoria(memoria),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _gerarPDFsMemoria(MemoriaCalculo memoria) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Gerando relatórios...'),
            ],
          ),
        ),
      );

      // Criar mapa de nomes das regiões e regionais
      final Map<String, String> regioesNomes = {};
      final Map<String, List<String>> regionaisPorRegiao = {};
      for (final regiao in regioes) {
        regioesNomes[regiao.id] = regiao.nome;
        regionaisPorRegiao[regiao.id] = regiao.regionais
            .map((r) => r.nome)
            .toList();
      }

      // Buscar produtos selecionados
      final produtosSelecionados = <Produto>[];
      for (final produtoId in memoria.produtosSelecionados) {
        final produto = produtos.firstWhere((p) => p.id == produtoId);
        produtosSelecionados.add(produto);
      }

      // Gerar um PDF para cada modalidade selecionada
      final relatoriosGerados = <Map<String, dynamic>>[];
      for (final modalidadeName in memoria.modalidadesSelecionadas) {
        final modalidade = ModalidadeEnsino.values.firstWhere(
          (m) => m.name == modalidadeName,
        );

        // Frequências do domínio GPAE ou fallback
        final frequencias =
            memoria.frequenciaByDomain['gpae']?[modalidadeName] ??
            memoria.frequenciaPorModalidadeQuantidade[modalidadeName] ??
            {};

        // Dados específicos desta modalidade usando dados congelados
        final Map<String, Map<String, int>>
        alunosPorRegiaoModalidadeEspecifica = {};
        for (final regiaoId in memoria.regioesSelecionadas) {
          alunosPorRegiaoModalidadeEspecifica[regiaoId] = {};
          for (final qtd in quantidadesRefeicao.where((q) => q.ativo)) {
            alunosPorRegiaoModalidadeEspecifica[regiaoId]![qtd.id] = 0;
          }

          final dadosCongeladosRegiao = memoria.dadosAlunosCongelados[regiaoId];
          if (dadosCongeladosRegiao != null) {
            final dadosModalidade = dadosCongeladosRegiao[modalidadeName];
            if (dadosModalidade != null) {
              for (final qtdEntry in dadosModalidade.entries) {
                final qtdId = qtdEntry.key;
                final qtdAlunos = qtdEntry.value;
                if (alunosPorRegiaoModalidadeEspecifica[regiaoId]!.containsKey(
                  qtdId,
                )) {
                  alunosPorRegiaoModalidadeEspecifica[regiaoId]![qtdId] =
                      qtdAlunos;
                }
              }
            }
          }
        }

        final pdfBytes = await PDFGenerator.generateRelatorioMemoriaCalculo(
          anoLetivo: memoria.anoLetivo,
          numeroMemoria: memoria.numero,
          titulo: memoria.titulo,
          modalidade: modalidade.displayName,
          regioesSelecionadas: memoria.regioesSelecionadas,
          regioesNomes: regioesNomes,
          regionaisPorRegiao: regionaisPorRegiao,
          alunosPorRegiaoModalidade: alunosPorRegiaoModalidadeEspecifica,
          frequencias: frequencias,
          frequenciasPorProduto: memoria.frequenciaPorProduto,
          quantidadesRefeicao: quantidadesRefeicao,
          produtosSelecionados: produtosSelecionados,
        );

        relatoriosGerados.add({
          'modalidade': modalidade.displayName,
          'bytes': pdfBytes,
          'fileName':
              'MemoriaCalculo_${memoria.numero}_${modalidade.displayName}.pdf',
        });
      }

      // ================= Consolidado 1 Excel =================

      final excelConsolidado =
          await ExcelGenerator.generateConsolidadoMemoriaCalculo(
            anoLetivo: memoria.anoLetivo,
            numeroMemoria: memoria.numero,
            titulo: memoria.titulo,
            regioesSelecionadas: memoria.regioesSelecionadas,
            regioesNomes: regioesNomes,
            alunosPorRegiaoModalidade: memoria.dadosAlunosCongelados,
            frequencias: {}, // Não usado no novo sistema
            frequenciasPorProduto: memoria.frequenciaPorProduto,
            quantidadesRefeicao: quantidadesRefeicao,
            produtosSelecionados: produtosSelecionados,
          );

      relatoriosGerados.add({
        'modalidade': 'CONSOLIDADO 1 EXCEL',
        'bytes': excelConsolidado,
        'fileName': 'MemoriaCalculo_${memoria.numero}_Consolidado_1.xlsx',
      });

      if (mounted) Navigator.of(context).pop();
      for (final relatorio in relatoriosGerados) {
        await _downloadFile(
          relatorio['bytes'] as Uint8List,
          relatorio['fileName'] as String,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${relatoriosGerados.length} relatório(s) baixado(s) com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao gerar relatórios: $e')));
      }
    }
  }

  Future<void> _downloadFile(Uint8List bytes, String fileName) async {
    try {
      final blob = web.Blob([bytes.toJS].toJS);
      final url = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = fileName;
      anchor.click();
      web.URL.revokeObjectURL(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao baixar PDF: $e')));
      }
    }
  }
}
