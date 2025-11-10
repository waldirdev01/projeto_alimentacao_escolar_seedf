import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/escola.dart';
import '../../../models/produto.dart';
import '../../../models/quantidade_refeicao.dart';

/// Diálogo para edição simples de produto (usado durante fase de aquisição)
/// Inclui apenas: nome, tipo e valores per capita
class EditarProdutoDialog extends StatefulWidget {
  final Produto produto;
  final List<QuantidadeRefeicao> quantidadesRefeicao;

  const EditarProdutoDialog({
    super.key,
    required this.produto,
    required this.quantidadesRefeicao,
  });

  @override
  State<EditarProdutoDialog> createState() => _EditarProdutoDialogState();
}

class _EditarProdutoDialogState extends State<EditarProdutoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  TipoProduto _tipoSelecionado = TipoProduto.naoPerecivel;
  final Map<String, TextEditingController> _perCapitaControllers = {};

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _carregarDadosProduto();
  }

  void _inicializarControllers() {
    for (final modalidade in ModalidadeEnsino.values) {
      for (final quantidade in widget.quantidadesRefeicao) {
        final chave = '${modalidade.name}_${quantidade.id}';
        _perCapitaControllers[chave] = TextEditingController();
      }
    }
  }

  void _carregarDadosProduto() {
    _nomeController.text = widget.produto.nome;
    _tipoSelecionado = widget.produto.tipo;

    // Carregar per capita
    for (final entry in widget.produto.perCapita.entries) {
      if (_perCapitaControllers.containsKey(entry.key)) {
        _perCapitaControllers[entry.key]!.text = entry.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    for (final controller in _perCapitaControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final perCapita = <String, double>{};

      for (final entry in _perCapitaControllers.entries) {
        final valor = double.tryParse(entry.value.text.replaceAll(',', '.'));
        if (valor != null && valor > 0) {
          perCapita[entry.key] = valor;
        }
      }

      final produtoAtualizado = widget.produto.copyWith(
        nome: _nomeController.text.trim(),
        tipo: _tipoSelecionado,
        perCapita: perCapita,
        perCapitaByDomain: {'gpae': perCapita},
      );

      Navigator.of(context).pop(produtoAtualizado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Editar Produto',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Produto em fase de aquisição. Após adquirido, você poderá adicionar mais informações.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações básicas
                      const Text(
                        'Informações Básicas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Produto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.inventory),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite o nome do produto';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TipoProduto>(
                        initialValue: _tipoSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo do Produto',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: TipoProduto.values.map((tipo) {
                          return DropdownMenuItem<TipoProduto>(
                            value: tipo,
                            child: Row(
                              children: [
                                Icon(
                                  tipo == TipoProduto.naoPerecivel
                                      ? Icons.inventory_2
                                      : Icons.local_grocery_store,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tipo == TipoProduto.naoPerecivel
                                      ? 'Semiperecível'
                                      : 'Perecível',
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _tipoSelecionado = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Valores per capita
                      const Text(
                        'Valores Per Capita (Kg/L por aluno)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preencha os valores para cada modalidade e Tipo de refeição:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      _buildPerCapitaTable(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _salvar,
                  child: const Text('Salvar Alterações'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerCapitaTable() {
    final quantidadesAtivas = widget.quantidadesRefeicao
        .where((q) => q.ativo)
        .toList();

    if (quantidadesAtivas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Nenhuma Tipo de refeição ativa cadastrada.\nCadastre Tipo  de Refeição primeiro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Modalidade',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                ...quantidadesAtivas.map((quantidade) {
                  return Expanded(
                    child: Text(
                      quantidade.sigla,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Linhas
          ...ModalidadeEnsino.values.map((modalidade) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      modalidade.displayName,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  ...quantidadesAtivas.map((quantidade) {
                    final chave = '${modalidade.name}_${quantidade.id}';
                    return Expanded(
                      child: TextFormField(
                        controller: _perCapitaControllers[chave],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                        ],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          isDense: true,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
