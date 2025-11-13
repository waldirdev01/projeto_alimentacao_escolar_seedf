// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/distribuicao.dart';
import '../../models/escola.dart';
import '../../models/memoria_calculo.dart';
import '../../models/produto.dart';
import '../../models/quantidade_refeicao.dart';
import '../../models/regiao.dart';
import '../../services/excel_generator.dart';
import '../../services/pdf_generator.dart';
import '../diae/widgets/memoria_calculo_detail_dialog.dart';
import 'distribuicoes_por_ano_screen.dart';
import 'memoria_calculo_qtd_screen.dart';
import 'widgets/criar_memoria_calculo_dialog.dart';
import 'widgets/dados_alunos_regiao_widget.dart';

class AnoLetivoDetailScreen extends StatefulWidget {
  final AnoLetivo anoLetivo;

  const AnoLetivoDetailScreen({super.key, required this.anoLetivo});

  @override
  State<AnoLetivoDetailScreen> createState() => _AnoLetivoDetailScreenState();
}

class _AnoLetivoDetailScreenState extends State<AnoLetivoDetailScreen> {
  List<MemoriaCalculo> memoriasCalculo = [];
  List<Produto> produtos = [];
  List<QuantidadeRefeicao> quantidadesRefeicao = [];
  List<Regiao> regioes = [];
  List<Distribuicao> distribuicoes = [];
  Distribuicao? distribuicaoSelecionada;
  Map<String, Map<String, Map<String, int>>>
  alunosPorRegiaoModalidadeQuantidade = {};
  Map<String, Map<String, int>> matriculadosPorRegiaoModalidade = {};
  List<Map<String, dynamic>> distribuicoesComTotais = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final db = FirestoreHelper();
      final memoriasDb = await db.getMemoriasCalculoPorAno(
        widget.anoLetivo.ano.toString(),
      );
      final produtosDb = await db.getProdutos();
      final quantidadesDb = await db.getQuantidadesRefeicao();
      final regioesDb = await db.getRegioes();

      // Carregar distribuições do ano
      final todasDistribuicoes = await db.getDistribuicoes();
      final distribuicoesDoAno =
          todasDistribuicoes
              .where((d) => d.anoLetivo == widget.anoLetivo.ano.toString())
              .toList()
            ..sort(
              (a, b) => b.numero.compareTo(a.numero),
            ); // Mais recente primeiro

      // Remover duplicadas por id (caso a coleção retorne repetidos)
      final Set<String> idsVistos = {};
      final List<Distribuicao> distribuicoesDoAnoUnicas = [];
      for (final d in distribuicoesDoAno) {
        if (idsVistos.add(d.id)) {
          distribuicoesDoAnoUnicas.add(d);
        }
      }

      // Calcular totais para todas as distribuições
      await _calcularTotaisDistribuicoes(
        db,
        regioesDb,
        distribuicoesDoAnoUnicas,
        quantidadesDb,
      );

      // Carregar dados de alunos para a primeira distribuição (para MemoriaCalculo)
      if (distribuicoesDoAnoUnicas.isNotEmpty) {
        await _carregarDadosAlunos(
          db,
          regioesDb,
          distribuicoesDoAnoUnicas.first.id,
        );
      }

      setState(() {
        distribuicoes = distribuicoesDoAnoUnicas;
        distribuicaoSelecionada = null; // Não selecionar nenhuma por padrão
      });

