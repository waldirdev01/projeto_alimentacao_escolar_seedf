import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/fornecedor.dart';
import 'widgets/fornecedor_form_dialog.dart';

enum FiltroFornecedor { ativos, inativos, todos }

class FornecedoresManagementScreen extends StatefulWidget {
  const FornecedoresManagementScreen({super.key});

  @override
  State<FornecedoresManagementScreen> createState() =>
      _FornecedoresManagementScreenState();
}

class _FornecedoresManagementScreenState
    extends State<FornecedoresManagementScreen> {
  final List<Fornecedor> _fornecedores = [];
  final TextEditingController _searchController = TextEditingController();
  FiltroFornecedor _filtro = FiltroFornecedor.ativos;
  bool _carregando = true;
  String _busca = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _busca = _searchController.text.toLowerCase().trim();
      });
    });
    _carregarFornecedores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarFornecedores() async {
    setState(() {
      _carregando = true;
    });

    try {
      final db = FirestoreHelper();
      final lista = await db.getFornecedores();
      lista.sort((a, b) => a.nome.compareTo(b.nome));
      setState(() {
        _fornecedores
          ..clear()
          ..addAll(lista);
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar fornecedores: $e')),
      );
    }
  }

  Future<void> _criarFornecedor() async {
    final resultado = await showDialog<Fornecedor>(
      context: context,
      builder: (_) => const FornecedorFormDialog(),
    );
    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.saveFornecedor(resultado);
        await _carregarFornecedores();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fornecedor cadastrado com sucesso!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar fornecedor: $e')),
        );
      }
    }
  }

  Future<void> _editarFornecedor(Fornecedor fornecedor) async {
    final resultado = await showDialog<Fornecedor>(
      context: context,
      builder: (_) => FornecedorFormDialog(fornecedor: fornecedor),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        await db.updateFornecedor(resultado);
        await _carregarFornecedores();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fornecedor atualizado com sucesso!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar fornecedor: $e')),
        );
      }
    }
  }

  Future<void> _alterarStatusFornecedor(
    Fornecedor fornecedor,
    bool novoStatus,
  ) async {
    try {
      final db = FirestoreHelper();
      await db.atualizarStatusFornecedor(fornecedor.id, novoStatus);
      await _carregarFornecedores();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              novoStatus
                  ? 'Fornecedor reativado com sucesso!'
                  : 'Fornecedor desativado com sucesso!',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar status: $e')),
      );
    }
  }

  void _excluirFornecedor(Fornecedor fornecedor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir fornecedor'),
        content: Text(
          'Deseja realmente excluir o fornecedor "${fornecedor.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final db = FirestoreHelper();
                await db.deleteFornecedor(fornecedor.id);
                await _carregarFornecedores();
                if (mounted) Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fornecedor excluído!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao excluir fornecedor: $e')),
                );
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  List<Fornecedor> get _fornecedoresFiltrados {
    Iterable<Fornecedor> lista = _fornecedores;

    switch (_filtro) {
      case FiltroFornecedor.ativos:
        lista = lista.where((f) => f.ativo);
        break;
      case FiltroFornecedor.inativos:
        lista = lista.where((f) => !f.ativo);
        break;
      case FiltroFornecedor.todos:
        break;
    }

    if (_busca.isNotEmpty) {
      lista = lista.where(
        (f) =>
            f.nome.toLowerCase().contains(_busca) ||
            (f.cnpj?.toLowerCase().contains(_busca) ?? false) ||
            (f.responsavel?.toLowerCase().contains(_busca) ?? false) ||
            (f.email?.toLowerCase().contains(_busca) ?? false),
      );
    }

    return lista.toList()
      ..sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Fornecedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarFornecedores,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo fornecedor',
            onPressed: _criarFornecedor,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Pesquisar por nome, CNPJ, responsável ou e-mail...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Ativos'),
                  selected: _filtro == FiltroFornecedor.ativos,
                  onSelected: (_) =>
                      setState(() => _filtro = FiltroFornecedor.ativos),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Inativos'),
                  selected: _filtro == FiltroFornecedor.inativos,
                  onSelected: (_) =>
                      setState(() => _filtro = FiltroFornecedor.inativos),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filtro == FiltroFornecedor.todos,
                  onSelected: (_) =>
                      setState(() => _filtro = FiltroFornecedor.todos),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _fornecedoresFiltrados.isEmpty
                    ? _EmptyState(onCreate: _criarFornecedor)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _fornecedoresFiltrados.length,
                        itemBuilder: (context, index) {
                          final fornecedor = _fornecedoresFiltrados[index];
                          return _FornecedorCard(
                            fornecedor: fornecedor,
                            onEditar: () => _editarFornecedor(fornecedor),
                            onExcluir: () => _excluirFornecedor(fornecedor),
                            onToggleStatus: () =>
                                _alterarStatusFornecedor(fornecedor, !fornecedor.ativo),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarFornecedor,
        icon: const Icon(Icons.add),
        label: const Text('Novo fornecedor'),
      ),
    );
  }
}

class _FornecedorCard extends StatelessWidget {
  final Fornecedor fornecedor;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onToggleStatus;

  const _FornecedorCard({
    required this.fornecedor,
    required this.onEditar,
    required this.onExcluir,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = fornecedor.ativo ? Colors.green[100] : Colors.red[100];
    final chipTextColor =
        fornecedor.ativo ? Colors.green[800] : Colors.red[800];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      fornecedor.ativo ? Colors.blue[100] : Colors.grey[300],
                  child: Icon(
                    Icons.handshake,
                    color: fornecedor.ativo ? Colors.blue[800] : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fornecedor.nome,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (fornecedor.responsavel?.isNotEmpty ?? false)
                        Text(
                          'Responsável: ${fornecedor.responsavel}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'editar':
                        onEditar();
                        break;
                      case 'status':
                        onToggleStatus();
                        break;
                      case 'excluir':
                        onExcluir();
                        break;
                    }
                  },
                  itemBuilder: (_) => [
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
                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            fornecedor.ativo
                                ? Icons.pause_circle
                                : Icons.check_circle,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(fornecedor.ativo ? 'Desativar' : 'Reativar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
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
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (fornecedor.cnpj?.isNotEmpty ?? false)
                  _InfoChip(
                    icon: Icons.badge,
                    label: fornecedor.cnpj!,
                  ),
                if (fornecedor.telefone?.isNotEmpty ?? false)
                  _InfoChip(
                    icon: Icons.phone,
                    label: fornecedor.telefone!,
                  ),
                if (fornecedor.email?.isNotEmpty ?? false)
                  _InfoChip(
                    icon: Icons.email,
                    label: fornecedor.email!,
                  ),
              ],
            ),
            if (fornecedor.endereco?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                fornecedor.endereco!,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fornecedor.ativo ? 'Ativo' : 'Inativo',
                    style: TextStyle(
                      color: chipTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                if (fornecedor.observacoes?.isNotEmpty ?? false)
                  Tooltip(
                    message: fornecedor.observacoes!,
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      avatar: Icon(icon, size: 16, color: Colors.blueGrey[700]),
      label: Text(label),
      backgroundColor: Colors.blueGrey[50],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handshake_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Nenhum fornecedor cadastrado',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Cadastrar fornecedor'),
          ),
        ],
      ),
    );
  }
}

