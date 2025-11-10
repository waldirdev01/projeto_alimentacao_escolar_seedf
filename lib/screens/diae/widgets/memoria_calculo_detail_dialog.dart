import 'package:flutter/material.dart';

import '../../../database/firestore_helper.dart';
import '../../../models/memoria_calculo.dart';
import '../../../models/produto.dart';

class MemoriaCalculoDetailDialog extends StatefulWidget {
  final MemoriaCalculo memoria;
  final bool somenteVisualizacao;

  const MemoriaCalculoDetailDialog({
    super.key,
    required this.memoria,
    this.somenteVisualizacao = false,
  });

  @override
  State<MemoriaCalculoDetailDialog> createState() =>
      _MemoriaCalculoDetailDialogState();
}

class _MemoriaCalculoDetailDialogState
    extends State<MemoriaCalculoDetailDialog> {
  late Map<String, StatusProdutoMemoria> _statusProdutos;
  List<Produto> _produtos = [];
  bool _carregando = true;
  bool _alterado = false;

  @override
  void initState() {
    super.initState();
    _statusProdutos = Map.from(widget.memoria.statusProdutos);
    _carregarProdutos();
  }

  Future<void> _carregarProdutos() async {
    try {
      final db = FirestoreHelper();
      final todosProdutos = await db.getProdutos();

      setState(() {
        _produtos = todosProdutos
            .where((p) => widget.memoria.produtosSelecionados.contains(p.id))
            .toList();
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  Future<void> _salvar() async {
    try {
      final db = FirestoreHelper();
      final memoriaAtualizada = widget.memoria.copyWith(
        statusProdutos: _statusProdutos,
      );
      await db.updateMemoriaCalculo(memoriaAtualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _alterarStatus(String produtoId, StatusProdutoMemoria novoStatus) {
    setState(() {
      _statusProdutos[produtoId] = novoStatus;
      _alterado = true;
    });
  }

  Color _getStatusColor(StatusProdutoMemoria status) {
    switch (status) {
      case StatusProdutoMemoria.emAquisicao:
        return Colors.orange;
      case StatusProdutoMemoria.adquirido:
        return Colors.green;
      case StatusProdutoMemoria.fracassado:
        return Colors.red;
      case StatusProdutoMemoria.deserto:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.memoria.titulo,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ano Letivo: ${widget.memoria.anoLetivo}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 32),
            const Text(
              'Status dos Produtos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Legenda de status
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: StatusProdutoMemoria.values.map((status) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _produtos.isEmpty
                  ? const Center(child: Text('Nenhum produto nesta memória'))
                  : ListView.builder(
                      itemCount: _produtos.length,
                      itemBuilder: (context, index) {
                        final produto = _produtos[index];
                        final status =
                            _statusProdutos[produto.id] ??
                            StatusProdutoMemoria.emAquisicao;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(
                                status,
                              ).withValues(alpha: 0.2),
                              child: Icon(
                                Icons.inventory_2,
                                color: _getStatusColor(status),
                              ),
                            ),
                            title: Text(
                              produto.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Status: ${status.displayName}',
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 12,
                              ),
                            ),
                            trailing: widget.somenteVisualizacao
                                ? null
                                : PopupMenuButton<StatusProdutoMemoria>(
                                    icon: const Icon(Icons.more_vert),
                                    tooltip: 'Alterar status',
                                    onSelected: (novoStatus) {
                                      _alterarStatus(produto.id, novoStatus);
                                    },
                                    itemBuilder: (context) =>
                                        StatusProdutoMemoria.values.map((s) {
                                          return PopupMenuItem(
                                            value: s,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(s),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(s.displayName),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    widget.somenteVisualizacao ? 'Fechar' : 'Cancelar',
                  ),
                ),
                const SizedBox(width: 16),
                if (!widget.somenteVisualizacao)
                  ElevatedButton(
                    onPressed: _alterado ? _salvar : null,
                    child: const Text('Salvar Alterações'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
