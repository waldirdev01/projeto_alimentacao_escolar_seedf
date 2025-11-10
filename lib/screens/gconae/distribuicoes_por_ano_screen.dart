import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/distribuicao.dart';
import '../../models/escola.dart';
import '../../models/etapa_distribuicao.dart';
import '../diae/widgets/criar_distribuicao_dialog.dart';
import '../diae/widgets/gerenciar_etapas_dialog.dart';

class DistribuicoesPorAnoScreen extends StatefulWidget {
  final AnoLetivo anoLetivo;

  const DistribuicoesPorAnoScreen({super.key, required this.anoLetivo});

  @override
  State<DistribuicoesPorAnoScreen> createState() =>
      _DistribuicoesPorAnoScreenState();
}

class _DistribuicoesPorAnoScreenState extends State<DistribuicoesPorAnoScreen> {
  List<Distribuicao> distribuicoes = [];
  List<Escola> escolas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    try {
      final db = FirestoreHelper();
      final distribuicoesDb = await db.getDistribuicoesPorAno(
        widget.anoLetivo.ano.toString(),
      );
      final escolasDb = await db.getEscolas();
      setState(() {
        distribuicoes = distribuicoesDb
          ..sort((a, b) => b.numero.compareTo(a.numero));
        escolas = escolasDb;
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

  Future<void> _criarNovaDistribuicao() async {
    final resultado = await showDialog<Distribuicao>(
      context: context,
      builder: (context) => CriarDistribuicaoDialog(
        anosLetivos: [widget.anoLetivo],
        distribuicaoExistente: null,
      ),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.saveDistribuicao(resultado);
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Distribuição ${resultado.numero}/${resultado.anoLetivo} criada!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar distribuição: $e')),
          );
        }
      }
    }
  }

  Future<void> _editarDistribuicao(Distribuicao distribuicao) async {
    final resultado = await showDialog<Distribuicao>(
      context: context,
      builder: (context) => CriarDistribuicaoDialog(
        anosLetivos: [widget.anoLetivo],
        distribuicaoExistente: distribuicao,
      ),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.updateDistribuicao(resultado);
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Distribuição ${resultado.numero}/${resultado.anoLetivo} atualizada!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar distribuição: $e')),
          );
        }
      }
    }
  }

  Future<void> _alternarLiberacao(Distribuicao distribuicao) async {
    final novoStatus = !distribuicao.isLiberadaParaEscolas;
    final distribuicaoAtualizada = distribuicao.copyWith(
      status: novoStatus
          ? StatusDistribuicao.liberada
          : StatusDistribuicao.planejada,
      dataLiberacao: novoStatus ? DateTime.now() : null,
    );

    try {
      final db = FirestoreHelper();
      await db.updateDistribuicao(distribuicaoAtualizada);
      await _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              novoStatus
                  ? 'Distribuição ${distribuicao.numero} liberada para escolas!'
                  : 'Distribuição ${distribuicao.numero} bloqueada!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao alterar status: $e')));
      }
    }
  }

  void _gerenciarEtapas(Distribuicao distribuicao) async {
    final etapasAtualizadas = await showDialog<List<EtapaDistribuicao>>(
      context: context,
      builder: (context) => GerenciarEtapasDialog(
        etapasExistentes: distribuicao.etapas,
        distribuicaoId: distribuicao.id,
      ),
    );

    if (etapasAtualizadas != null) {
      try {
        final db = FirestoreHelper();
        final distribuicaoAtualizada = distribuicao.copyWith(
          etapas: etapasAtualizadas,
        );
        await db.updateDistribuicao(distribuicaoAtualizada);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Etapas atualizadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _carregarDados();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar etapas: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar Distribuições ${widget.anoLetivo.ano}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distribuições de Alimentação Escolar',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gerencie as distribuições do ano ${widget.anoLetivo.ano}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Lista de Distribuições',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: distribuicoes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma distribuição criada para ${widget.anoLetivo.ano}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Crie a primeira distribuição',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: distribuicoes.length,
                            itemBuilder: (context, index) {
                              final dist = distribuicoes[index];
                              final escolasEnviaram =
                                  dist.escolasQueEnviaramDados.length;
                              final percentual = escolas.isNotEmpty
                                  ? (escolasEnviaram / escolas.length * 100)
                                  : 0.0;
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: dist.isLiberadaParaEscolas
                                        ? Colors.green[100]
                                        : Colors.grey[200],
                                    child: Icon(
                                      dist.isLiberadaParaEscolas
                                          ? Icons.lock_open
                                          : Icons.lock,
                                      color: dist.isLiberadaParaEscolas
                                          ? Colors.green[700]
                                          : Colors.grey[700],
                                    ),
                                  ),
                                  title: Text(
                                    'Distribuição ${dist.numero}/${dist.anoLetivo}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(dist.titulo),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: dist.isLiberadaParaEscolas
                                                  ? Colors.green[100]
                                                  : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              dist.isLiberadaParaEscolas
                                                  ? 'Liberada'
                                                  : 'Bloqueada',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    dist.isLiberadaParaEscolas
                                                    ? Colors.green[700]
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$escolasEnviaram/${escolas.length} escolas (${percentual.toStringAsFixed(0)}%)',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Período: ${dist.periodoTexto}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _editarDistribuicao(dist),
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 18,
                                              ),
                                              label: const Text('Editar'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _alternarLiberacao(dist),
                                              icon: Icon(
                                                dist.isLiberadaParaEscolas
                                                    ? Icons.lock
                                                    : Icons.lock_open,
                                                size: 18,
                                              ),
                                              label: Text(
                                                dist.isLiberadaParaEscolas
                                                    ? 'Bloquear'
                                                    : 'Liberar',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    dist.isLiberadaParaEscolas
                                                    ? Colors.orange
                                                    : Colors.green,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _gerenciarEtapas(dist),
                                              icon: const Icon(
                                                Icons.assignment_turned_in,
                                                size: 18,
                                              ),
                                              label: const Text('Etapas'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarNovaDistribuicao,
        icon: const Icon(Icons.add),
        label: const Text('Nova Distribuição'),
      ),
    );
  }
}
