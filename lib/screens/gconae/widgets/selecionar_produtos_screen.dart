import 'package:flutter/material.dart';

import '../../../models/produto.dart';

class SelecionarProdutosScreen extends StatefulWidget {
  final List<Produto> todosProdutos;
  final List<String> produtosJaSelecionados;

  const SelecionarProdutosScreen({
    super.key,
    required this.todosProdutos,
    required this.produtosJaSelecionados,
  });

  @override
  State<SelecionarProdutosScreen> createState() =>
      _SelecionarProdutosScreenState();
}

class _SelecionarProdutosScreenState extends State<SelecionarProdutosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TipoProduto? _filtroTipo;
  late Set<String> _produtosSelecionados;

  @override
  void initState() {
    super.initState();
    _produtosSelecionados = Set.from(widget.produtosJaSelecionados);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Produto> get _produtosFiltrados {
    var filtrados = widget.todosProdutos;

    // Filtro por tipo
    if (_filtroTipo != null) {
      filtrados = filtrados.where((p) => p.tipo == _filtroTipo).toList();
    }

    // Filtro por pesquisa
    if (_searchQuery.isNotEmpty) {
      filtrados = filtrados.where((p) {
        return p.nome.toLowerCase().contains(_searchQuery) ||
            (p.fabricante?.toLowerCase().contains(_searchQuery) ?? false) ||
            (p.distribuidor?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filtrados;
  }

  void _confirmar() {
    Navigator.of(context).pop(_produtosSelecionados.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selecionar Produtos (${_produtosSelecionados.length})'),
        actions: [
          TextButton.icon(
            onPressed: _confirmar,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar produtos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // Filtros de Tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Tipo:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SegmentedButton<TipoProduto?>(
                    segments: const [
                      ButtonSegment<TipoProduto?>(
                        value: null,
                        label: Text('Todos'),
                        icon: Icon(Icons.all_inclusive, size: 16),
                      ),
                      ButtonSegment<TipoProduto?>(
                        value: TipoProduto.naoPerecivel,
                        label: Text('Não Perecíveis'),
                        icon: Icon(Icons.inventory_2, size: 16),
                      ),
                      ButtonSegment<TipoProduto?>(
                        value: TipoProduto.perecivel,
                        label: Text('Semiperecíveis'),
                        icon: Icon(Icons.local_grocery_store, size: 16),
                      ),
                    ],
                    selected: {_filtroTipo},
                    onSelectionChanged: (Set<TipoProduto?> newSelection) {
                      setState(() {
                        _filtroTipo = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de Produtos
          Expanded(
            child: _produtosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum produto encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _produtosFiltrados.length,
                    itemBuilder: (context, index) {
                      final produto = _produtosFiltrados[index];
                      final selecionado = _produtosSelecionados.contains(
                        produto.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: selecionado,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _produtosSelecionados.add(produto.id);
                              } else {
                                _produtosSelecionados.remove(produto.id);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor:
                                produto.tipo == TipoProduto.naoPerecivel
                                ? Colors.blue[100]
                                : Colors.green[100],
                            child: Icon(
                              produto.tipo == TipoProduto.naoPerecivel
                                  ? Icons.inventory_2
                                  : Icons.local_grocery_store,
                              color: produto.tipo == TipoProduto.naoPerecivel
                                  ? Colors.blue[700]
                                  : Colors.green[700],
                            ),
                          ),
                          title: Text(
                            produto.nome,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (produto.fabricante != null)
                                Text(
                                  'Fabricante: ${produto.fabricante}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (produto.distribuidor != null)
                                Text(
                                  'Distribuidor: ${produto.distribuidor}',
                                  style: const TextStyle(fontSize: 12),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${_produtosSelecionados.length} produto(s) selecionado(s)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _confirmar,
              icon: const Icon(Icons.check),
              label: const Text('Confirmar Seleção'),
            ),
          ],
        ),
      ),
    );
  }
}
