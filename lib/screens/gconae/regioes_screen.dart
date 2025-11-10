import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/regiao.dart';
import 'widgets/criar_regional_dialog.dart';
import 'widgets/mover_regional_dialog.dart';

class RegioesScreen extends StatefulWidget {
  const RegioesScreen({super.key});

  @override
  State<RegioesScreen> createState() => _RegioesScreenState();
}

class _RegioesScreenState extends State<RegioesScreen> {
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
      final firestore = FirestoreHelper();
      final regioesDb = await firestore.getRegioes();

      setState(() {
        regioes = regioesDb;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  void _criarNovaRegional() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CriarRegionalDialog(regioes: regioes),
    );

    if (resultado != null) {
      try {
        final regiaoId = resultado['regiaoId'] as String;
        final regional = resultado['regional'] as Regional;

        final index = regioes.indexWhere((r) => r.id == regiaoId);
        if (index != -1) {
          final novasRegionais = [...regioes[index].regionais, regional];
          final regiaoAtualizada =
              regioes[index].copyWith(regionais: novasRegionais);

          final firestore = FirestoreHelper();
          await firestore.saveRegiao(regiaoAtualizada);
          await _carregarDados();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Regional criada com sucesso!')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar regional: $e')),
          );
        }
      }
    }
  }

  void _moverRegional(Regional regional, String regiaoAtualId) async {
    final resultado = await showDialog<String>(
      context: context,
      builder: (context) => MoverRegionalDialog(
        regional: regional,
        regioes: regioes,
        regiaoAtualId: regiaoAtualId,
      ),
    );

    if (resultado != null) {
      try {
        final regioesAtualizadas = List<Regiao>.from(regioes);

        // Remover da região atual
        final indexAtual = regioesAtualizadas.indexWhere((r) => r.id == regiaoAtualId);
        if (indexAtual != -1) {
          final regionaisAtualizadas = regioesAtualizadas[indexAtual].regionais
              .where((r) => r.id != regional.id)
              .toList();
          regioesAtualizadas[indexAtual] = regioesAtualizadas[indexAtual].copyWith(
            regionais: regionaisAtualizadas,
          );
        }

        // Adicionar na nova região
        final indexNova = regioesAtualizadas.indexWhere((r) => r.id == resultado);
        if (indexNova != -1) {
          final novasRegionais = [...regioesAtualizadas[indexNova].regionais, regional];
          regioesAtualizadas[indexNova] = regioesAtualizadas[indexNova].copyWith(
            regionais: novasRegionais,
          );
        }

        final firestore = FirestoreHelper();
        await firestore.updateRegioes(regioesAtualizadas);
        await _carregarDados();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Regional movida com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao mover regional: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regiões e Regionais'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            onPressed: _criarNovaRegional,
            tooltip: 'Criar nova regional',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: regioes.length,
              itemBuilder: (context, index) {
                final regiao = regioes[index];
                return _RegiaoCard(
                  regiao: regiao,
            onMoverRegional: (regional) => _moverRegional(regional, regiao.id),
          );
        },
      ),
    );
  }
}

class _RegiaoCard extends StatelessWidget {
  final Regiao regiao;
  final Function(Regional) onMoverRegional;

  const _RegiaoCard({required this.regiao, required this.onMoverRegional});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${regiao.numero}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        regiao.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${regiao.regionais.length} ${regiao.regionais.length == 1 ? "regional" : "regionais"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: regiao.regionais.map((regional) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.school,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      regional.sigla,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      regional.nome,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'mover') {
                          onMoverRegional(regional);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'mover',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz, size: 20),
                              SizedBox(width: 8),
                              Text('Mover para outra região'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
