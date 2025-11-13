import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/firestore_helper.dart';
import '../../models/fonte_pagamento.dart';
import 'widgets/fonte_pagamento_form_dialog.dart';

enum FiltroFonte { ativas, inativas, todas }

class FontesPagamentoManagementScreen extends StatefulWidget {
  const FontesPagamentoManagementScreen({super.key});

  @override
  State<FontesPagamentoManagementScreen> createState() =>
      _FontesPagamentoManagementScreenState();
}

class _FontesPagamentoManagementScreenState
    extends State<FontesPagamentoManagementScreen> {
  final List<FontePagamento> _fontes = [];
  final TextEditingController _searchController = TextEditingController();
  FiltroFonte _filtro = FiltroFonte.ativas;
  bool _carregando = true;
  String _busca = '';

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _busca = _searchController.text.toLowerCase().trim();
      });
    });
    _carregarFontes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarFontes() async {
    setState(() {
      _carregando = true;
    });

    try {
      final db = FirestoreHelper();
      final lista = await db.getFontesPagamento();
      lista.sort((a, b) => a.nome.compareTo(b.nome));
      setState(() {
        _fontes
          ..clear()
          ..addAll(lista);
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar fontes: $e')),
      );
    }
  }

  Future<void> _criarFonte() async {
    final resultado = await showDialog<FontePagamento>(
      context: context,
      builder: (_) => const FontePagamentoFormDialog(),
    );
    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.saveFontePagamento(resultado);
        await _carregarFontes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonte cadastrada com sucesso!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar fonte: $e')),
        );
      }
    }
  }

  Future<void> _editarFonte(FontePagamento fonte) async {
    final resultado = await showDialog<FontePagamento>(
      context: context,
      builder: (_) => FontePagamentoFormDialog(fonte: fonte),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.updateFontePagamento(resultado);
        await _carregarFontes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonte atualizada com sucesso!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar fonte: $e')),
        );
      }
    }
  }

  Future<void> _toggleStatus(FontePagamento fonte) async {
    try {
      final db = FirestoreHelper();
      await db.toggleFontePagamentoStatus(fonte.id, !fonte.ativo);
      await _carregarFontes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fonte.ativo
                  ? 'Fonte desativada com sucesso!'
                  : 'Fonte ativada com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar status: $e')),
      );
    }
  }

  Future<void> _deletarFonte(FontePagamento fonte) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a fonte "${fonte.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        final db = FirestoreHelper();
        await db.deleteFontePagamento(fonte.id);
        await _carregarFontes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonte excluída com sucesso!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir fonte: $e')),
        );
      }
    }
  }

  List<FontePagamento> get _fontesFiltradas {
    var filtradas = _fontes.where((fonte) {
      final matchBusca = _busca.isEmpty ||
          fonte.nome.toLowerCase().contains(_busca) ||
          fonte.observacao.toLowerCase().contains(_busca);
      if (!matchBusca) return false;

      switch (_filtro) {
        case FiltroFonte.ativas:
          return fonte.ativo;
        case FiltroFonte.inativas:
          return !fonte.ativo;
        case FiltroFonte.todas:
          return true;
      }
    }).toList();

    return filtradas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Fontes de Pagamento'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar fonte',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SegmentedButton<FiltroFonte>(
                      segments: const [
                        ButtonSegment(
                          value: FiltroFonte.ativas,
                          label: Text('Ativas'),
                        ),
                        ButtonSegment(
                          value: FiltroFonte.inativas,
                          label: Text('Inativas'),
                        ),
                        ButtonSegment(
                          value: FiltroFonte.todas,
                          label: Text('Todas'),
                        ),
                      ],
                      selected: {_filtro},
                      onSelectionChanged: (Set<FiltroFonte> novo) {
                        setState(() {
                          _filtro = novo.first;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _fontesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _busca.isEmpty
                                  ? 'Nenhuma fonte cadastrada'
                                  : 'Nenhuma fonte encontrada',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _fontesFiltradas.length,
                        itemBuilder: (context, index) {
                          final fonte = _fontesFiltradas[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: fonte.ativo
                                    ? Colors.green[100]
                                    : Colors.grey[300],
                                child: Icon(
                                  Icons.payment,
                                  color: fonte.ativo
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                ),
                              ),
                              title: Text(
                                fonte.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: fonte.ativo
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (fonte.observacao.isNotEmpty)
                                    Text(
                                      fonte.observacao,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Valor: ${_currencyFormat.format(fonte.valor)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      fonte.ativo
                                          ? Icons.toggle_on
                                          : Icons.toggle_off,
                                      ),
                                    color: fonte.ativo ? Colors.green : Colors.grey,
                                    onPressed: () => _toggleStatus(fonte),
                                    tooltip: fonte.ativo
                                        ? 'Desativar'
                                        : 'Ativar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editarFonte(fonte),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () => _deletarFonte(fonte),
                                    tooltip: 'Excluir',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarFonte,
        icon: const Icon(Icons.add),
        label: const Text('Nova Fonte'),
      ),
    );
  }
}

