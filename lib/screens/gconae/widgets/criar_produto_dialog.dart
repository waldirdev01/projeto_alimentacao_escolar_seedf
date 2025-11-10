import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/escola.dart';
import '../../../models/produto.dart';
import '../../../models/quantidade_refeicao.dart';

class CriarProdutoDialog extends StatefulWidget {
  final List<QuantidadeRefeicao> quantidadesRefeicao;
  final List<Produto> produtosExistentes;

  const CriarProdutoDialog({
    super.key,
    required this.quantidadesRefeicao,
    this.produtosExistentes = const [],
  });

  @override
  State<CriarProdutoDialog> createState() => _CriarProdutoDialogState();
}

class _CriarProdutoDialogState extends State<CriarProdutoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  TipoProduto _tipoSelecionado = TipoProduto.naoPerecivel;
  final Map<String, TextEditingController> _perCapitaControllers = {};
  List<Produto> _produtosSimilares = [];
  bool _mostrarSugestoes = false;

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
    _nomeController.addListener(_buscarProdutosSimilares);
  }

  void _buscarProdutosSimilares() {
    final query = _nomeController.text.toLowerCase().trim();

    if (query.isEmpty || query.length < 2) {
      setState(() {
        _produtosSimilares = [];
        _mostrarSugestoes = false;
      });
      return;
    }

    final similares = widget.produtosExistentes
        .where((p) => p.nome.toLowerCase().contains(query))
        .take(5)
        .toList();

    setState(() {
      _produtosSimilares = similares;
      _mostrarSugestoes = similares.isNotEmpty;
    });
  }

  void _usarProdutoExistente(Produto produto) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usar Produto Existente?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Encontramos um produto similar cadastrado:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildProdutoInfo('Nome', produto.nome),
              _buildProdutoInfo(
                'Tipo',
                produto.tipo == TipoProduto.naoPerecivel
                    ? 'Semiperecível'
                    : 'Perecível',
              ),
              const SizedBox(height: 16),
              const Text(
                'Deseja usar este produto ou continuar cadastrando um novo?',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cadastrar Novo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Usar Este'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      // Retornar o produto existente
      if (mounted) {
        Navigator.of(context).pop(produto);
      }
    } else {
      // Fechar sugestões para continuar cadastrando
      setState(() {
        _mostrarSugestoes = false;
      });
    }
  }

  Widget _buildProdutoInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _inicializarControllers() {
    for (final modalidade in ModalidadeEnsino.values) {
      for (final quantidade in widget.quantidadesRefeicao) {
        final chave = '${modalidade.name}_${quantidade.id}';
        _perCapitaControllers[chave] = TextEditingController();
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

      final produto = Produto(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        tipo: _tipoSelecionado,
        perCapita: perCapita,
        perCapitaByDomain: {'gpae': perCapita},
      );

      Navigator.of(context).pop(produto);
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
            const Text(
              'Criar Novo Produto',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
                        decoration: InputDecoration(
                          labelText: 'Nome do Produto',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.inventory),
                          suffixIcon: _mostrarSugestoes
                              ? Icon(
                                  Icons.warning_amber,
                                  color: Colors.orange[700],
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite o nome do produto';
                          }
                          return null;
                        },
                      ),
                      // Sugestões de produtos similares
                      if (_mostrarSugestoes) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange[300]!,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Produtos similares já cadastrados:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      setState(() {
                                        _mostrarSugestoes = false;
                                      });
                                    },
                                    tooltip: 'Fechar sugestões',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ..._produtosSimilares.map((produto) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  child: ListTile(
                                    dense: true,
                                    leading: Icon(
                                      produto.tipo == TipoProduto.naoPerecivel
                                          ? Icons.inventory_2
                                          : Icons.local_grocery_store,
                                      color:
                                          produto.tipo ==
                                              TipoProduto.naoPerecivel
                                          ? Colors.blue[700]
                                          : Colors.green[700],
                                      size: 20,
                                    ),
                                    title: Text(
                                      produto.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    subtitle: Text(
                                      produto.tipo == TipoProduto.naoPerecivel
                                          ? 'Semiperecível'
                                          : 'Perecível',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    trailing: TextButton(
                                      onPressed: () =>
                                          _usarProdutoExistente(produto),
                                      child: const Text('Ver detalhes'),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
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
                        'Preencha os valores para cada modalidade e Tipo de refeição (opcional):',
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
                ElevatedButton(onPressed: _salvar, child: const Text('Criar')),
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
                        fontSize: 11,
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
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  ...quantidadesAtivas.map((quantidade) {
                    return Expanded(
                      child: TextFormField(
                        controller:
                            _perCapitaControllers['${modalidade.name}_${quantidade.id}'],
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