      setState(() {
        memoriasCalculo = memoriasDb;
        produtos = produtosDb;
        quantidadesRefeicao = quantidadesDb;
        regioes = regioesDb;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<void> _carregarDadosAlunos(
    FirestoreHelper db,
    List<Regiao> regioesDb,
    String distribuicaoId,
  ) async {
    final Map<String, Map<String, Map<String, int>>> dados = {};
    final Map<String, Map<String, int>> matriculados = {};

    // Criar mapeamento de regionalId -> regiaoId
    final Map<String, String> regionalParaRegiao = {};
    for (final regiao in regioesDb) {
      for (final regional in regiao.regionais) {
        regionalParaRegiao[regional.id] = regiao.id;
      }
    }

    // Inicializar estrutura para cada região
    for (final regiao in regioesDb) {
      dados[regiao.id] = {};
      matriculados[regiao.id] = {};
      for (final modalidade in ModalidadeEnsino.values) {
        dados[regiao.id]![modalidade.name] = {};
        matriculados[regiao.id]![modalidade.name] = 0;
      }
    }

    // Buscar escolas e agregar dados
    final escolasList = await db.getEscolas();

    for (final escola in escolasList) {
      // Encontrar a região da escola através da regional
      final regiaoId = regionalParaRegiao[escola.regionalId];

      if (regiaoId == null) continue;

      final dadosEscola = await db.getDadosAlunosPorEscola(escola.id);

      for (final dadosAluno in dadosEscola) {
        // Verificar se é do ano correto E da distribuição selecionada
        if (dadosAluno.anoLetivo == widget.anoLetivo.ano.toString() &&
            dadosAluno.distribuicaoId == distribuicaoId) {
          for (final modalidadeEntry in dadosAluno.modalidades.entries) {
            final modalidadeNome = modalidadeEntry.key;
            final dadosModalidade = modalidadeEntry.value;

            if (dados[regiaoId] != null &&
                dados[regiaoId]![modalidadeNome] != null) {
              // Agregar matriculados
              matriculados[regiaoId]![modalidadeNome] =
                  (matriculados[regiaoId]![modalidadeNome] ?? 0) +
                  dadosModalidade.matriculados;

              // Agregar alunos por Tipo de refeição
              for (final qtdEntry
                  in dadosModalidade.quantidadeRefeicoes.entries) {
                final qtdId = qtdEntry.key;
                final qtdAlunos = qtdEntry.value;

                dados[regiaoId]![modalidadeNome]![qtdId] =
                    (dados[regiaoId]![modalidadeNome]![qtdId] ?? 0) + qtdAlunos;
              }
            }
          }
        }
      }
    }

    alunosPorRegiaoModalidadeQuantidade = dados;
    matriculadosPorRegiaoModalidade = matriculados;
  }

  Future<void> _calcularTotaisDistribuicoes(
    FirestoreHelper db,
    List<Regiao> regioesDb,
    List<Distribuicao> distribuicoesDoAno,
    List<QuantidadeRefeicao> quantidadesDb,
  ) async {
    final List<Map<String, dynamic>> totaisDistribuicoes = [];

    for (final distribuicao in distribuicoesDoAno) {
      // Carregar dados para esta distribuição
      final Map<String, Map<String, Map<String, int>>> dados = {};
      final Map<String, Map<String, int>> matriculados = {};

      // Criar mapeamento de regionalId -> regiaoId
      final Map<String, String> regionalParaRegiao = {};
      for (final regiao in regioesDb) {
        for (final regional in regiao.regionais) {
          regionalParaRegiao[regional.id] = regiao.id;
        }
      }

      // Inicializar estrutura para cada região
      for (final regiao in regioesDb) {
        dados[regiao.id] = {};
        matriculados[regiao.id] = {};
        for (final modalidade in ModalidadeEnsino.values) {
          dados[regiao.id]![modalidade.name] = {};
          matriculados[regiao.id]![modalidade.name] = 0;
        }
      }

      // Buscar escolas e agregar dados
      final escolasList = await db.getEscolas();

      for (final escola in escolasList) {
        // Encontrar a região da escola através da regional
        final regiaoId = regionalParaRegiao[escola.regionalId];

        if (regiaoId == null) continue;

        final dadosEscola = await db.getDadosAlunosPorEscola(escola.id);

        for (final dadosAluno in dadosEscola) {
          // Verificar se é do ano correto E da distribuição específica
          if (dadosAluno.anoLetivo == widget.anoLetivo.ano.toString() &&
              dadosAluno.distribuicaoId == distribuicao.id) {
            for (final modalidadeEntry in dadosAluno.modalidades.entries) {
              final modalidadeNome = modalidadeEntry.key;
              final dadosModalidade = modalidadeEntry.value;

              if (dados[regiaoId] != null &&
                  dados[regiaoId]![modalidadeNome] != null) {
                // Agregar matriculados
                matriculados[regiaoId]![modalidadeNome] =
                    (matriculados[regiaoId]![modalidadeNome] ?? 0) +
                    dadosModalidade.matriculados;

                // Agregar alunos por Tipo de refeição
                for (final qtdEntry
                    in dadosModalidade.quantidadeRefeicoes.entries) {
                  final qtdId = qtdEntry.key;
                  final qtdAlunos = qtdEntry.value;

                  dados[regiaoId]![modalidadeNome]![qtdId] =
                      (dados[regiaoId]![modalidadeNome]![qtdId] ?? 0) +
                      qtdAlunos;
                }
              }
            }
          }
        }

        // Calcular totais gerais
        int totalMatriculados = 0;
        int totalRefeicoes = 0;

        // Mapa para armazenar totais por Tipo de refeição
        final Map<String, int> totaisPorQuantidade = {};

        for (final regiao in regioesDb) {
          final dadosRegiao = dados[regiao.id] ?? {};
          final matriculadosRegiao = matriculados[regiao.id] ?? {};

          for (final modalidade in ModalidadeEnsino.values) {
            final dadosModalidade = dadosRegiao[modalidade.name] ?? {};
            final matriculadosModalidade =
                matriculadosRegiao[modalidade.name] ?? 0;

            totalMatriculados += matriculadosModalidade;

            // Somar todas as Tipo  de Refeição
            for (final qtdEntry in dadosModalidade.entries) {
              final qtdAlunos = qtdEntry.value;
              final qtdKey = qtdEntry.key;

              totalRefeicoes += qtdAlunos;

              // Somar por Tipo de refeição específica
              totaisPorQuantidade[qtdKey] =
                  (totaisPorQuantidade[qtdKey] ?? 0) + qtdAlunos;
            }
          }
        }

        // Criar mapa de totais incluindo todas as Tipo  de Refeição
        final Map<String, int> totais = {
          'matriculados': totalMatriculados,
          'total_refeicoes': totalRefeicoes,
        };

        // Adicionar totais para cada Tipo de refeição ativa
        for (final qtd in quantidadesDb.where((q) => q.ativo)) {
          totais[qtd.id] = totaisPorQuantidade[qtd.id] ?? 0;
        }

        totaisDistribuicoes.add({
          'numero': distribuicao.numero,
          'titulo': distribuicao.titulo,
          'id': distribuicao.id,
          'totais': totais,
        });
      }
    }

    // Deduplicar por id antes de expor ao widget
    final Set<String> idsTotais = {};
    final List<Map<String, dynamic>> totaisUnicos = [];
    for (final item in totaisDistribuicoes) {
      final id = item['id'] as String?;
      if (id != null && idsTotais.add(id)) {
        totaisUnicos.add(item);
      }
    }

    distribuicoesComTotais = totaisUnicos;
  }

  void _selecionarDistribuicao() async {
    if (distribuicoes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma distribuição disponível para este ano'),
        ),
      );
      return;
    }

    // Se já tem uma distribuição selecionada, voltar para a lista
    if (distribuicaoSelecionada != null) {
      setState(() {
        distribuicaoSelecionada = null;
        alunosPorRegiaoModalidadeQuantidade = {};
        matriculadosPorRegiaoModalidade = {};
      });
      return;
    }

    final resultado = await showDialog<Distribuicao>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Distribuição'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: distribuicoes.map((d) {
              final isSelected = d.id == (distribuicaoSelecionada?.id ?? '');
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Colors.blue,
                ),
                title: Text('Distribuição ${d.numero}'),
                subtitle: Text(d.titulo),
                onTap: () => Navigator.of(context).pop(d),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (resultado != null) {
      setState(() => _carregando = true);

      try {
        final db = FirestoreHelper();
        await _carregarDadosAlunos(db, regioes, resultado.id);
        setState(() {
          distribuicaoSelecionada = resultado;
          _carregando = false;
        });
      } catch (e) {
        setState(() => _carregando = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
        }
      }
    }
  }

  void _selecionarDistribuicaoEspecifica(String distribuicaoId) async {
    setState(() => _carregando = true);

    try {
      final db = FirestoreHelper();
      await _carregarDadosAlunos(db, regioes, distribuicaoId);

      // Encontrar a distribuição pelo ID
      final distribuicao = distribuicoes.firstWhere(
        (d) => d.id == distribuicaoId,
        orElse: () => distribuicoes.first,
      );

      setState(() {
        distribuicaoSelecionada = distribuicao;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  Future<void> _debugDados() async {
    try {
      final db = FirestoreHelper();

      // Buscar dados de uma escola específica para debug
      final escolas = await db.getEscolas();
      if (escolas.isEmpty) {
        _mostrarDialogoDebug('Nenhuma escola encontrada');
        return;
      }

      final escola = escolas.first;

      final dadosEscola = await db.getDadosAlunosPorEscola(escola.id);

      String debugInfo = '=== DEBUG DADOS ===\n\n';
      debugInfo += 'Escola: ${escola.nome}\n';
      debugInfo += 'Regional ID: ${escola.regionalId}\n';
      debugInfo += 'Dados encontrados: ${dadosEscola.length}\n\n';

      for (int i = 0; i < dadosEscola.length; i++) {
        final dados = dadosEscola[i];
        debugInfo += '--- Dados Alunos $i ---\n';
        debugInfo += 'Ano Letivo: ${dados.anoLetivo}\n';
        debugInfo += 'Distribuição ID: ${dados.distribuicaoId}\n';
        debugInfo += 'Modalidades: ${dados.modalidades.keys.join(', ')}\n\n';

        for (final modalidadeEntry in dados.modalidades.entries) {
          final modalidade = modalidadeEntry.key;
          final dadosModalidade = modalidadeEntry.value;

          debugInfo += 'Modalidade: $modalidade\n';
          debugInfo += 'Matriculados: ${dadosModalidade.matriculados}\n';
          debugInfo += 'Tipo  de Refeição:\n';

          for (final qtdEntry in dadosModalidade.quantidadeRefeicoes.entries) {
            debugInfo += '  ${qtdEntry.key}: ${qtdEntry.value} alunos\n';
          }
          debugInfo += '\n';
        }
      }

      // Verificar distribuições
      final distribuicoes = await db.getDistribuicoesPorAno(
        widget.anoLetivo.ano.toString(),
      );
      debugInfo += 'Distribuições do ano ${widget.anoLetivo.ano}:\n';
      for (final dist in distribuicoes) {
        debugInfo += '- ${dist.numero}: ${dist.titulo} (ID: ${dist.id})\n';
      }

      print('Mostrando diálogo com debugInfo');
      _mostrarDialogoDebug(debugInfo);
    } catch (e) {
      print('Erro no debug: $e');
      print(StackTrace.current);
      _mostrarDialogoDebug('Erro ao buscar dados: $e');
    }
  }

  void _mostrarDialogoDebug(String conteudo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug - Dados'),
        content: SingleChildScrollView(
          child: Text(
            conteudo,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ano Letivo ${widget.anoLetivo.ano}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugDados,
            tooltip: 'Debug - Verificar Dados',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informações do ano letivo
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ano Letivo ${widget.anoLetivo.ano}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.anoLetivo.ativo
                                      ? Colors.green[100]
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.anoLetivo.ativo ? 'Ativo' : 'Inativo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.anoLetivo.ativo
                                        ? Colors.green[700]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _InfoChip(
                                icon: Icons.list_alt,
                                label:
                                    '${memoriasCalculo.length} Memórias de Cálculo',
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ações do ano letivo
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: Icon(
                          Icons.local_shipping,
                          color: Colors.teal[700],
                        ),
                      ),
                      title: const Text(
                        'Gerenciar Distribuições',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Crie e gerencie as distribuições deste ano letivo',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DistribuicoesPorAnoScreen(
                              anoLetivo: widget.anoLetivo,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de memórias de cálculo
                  const Text(
                    'Memórias de Cálculo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 400,
                    child: memoriasCalculo.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assessment_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma memória de cálculo criada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Crie a primeira memória de cálculo para começar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: memoriasCalculo.length,
                            itemBuilder: (context, index) {
                              final memoria = memoriasCalculo[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Icon(
                                      Icons.calculate,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  title: Text(memoria.titulo),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Memória de Cálculo ${memoria.numero}',
                                      ),
                                      Text(
                                        '${memoria.produtosSelecionados.length} produtos, ${memoria.modalidadesSelecionadas.length} modalidades',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (memoria.disponibilizadaParaDiae)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.cloud_done,
                                                size: 16,
                                                color: Colors.green[600],
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Disponibilizada para a DIAE',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 20,
                                        ),
                                        tooltip:
                                            'Gerenciar Quadros Técnicos Descritivos',
                                        onPressed: () =>
                                            _abrirGestaoQtd(memoria),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          memoria.disponibilizadaParaDiae
                                              ? Icons.cloud_done
                                              : Icons.cloud_upload,
                                          size: 20,
                                        ),
                                        color: memoria.disponibilizadaParaDiae
                                            ? Colors.green[600]
                                            : Colors.grey[600],
                                        tooltip: memoria
                                                .disponibilizadaParaDiae
                                            ? 'Remover da lista da DIAE'
                                            : 'Disponibilizar para a DIAE',
                                        onPressed: () =>
                                            _alternarDisponibilidadeMemoria(
                                          memoria,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          size: 20,
                                        ),
                                        tooltip:
                                            'Visualizar memória de cálculo',
                                        onPressed: () =>
                                            _visualizarMemoriaCalculo(memoria),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.print, size: 20),
                                        color: Colors.purple,
                                        onPressed: () =>
                                            _gerarPDFsMemoria(memoria),
                                        tooltip: 'Gerar PDFs',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        onPressed: () =>
                                            _configurarMemoriaCalculo(
                                              memoria.numero,
                                            ),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20),
                                        onPressed: () =>
                                            _duplicarMemoriaCalculo(memoria),
                                        tooltip: 'Duplicar',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.assignment_turned_in,
                                          size: 20,
                                        ),
                                        tooltip: 'Ver status dos produtos',
                                        onPressed: () async {
                                          await showDialog(
                                            context: context,
                                            builder: (context) =>
                                                MemoriaCalculoDetailDialog(
                                                  memoria: memoria,
                                                  somenteVisualizacao: true,
                                                ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: () => _gerarPDFsMemoria(memoria),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Dados de alunos por região
                  DadosAlunosRegiaoWidget(
                    anoLetivo: widget.anoLetivo.ano.toString(),
                    distribuicaoSelecionada: distribuicaoSelecionada != null
                        ? 'Distribuição ${distribuicaoSelecionada!.numero}'
                        : null,
                    regioes: regioes,
                    alunosPorRegiaoModalidadeQuantidade:
                        alunosPorRegiaoModalidadeQuantidade,
                    matriculadosPorRegiaoModalidade:
                        matriculadosPorRegiaoModalidade,
                    quantidadesRefeicao: quantidadesRefeicao,
                    onSelecionarDistribuicao: _selecionarDistribuicao,
                    onSelecionarDistribuicaoEspecifica:
                        _selecionarDistribuicaoEspecifica,
                    distribuicoesComTotais: distribuicoesComTotais,
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _adicionarNovaMemoriaCalculo();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Memória de Cálculo'),
      ),
    );
  }

  void _adicionarNovaMemoriaCalculo() {
    final proximoNumero = memoriasCalculo.isEmpty
        ? 1
        : memoriasCalculo.map((d) => d.numero).reduce((a, b) => a > b ? a : b) +
              1;
    _configurarMemoriaCalculo(proximoNumero);
  }

  void _configurarMemoriaCalculo(int numeroMemoriaCalculo) async {
    // Buscar memória anterior (se existir) para copiar frequências
    MemoriaCalculo? memoriaAnterior;
    if (numeroMemoriaCalculo > 1) {
      try {
        memoriaAnterior = memoriasCalculo.firstWhere(
          (m) => m.numero == numeroMemoriaCalculo - 1,
        );
      } catch (e) {
        memoriaAnterior = null;
      }
    }

    // Buscar memória existente (somente se já foi criada)
    MemoriaCalculo? memoriaExistente;
    try {
      memoriaExistente = memoriasCalculo.firstWhere(
        (m) => m.numero == numeroMemoriaCalculo,
      );
    } catch (e) {
      memoriaExistente = null;
    }

    final resultado = await showDialog<MemoriaCalculo>(
      context: context,
      builder: (context) => CriarMemoriaCalculoDialog(
        numeroMemoriaCalculo: numeroMemoriaCalculo,
        produtos: produtos,
        quantidadesRefeicao: quantidadesRefeicao,
        regioes: regioes,
        memoriaAnterior: memoriaAnterior,
        memoriaExistente: memoriaExistente,
        dadosAlunosAtuais: alunosPorRegiaoModalidadeQuantidade,
      ),
    );

    if (resultado != null) {
      try {
        // Exibir loading enquanto salva e recarrega os dados
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Gerando memória de cálculo...'),
              ],
            ),
          ),
        );

        final db = FirestoreHelper();
        final memoriaComAno = resultado.copyWith(
          anoLetivo: widget.anoLetivo.ano.toString(),
        );
        await db.saveMemoriaCalculo(memoriaComAno);
        await _carregarDados();

        // Fechar loading
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Memória de Cálculo ${resultado.numero} configurada com sucesso!',
              ),
            ),
          );
        }
      } catch (e) {
        // Fechar loading em caso de erro
        if (mounted) Navigator.of(context).pop();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao salvar memória: $e')));
        }
      }
    }
  }

  void _abrirGestaoQtd(MemoriaCalculo memoria) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MemoriaCalculoQtdScreen(
              anoLetivo: widget.anoLetivo,
              memoria: memoria,
              produtos: produtos,
              regioes: regioes,
            ),
          ),
        )
        .then((_) => _carregarDados());
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

        // Buscar regionais desta região
        final regionaisNomes = <String>[];
        for (final regional in regiao.regionais) {
          regionaisNomes.add(regional.nome);
        }
        regionaisPorRegiao[regiao.id] = regionaisNomes;
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

        // Buscar frequências do domínio GPAE para esta modalidade
        final frequencias =
            memoria.frequenciaByDomain['gpae']?[modalidadeName] ??
            memoria.frequenciaPorModalidadeQuantidade[modalidadeName] ??
            {};

        // Criar dados específicos para esta modalidade usando dados congelados
        final Map<String, Map<String, int>>
        alunosPorRegiaoModalidadeEspecifica = {};

        for (final regiaoId in memoria.regioesSelecionadas) {
          alunosPorRegiaoModalidadeEspecifica[regiaoId] = {};

          // Inicializar com zero para cada Tipo de refeição ativa
          for (final qtd in quantidadesRefeicao.where((q) => q.ativo)) {
            alunosPorRegiaoModalidadeEspecifica[regiaoId]![qtd.id] = 0;
          }

          // Usar dados congelados da memória (se disponíveis)
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
      // Agregar alunos por região somando todas as modalidades selecionadas
      final Map<String, Map<String, int>> alunosPorRegiaoTotais = {};
      for (final regiaoId in memoria.regioesSelecionadas) {
        alunosPorRegiaoTotais[regiaoId] = {};
        for (final qtd in quantidadesRefeicao.where((q) => q.ativo)) {
          alunosPorRegiaoTotais[regiaoId]![qtd.id] = 0;
        }

        final dadosRegiao = memoria.dadosAlunosCongelados[regiaoId];
        if (dadosRegiao != null) {
          for (final entryModalidade in dadosRegiao.entries) {
            final mapaQtd = entryModalidade.value; // Map<String,int>
            for (final qtdEntry in mapaQtd.entries) {
              final qtdId = qtdEntry.key;
              final qtdAlunos = qtdEntry.value;
              if (alunosPorRegiaoTotais[regiaoId]!.containsKey(qtdId)) {
                alunosPorRegiaoTotais[regiaoId]![qtdId] =
                    (alunosPorRegiaoTotais[regiaoId]![qtdId] ?? 0) + qtdAlunos;
              }
            }
          }
        }
      }

      // Frequências globais: usa a primeira modalidade selecionada como referência
      Map<String, double> frequenciasGlobais = {};
      if (memoria.modalidadesSelecionadas.isNotEmpty) {
        final primeira = memoria.modalidadesSelecionadas.first;
        frequenciasGlobais =
            memoria.frequenciaByDomain['gpae']?[primeira] ??
            memoria.frequenciaPorModalidadeQuantidade[primeira] ??
            {};
      }
      final excelConsolidado =
          await ExcelGenerator.generateConsolidadoMemoriaCalculo(
            anoLetivo: memoria.anoLetivo,
            numeroMemoria: memoria.numero,
            titulo: memoria.titulo,
            regioesSelecionadas: memoria.regioesSelecionadas,
            regioesNomes: regioesNomes,
            alunosPorRegiaoModalidade: memoria.dadosAlunosCongelados,
            frequencias: frequenciasGlobais,
            frequenciasPorProduto: memoria.frequenciaPorProduto,
            quantidadesRefeicao: quantidadesRefeicao,
            produtosSelecionados: produtosSelecionados,
          );

      relatoriosGerados.add({
        'modalidade': 'CONSOLIDADO 1 EXCEL',
        'bytes': excelConsolidado,
        'fileName': 'MemoriaCalculo_${memoria.numero}_Consolidado_1.xlsx',
      });

      // Fechar loading
      if (mounted) Navigator.of(context).pop();

      // Fazer download dos PDFs e Excel
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
      // Fechar loading se estiver aberto
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
      debugPrint('Erro ao fazer download do arquivo: $e');
    }
  }

  Future<void> _duplicarMemoriaCalculo(MemoriaCalculo origem) async {
    final tituloController = TextEditingController(
      text: '${origem.titulo} (cópia)',
    );

    final novoTitulo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicar Memória de Cálculo'),
        content: TextField(
          controller: tituloController,
          decoration: const InputDecoration(
            labelText: 'Novo título',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).pop(tituloController.text.trim()),
            child: const Text('Duplicar'),
          ),
        ],
      ),
    );

    if (novoTitulo == null || novoTitulo.isEmpty) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Duplicando memória de cálculo...'),
            ],
          ),
        ),
      );

      final proximoNumero = memoriasCalculo.isEmpty
          ? 1
          : memoriasCalculo
                    .map((d) => d.numero)
                    .reduce((a, b) => a > b ? a : b) +
                1;

      final copia = origem.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        numero: proximoNumero,
        titulo: novoTitulo,
        dataCriacao: DateTime.now(),
        disponibilizadaParaDiae: false,
      );

      final db = FirestoreHelper();
      await db.saveMemoriaCalculo(copia);
      await _carregarDados();

      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Memória ${copia.numero} criada a partir da ${origem.numero}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao duplicar memória: $e')));
      }
    }
  }

  Future<void> _alternarDisponibilidadeMemoria(
    MemoriaCalculo memoria,
  ) async {
    final novoValor = !memoria.disponibilizadaParaDiae;
    try {
      final Map<String, StatusProdutoMemoria> statusAtualizados = {
        ...memoria.statusProdutos,
      };

      if (novoValor) {
        for (final produtoId in memoria.produtosSelecionados) {
          statusAtualizados.putIfAbsent(
            produtoId,
            () => StatusProdutoMemoria.emAquisicao,
          );
        }
      }

      final db = FirestoreHelper();
      final memoriaAtualizada = memoria.copyWith(
        disponibilizadaParaDiae: novoValor,
        statusProdutos: statusAtualizados,
      );
      await db.saveMemoriaCalculo(memoriaAtualizada);

      if (!mounted) return;

      setState(() {
        memoriasCalculo = memoriasCalculo
            .map(
              (m) => m.id == memoria.id
                  ? m.copyWith(
                      disponibilizadaParaDiae: novoValor,
                      statusProdutos: statusAtualizados,
                    )
                  : m,
            )
            .toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoValor
                ? 'Memória disponibilizada para a DIAE.'
                : 'Memória removida da lista da DIAE.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar disponibilidade: $e')),
      );
    }
  }

  void _visualizarMemoriaCalculo(MemoriaCalculo memoria) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Visualização da Memória ${memoria.numero} estará disponível em breve.',
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
