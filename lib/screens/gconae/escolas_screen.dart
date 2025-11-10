// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../data/regioes_data.dart';
import '../../database/firestore_helper.dart';
import '../../models/escola.dart';
import '../../models/regiao.dart';
import 'widgets/criar_escola_dialog.dart';

class EscolasScreen extends StatefulWidget {
  const EscolasScreen({super.key});

  @override
  State<EscolasScreen> createState() => _EscolasScreenState();
}

class _EscolasScreenState extends State<EscolasScreen> {
  List<Escola> escolas = [];
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
      final escolasDb = await db.getEscolas();
      final regioesDb = RegioesData.getRegioesIniciais();

      setState(() {
        escolas = escolasDb;
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

  void _criarEscola() async {
    final resultado = await showDialog<Escola>(
      context: context,
      builder: (context) => CriarEscolaDialog(regioes: regioes),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.saveEscola(resultado);
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Escola criada com sucesso!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao criar escola: $e')));
        }
      }
    }
  }

  void _excluirEscola(Escola escola) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Escola'),
        content: Text(
          'Tem certeza que deseja excluir a escola "${escola.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final db = FirestoreHelper();
                await db.deleteEscola(escola.id);
                await _carregarDados();
                if (mounted) {
                  Navigator.of(context).pop(true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Escola excluída!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao excluir escola: $e')),
                  );
                }
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  String _getNomeRegional(String regionalId) {
    for (final regiao in regioes) {
      for (final regional in regiao.regionais) {
        if (regional.id == regionalId) {
          return regional.nome;
        }
      }
    }
    return 'Regional não encontrada';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : escolas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma escola cadastrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _criarEscola,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar primeira escola'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Filtros e estatísticas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total de Escolas: ${escolas.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Escolas Ativas: ${escolas.where((e) => e.ativo).length}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.school,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                // Lista de escolas
                Expanded(
                  child: ListView.builder(
                    itemCount: escolas.length,
                    itemBuilder: (context, index) {
                      final escola = escolas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: escola.ativo
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.1)
                                : Colors.grey[100],
                            child: Icon(
                              Icons.school,
                              color: escola.ativo
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[600],
                            ),
                          ),
                          title: Text(
                            escola.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: escola.ativo ? null : Colors.grey[600],
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Código: ${escola.codigo}'),
                              Text(
                                'Regional: ${_getNomeRegional(escola.regionalId)}',
                              ),
                              Row(
                                children: [
                                  Icon(
                                    escola.ativo
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    size: 16,
                                    color: escola.ativo
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    escola.ativo ? 'Ativa' : 'Inativa',
                                    style: TextStyle(
                                      color: escola.ativo
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'excluir') {
                                _excluirEscola(escola);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Detalhes de ${escola.nome}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarEscola,
        icon: const Icon(Icons.add),
        label: const Text('Nova Escola'),
      ),
    );
  }
}
