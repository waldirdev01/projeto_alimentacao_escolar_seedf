// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/quantidade_refeicao.dart';
import 'widgets/criar_quantidade_refeicao_dialog.dart';
import 'widgets/editar_quantidade_refeicao_dialog.dart';

class QuantidadesRefeicaoScreen extends StatefulWidget {
  const QuantidadesRefeicaoScreen({super.key});

  @override
  State<QuantidadesRefeicaoScreen> createState() =>
      _QuantidadesRefeicaoScreenState();
}

class _QuantidadesRefeicaoScreenState extends State<QuantidadesRefeicaoScreen> {
  List<QuantidadeRefeicao> quantidadesRefeicao = [];
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
      final quantidadesDb = await firestore.getQuantidadesRefeicao();

      setState(() {
        quantidadesRefeicao = quantidadesDb;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    }
  }

  void _criarQuantidadeRefeicao() async {
    final resultado = await showDialog<QuantidadeRefeicao>(
      context: context,
      builder: (context) => const CriarQuantidadeRefeicaoDialog(),
    );

    if (resultado != null) {
      try {
        final firestore = FirestoreHelper();
        await firestore.saveQuantidadeRefeicao(resultado);
        await _carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de refeição criada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar quantidade: $e')));
      }
    }
  }

  void _editarQuantidadeRefeicao(QuantidadeRefeicao quantidade) async {
    final resultado = await showDialog<QuantidadeRefeicao>(
      context: context,
      builder: (context) =>
          EditarQuantidadeRefeicaoDialog(quantidade: quantidade),
    );

    if (resultado != null) {
      try {
        final firestore = FirestoreHelper();
        await firestore.updateQuantidadeRefeicao(resultado);
        await _carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tipo de refeição atualizada com sucesso!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar quantidade: $e')),
        );
      }
    }
  }

  void _alternarStatus(QuantidadeRefeicao quantidade) async {
    try {
      final firestore = FirestoreHelper();
      final quantidadeAtualizada = quantidade.copyWith(
        ativo: !quantidade.ativo,
      );
      await firestore.updateQuantidadeRefeicao(quantidadeAtualizada);
      await _carregarDados();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quantidade.ativo
                ? 'Tipo de refeição desativada'
                : 'Tipo de refeição ativada',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao alterar status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantidades de Refeição'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _criarQuantidadeRefeicao,
            tooltip: 'Criar nova Tipo de refeição',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : quantidadesRefeicao.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma Tipo de refeição cadastrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _criarQuantidadeRefeicao,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar primeira quantidade'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quantidadesRefeicao.length,
              itemBuilder: (context, index) {
                final quantidade = quantidadesRefeicao[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: quantidade.ativo
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1)
                          : Colors.grey[100],
                      child: Icon(
                        Icons.restaurant,
                        color: quantidade.ativo
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[400],
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          quantidade.sigla,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (!quantidade.ativo)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Inativo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(quantidade.nome),
                        Text(
                          quantidade.descricao,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: quantidade.ativo,
                          onChanged: (value) => _alternarStatus(quantidade),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') {
                              _editarQuantidadeRefeicao(quantidade);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
