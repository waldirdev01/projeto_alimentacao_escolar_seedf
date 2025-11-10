// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/produto.dart';
import '../../models/quantidade_refeicao.dart';
import 'widgets/criar_produto_dialog.dart';
import 'widgets/editar_produto_dialog.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  List<Produto> produtos = [];
  List<QuantidadeRefeicao> quantidadesRefeicao = [];
  TipoProduto _filtroTipo = TipoProduto.naoPerecivel;
  bool _carregando = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
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

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
    });

    try {
      final db = FirestoreHelper();
      final produtosDb = await db.getProdutos();
      final quantidadesDb = await db.getQuantidadesRefeicao();

      setState(() {
        produtos = produtosDb;
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

  void _criarProduto() async {
    final resultado = await showDialog<Produto>(
      context: context,
      builder: (context) => CriarProdutoDialog(
        quantidadesRefeicao: quantidadesRefeicao,
        produtosExistentes: produtos,
      ),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.saveProduto(resultado);
        await _carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto criado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar produto: $e')));
      }
    }
  }

  void _editarProduto(Produto produto) async {
    final resultado = await showDialog<Produto>(
      context: context,
      builder: (context) => EditarProdutoDialog(
        produto: produto,
        quantidadesRefeicao: quantidadesRefeicao,
      ),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.updateProduto(resultado);
        await _carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto atualizado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar produto: $e')),
        );
      }
    }
  }

  void _excluirProduto(Produto produto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Produto'),
        content: Text('Deseja excluir o produto "${produto.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final db = FirestoreHelper();
                await db.deleteProduto(produto.id);
                await _carregarDados();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produto excluído!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir produto: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  List<Produto> get _produtosFiltrados {
    var filtrados = produtos.where((p) => p.tipo == _filtroTipo).toList();

    if (_searchQuery.isNotEmpty) {
      filtrados = filtrados.where((p) {
        return p.nome.toLowerCase().contains(_searchQuery) ||
            (p.fabricante?.toLowerCase().contains(_searchQuery) ?? false) ||
            (p.distribuidor?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    return filtrados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Produtos para Aquisição'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _criarProduto,
            tooltip: 'Criar novo produto',
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
                hintText: 'Pesquisar por nome, fabricante ou distribuidor...',
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
                  child: SegmentedButton<TipoProduto>(
                    segments: const [
                      ButtonSegment<TipoProduto>(
                        value: TipoProduto.naoPerecivel,
                        label: Text('Perecíveis'),
                        icon: Icon(Icons.inventory_2),
                      ),
                      ButtonSegment<TipoProduto>(
                        value: TipoProduto.perecivel,
                        label: Text('Semiperecíveis'),
                        icon: Icon(Icons.local_grocery_store),
                      ),
                    ],
                    selected: {_filtroTipo},
                    onSelectionChanged: (Set<TipoProduto> selection) {
                      setState(() {
                        _filtroTipo = selection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Lista de produtos
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _produtosFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _filtroTipo == TipoProduto.naoPerecivel
                              ? Icons.inventory_2
                              : Icons.local_grocery_store,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum produto cadastrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _criarProduto,
                          icon: const Icon(Icons.add),
                          label: const Text('Criar primeiro produto'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _produtosFiltrados.length,
                    itemBuilder: (context, index) {
                      final produto = _produtosFiltrados[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
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
                                Text('Fabricante: ${produto.fabricante}'),
                              if (produto.distribuidor != null)
                                Text('Distribuidor: ${produto.distribuidor}'),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'editar') {
                                _editarProduto(produto);
                              } else if (value == 'excluir') {
                                _excluirProduto(produto);
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
                              const PopupMenuItem(
                                value: 'excluir',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
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
    );
  }
}
