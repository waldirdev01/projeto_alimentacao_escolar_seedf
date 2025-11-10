import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/memoria_calculo.dart';
import '../../models/processo_aquisicao.dart';
import 'widgets/criar_processo_aquisicao_dialog.dart';
import 'widgets/processo_aquisicao_detail_dialog.dart';

class ProcessosAquisicaoScreen extends StatefulWidget {
  const ProcessosAquisicaoScreen({super.key});

  @override
  State<ProcessosAquisicaoScreen> createState() =>
      _ProcessosAquisicaoScreenState();
}

class _ProcessosAquisicaoScreenState extends State<ProcessosAquisicaoScreen> {
  List<AnoLetivo> anosLetivos = [];
  Map<String, List<ProcessoAquisicao>> processosPorAno = {};
  Map<String, List<MemoriaCalculo>> memoriasPorAno = {};
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
      final todosProcessos = await db.getProcessosAquisicao();

      // Agrupar memórias por ano
      final Map<String, List<MemoriaCalculo>> memoriasAgrupadas = {};
      for (final memoria in todasMemorias) {
        if (!memoriasAgrupadas.containsKey(memoria.anoLetivo)) {
          memoriasAgrupadas[memoria.anoLetivo] = [];
        }
        memoriasAgrupadas[memoria.anoLetivo]!.add(memoria);
      }

      // Agrupar processos por ano
      final Map<String, List<ProcessoAquisicao>> processosAgrupados = {};
      for (final processo in todosProcessos) {
        if (!processosAgrupados.containsKey(processo.anoLetivo)) {
          processosAgrupados[processo.anoLetivo] = [];
        }
        processosAgrupados[processo.anoLetivo]!.add(processo);
      }

      // Ordenar processos por data de criação
      for (final lista in processosAgrupados.values) {
        lista.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      }

      setState(() {
        anosLetivos = anosDb;
        memoriasPorAno = memoriasAgrupadas;
        processosPorAno = processosAgrupados;
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

  void _criarProcessoAquisicao(String anoLetivo) async {
    final memorias = memoriasPorAno[anoLetivo] ?? [];
    if (memorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma memória de cálculo disponível para este ano'),
        ),
      );
      return;
    }

    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => CriarProcessoAquisicaoDialog(
        anoLetivo: anoLetivo,
        memoriasDisponiveis: memorias,
      ),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  void _abrirDetalhesProcesso(ProcessoAquisicao processo) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => ProcessoAquisicaoDetailDialog(processo: processo),
    );

    if (resultado == true) {
      _carregarDados();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processos de Aquisição'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
            tooltip: 'Atualizar',
          ),
        ],
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
                final processos = processosPorAno[ano.ano.toString()] ?? [];
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
                      '${processos.length} processo(s) de aquisição • ${memorias.length} memória(s) de cálculo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () =>
                              _criarProcessoAquisicao(ano.ano.toString()),
                          tooltip: 'Criar Processo',
                        ),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                    children: processos.isEmpty
                        ? [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Nenhum processo de aquisição cadastrado',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ]
                        : processos.map((processo) {
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCorFase(
                                  processo.faseAtual,
                                ),
                                child: Icon(
                                  _getIconeFase(processo.faseAtual),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(processo.titulo),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fase: ${processo.faseAtual.displayName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (processo.observacoes != null &&
                                      processo.observacoes!.isNotEmpty)
                                    Text(
                                      'Obs: ${processo.observacoes!.length > 50 ? '${processo.observacoes!.substring(0, 50)}...' : processo.observacoes!}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCorStatus(processo.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      processo.status.displayName,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                              onTap: () => _abrirDetalhesProcesso(processo),
                            );
                          }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Color _getCorFase(FaseProcessoAquisicao fase) {
    switch (fase) {
      case FaseProcessoAquisicao.processoIniciado:
        return Colors.blue;
      case FaseProcessoAquisicao.editalPublicado:
        return Colors.orange;
      case FaseProcessoAquisicao.analisePropostas:
        return Colors.purple;
      case FaseProcessoAquisicao.resultadoFinal:
        return Colors.indigo;
      case FaseProcessoAquisicao.publicado:
        return Colors.green;
    }
  }

  IconData _getIconeFase(FaseProcessoAquisicao fase) {
    switch (fase) {
      case FaseProcessoAquisicao.processoIniciado:
        return Icons.play_arrow;
      case FaseProcessoAquisicao.editalPublicado:
        return Icons.publish;
      case FaseProcessoAquisicao.analisePropostas:
        return Icons.analytics;
      case FaseProcessoAquisicao.resultadoFinal:
        return Icons.assessment;
      case FaseProcessoAquisicao.publicado:
        return Icons.check_circle;
    }
  }

  Color _getCorStatus(StatusProcessoAquisicao status) {
    switch (status) {
      case StatusProcessoAquisicao.ativo:
        return Colors.blue;
      case StatusProcessoAquisicao.concluido:
        return Colors.green;
      case StatusProcessoAquisicao.cancelado:
        return Colors.red;
    }
  }
}
