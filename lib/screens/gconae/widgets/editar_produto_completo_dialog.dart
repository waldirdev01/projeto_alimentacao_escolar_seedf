import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/valores_nutricionais_data.dart';
import '../../../models/escola.dart';
import '../../../models/produto.dart';
import '../../../models/quantidade_refeicao.dart';

/// Diálogo para edição completa de produto (usado após aquisição)
/// Inclui todos os campos: marca, fornecedor, ingredientes, valores nutricionais, etc.
class EditarProdutoCompletoDialog extends StatefulWidget {
  final Produto produto;
  final List<QuantidadeRefeicao> quantidadesRefeicao;

  const EditarProdutoCompletoDialog({
    super.key,
    required this.produto,
    required this.quantidadesRefeicao,
  });

  @override
  State<EditarProdutoCompletoDialog> createState() =>
      _EditarProdutoCompletoDialogState();
}

class _EditarProdutoCompletoDialogState
    extends State<EditarProdutoCompletoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _distribuidorController = TextEditingController();
  final _marcaController = TextEditingController();
  final _ingredientesController = TextEditingController();

  TipoProduto _tipoSelecionado = TipoProduto.naoPerecivel;
  final Map<String, TextEditingController> _perCapitaControllers = {};
  final Map<String, TextEditingController> _valoresNutricionaisControllers = {};

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _carregarDadosProduto();
  }

  void _inicializarControllers() {
    // Per capita controllers
    for (final modalidade in ModalidadeEnsino.values) {
      for (final quantidade in widget.quantidadesRefeicao) {
        final chave = '${modalidade.name}_${quantidade.id}';
        _perCapitaControllers[chave] = TextEditingController();
      }
    }

    // Valores nutricionais controllers
    final nutrientes = ValoresNutricionaisData.getNutrientesDisponiveis();
    for (final nutriente in nutrientes) {
      _valoresNutricionaisControllers[nutriente['codigo']!] =
          TextEditingController();
    }
  }

  void _carregarDadosProduto() {
    _nomeController.text = widget.produto.nome;
    _fabricanteController.text = widget.produto.fabricante ?? '';
    _distribuidorController.text = widget.produto.distribuidor ?? '';
    _marcaController.text = widget.produto.marca ?? '';
    _ingredientesController.text = widget.produto.ingredientes ?? '';
    _tipoSelecionado = widget.produto.tipo;

    // Carregar per capita
    for (final entry in widget.produto.perCapita.entries) {
      if (_perCapitaControllers.containsKey(entry.key)) {
        _perCapitaControllers[entry.key]!.text = entry.value.toString();
      }
    }

    // Carregar valores nutricionais
    for (final entry in widget.produto.valoresNutricionais.entries) {
      if (_valoresNutricionaisControllers.containsKey(entry.key)) {
        _valoresNutricionaisControllers[entry.key]!.text = entry.value
            .toString();
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fabricanteController.dispose();
    _distribuidorController.dispose();
    _marcaController.dispose();
    _ingredientesController.dispose();
    for (final controller in _perCapitaControllers.values) {
      controller.dispose();
    }
    for (final controller in _valoresNutricionaisControllers.values) {
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

      // Coletar valores nutricionais
      final valoresNutricionais = <String, double>{};
      for (final entry in _valoresNutricionaisControllers.entries) {
        final valor = double.tryParse(entry.value.text.replaceAll(',', '.'));
        if (valor != null && valor > 0) {
          valoresNutricionais[entry.key] = valor;
        }
      }

      // Se não preencheu valores nutricionais, tentar buscar automaticamente
      if (valoresNutricionais.isEmpty) {
        final valoresAutomaticos =
            ValoresNutricionaisData.getValoresNutricionais(
              _nomeController.text.trim(),
            );
        if (valoresAutomaticos.values.any((v) => v > 0)) {
          valoresNutricionais.addAll(valoresAutomaticos);
        }
      }

      final produtoAtualizado = widget.produto.copyWith(
        nome: _nomeController.text.trim(),
        fabricante: _fabricanteController.text.trim().isEmpty
            ? null
            : _fabricanteController.text.trim(),
        distribuidor: _distribuidorController.text.trim().isEmpty
            ? null
            : _distribuidorController.text.trim(),
        marca: _marcaController.text.trim().isEmpty
            ? null
            : _marcaController.text.trim(),
        ingredientes: _ingredientesController.text.trim().isEmpty
            ? null
            : _ingredientesController.text.trim(),
        tipo: _tipoSelecionado,
        perCapita: perCapita,
        perCapitaByDomain: {'gpae': perCapita},
        valoresNutricionais: valoresNutricionais,
      );

      Navigator.of(context).pop(produtoAtualizado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.edit, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Editar Produto Completo',
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
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Esta é a edição completa do produto. Inclua todos os dados necessários após a aquisição.',
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
                      TextFormField(
                        controller: _fabricanteController,
                        decoration: const InputDecoration(
                          labelText: 'Fabricante',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _distribuidorController,
                        decoration: const InputDecoration(
                          labelText: 'Distribuidor',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.local_shipping),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _marcaController,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.label),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ingredientesController,
                        decoration: const InputDecoration(
                          labelText: 'Ingredientes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.list_alt),
                        ),
                        maxLines: 3,
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
                        'Valores por modalidade e Tipo de refeição:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      _buildPerCapitaTable(),
                      const SizedBox(height: 32),

                      // Valores nutricionais
                      const Text(
                        'Valores Nutricionais (por 100g)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Valores nutricionais do produto:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      _buildValoresNutricionaisTable(),
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
          'Nenhuma Tipo de refeição ativa cadastrada.',
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

  Widget _buildValoresNutricionaisTable() {
    final nutrientes = ValoresNutricionaisData.getNutrientesDisponiveis();

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
                    'Nutriente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Valor por 100g',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Linhas
          ...nutrientes.map((nutriente) {
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
                      '${nutriente['nome']} (${nutriente['unidade']})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller:
                          _valoresNutricionaisControllers[nutriente['codigo']],
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
                          horizontal: 8,
                          vertical: 4,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
