import 'package:flutter/material.dart';

import '../../../models/escola.dart';
import '../../../models/memoria_calculo.dart';
import '../../../models/produto.dart';
import '../../../models/quantidade_refeicao.dart';
import '../../../models/regiao.dart';
import 'selecionar_produtos_screen.dart';

class CriarMemoriaCalculoDialog extends StatefulWidget {
  final int numeroMemoriaCalculo;
  final List<Produto> produtos;
  final List<QuantidadeRefeicao> quantidadesRefeicao;
  final List<Regiao> regioes;
  final MemoriaCalculo? memoriaExistente;
  final MemoriaCalculo? memoriaAnterior;
  final Map<String, Map<String, Map<String, int>>>? dadosAlunosAtuais;

  const CriarMemoriaCalculoDialog({
    super.key,
    required this.numeroMemoriaCalculo,
    required this.produtos,
    required this.quantidadesRefeicao,
    required this.regioes,
    this.memoriaExistente,
    this.memoriaAnterior,
    this.dadosAlunosAtuais,
  });

  @override
  State<CriarMemoriaCalculoDialog> createState() =>
      _CriarMemoriaCalculoDialogState();
}

class _CriarMemoriaCalculoDialogState extends State<CriarMemoriaCalculoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(const Duration(days: 30));

  List<String> _produtosSelecionados = [];
  List<String> _modalidadesSelecionadas = [];
  List<String> _regioesSelecionadas = [];

  Map<String, Map<String, double>> _frequenciaPorProduto = {};
  int _rebuildKey = 0;

  @override
  void initState() {
    super.initState();
    if (widget.memoriaExistente != null) {
      _carregarDadosExistentes();
    } else {
      _tituloController.text =
          'Memória de Cálculo ${widget.numeroMemoriaCalculo}';
      _inicializarSelecoesPadrao();
    }
  }

  void _carregarDadosExistentes() {
    final mem = widget.memoriaExistente!;
    _tituloController.text = mem.titulo;
    _descricaoController.text = mem.descricao;
    _dataInicio = mem.dataInicio;
    _dataFim = mem.dataFim;
    _produtosSelecionados = List.from(mem.produtosSelecionados);
    _modalidadesSelecionadas = List.from(mem.modalidadesSelecionadas);
    _regioesSelecionadas = List.from(mem.regioesSelecionadas);
    _frequenciaPorProduto = Map.from(mem.frequenciaPorProduto);
    _inicializarFrequenciasPorProduto();
  }

  void _inicializarSelecoesPadrao() {
    // Selecionar todas as modalidades por padrão
    _modalidadesSelecionadas.addAll(ModalidadeEnsino.values.map((m) => m.name));

    // Selecionar todas as regiões por padrão
    _regioesSelecionadas.addAll(widget.regioes.map((r) => r.id));
  }

  void _inicializarFrequenciasPorProduto() {
    for (final produtoId in _produtosSelecionados) {
      if (!_frequenciaPorProduto.containsKey(produtoId)) {
        _frequenciaPorProduto[produtoId] = {};
      }

      for (final modalidade in ModalidadeEnsino.values) {
        for (final qtd in widget.quantidadesRefeicao.where((q) => q.ativo)) {
          final chave = '${modalidade.name}_${qtd.id}';
          if (!_frequenciaPorProduto[produtoId]!.containsKey(chave)) {
            // Tentar copiar da memória anterior se existir
            double valorInicial = 0.0;
            if (widget.memoriaAnterior != null &&
                widget.memoriaAnterior!.frequenciaPorProduto.containsKey(
                  produtoId,
                ) &&
                widget.memoriaAnterior!.frequenciaPorProduto[produtoId]!
                    .containsKey(chave)) {
              valorInicial = widget
                  .memoriaAnterior!
                  .frequenciaPorProduto[produtoId]![chave]!;
            }
            _frequenciaPorProduto[produtoId]![chave] = valorInicial;
          }
        }
      }
    }
  }

  void _abrirSelecaoProdutos() async {
    final resultado = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => SelecionarProdutosScreen(
          todosProdutos: widget.produtos,
          produtosJaSelecionados: _produtosSelecionados,
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        _produtosSelecionados = resultado;
        // Reinicializar frequências por produto
        _inicializarFrequenciasPorProduto();
        _rebuildKey++; // Força reconstrução dos campos
      });
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() async {
    if (_formKey.currentState!.validate()) {
      if (_produtosSelecionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos um produto')),
        );
        return;
      }

      if (_modalidadesSelecionadas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos uma modalidade')),
        );
        return;
      }

      if (_regioesSelecionadas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos uma região')),
        );
        return;
      }

      // Criar frequenciaByDomain vazio (não usado mais)
      final Map<String, Map<String, Map<String, double>>> frequenciaByDomain =
          {};

      final memoriaCalculo = MemoriaCalculo(
        id:
            widget.memoriaExistente?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        anoLetivo: '', // Será definido pelo componente pai
        numero: widget.numeroMemoriaCalculo,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        dataCriacao: widget.memoriaExistente?.dataCriacao ?? DateTime.now(),
        produtosSelecionados: _produtosSelecionados,
        modalidadesSelecionadas: _modalidadesSelecionadas,
        regioesSelecionadas: _regioesSelecionadas,
        frequenciaPorModalidadeQuantidade: {},
        frequenciaByDomain: frequenciaByDomain,
        frequenciaPorProduto: _frequenciaPorProduto,
        dadosAlunosCongelados: widget.dadosAlunosAtuais ?? {},
      );

      Navigator.of(context).pop(memoriaCalculo);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.memoriaExistente != null
                  ? 'Editar Memória de Cálculo ${widget.numeroMemoriaCalculo}'
                  : 'Nova Memória de Cálculo ${widget.numeroMemoriaCalculo}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título e Descrição
                      TextFormField(
                        controller: _tituloController,
                        decoration: const InputDecoration(
                          labelText: 'Título da Memória de Cálculo',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Digite o título';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descricaoController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Datas
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: const Text('Data Início'),
                              subtitle: Text(
                                '${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final data = await showDatePicker(
                                  context: context,
                                  initialDate: _dataInicio,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (data != null) {
                                  setState(() {
                                    _dataInicio = data;
                                  });
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              title: const Text('Data Fim'),
                              subtitle: Text(
                                '${_dataFim.day}/${_dataFim.month}/${_dataFim.year}',
                              ),
                              trailing: const Icon(Icons.calendar_today),
                              onTap: () async {
                                final data = await showDatePicker(
                                  context: context,
                                  initialDate: _dataFim,
                                  firstDate: _dataInicio,
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                if (data != null) {
                                  setState(() {
                                    _dataFim = data;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Produtos Selecionados
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Produtos Selecionados:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _produtosSelecionados.isEmpty
                                      ? Colors.grey[300]
                                      : Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_produtosSelecionados.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _produtosSelecionados.isEmpty
                                        ? Colors.grey[700]
                                        : Colors.blue[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _abrirSelecaoProdutos,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Gerenciar Produtos'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _produtosSelecionados.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'Nenhum produto selecionado. Clique em "Gerenciar Produtos" para adicionar.',
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _produtosSelecionados.map((
                                  produtoId,
                                ) {
                                  final produto = widget.produtos.firstWhere(
                                    (p) => p.id == produtoId,
                                    orElse: () => widget.produtos.first,
                                  );
                                  return Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor:
                                          produto.tipo ==
                                              TipoProduto.naoPerecivel
                                          ? Colors.blue[700]
                                          : Colors.green[700],
                                      child: const Icon(
                                        Icons.inventory_2,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    label: Text(produto.nome),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _produtosSelecionados.remove(produtoId);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Frequências por Produto
                      if (_produtosSelecionados.isNotEmpty &&
                          _modalidadesSelecionadas.isNotEmpty) ...[
                        const Text(
                          'Frequências por Produto:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Defina a frequência individual para cada produto. Cada produto pode ter frequências diferentes por modalidade e Tipo de refeição.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._produtosSelecionados.map((produtoId) {
                          final produto = widget.produtos.firstWhere(
                            (p) => p.id == produtoId,
                            orElse: () => widget.produtos.first,
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            produto.tipo ==
                                                TipoProduto.naoPerecivel
                                            ? Colors.blue[700]
                                            : Colors.green[700],
                                        radius: 16,
                                        child: const Icon(
                                          Icons.inventory_2,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          produto.nome,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ..._modalidadesSelecionadas.map((
                                    modalidadeName,
                                  ) {
                                    final modalidade = ModalidadeEnsino.values
                                        .firstWhere(
                                          (m) => m.name == modalidadeName,
                                        );
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          modalidade.displayName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          children: widget.quantidadesRefeicao.where((q) => q.ativo).map((
                                            qtd,
                                          ) {
                                            final chave =
                                                '${modalidadeName}_${qtd.id}';
                                            return SizedBox(
                                              width: 100,
                                              child: TextFormField(
                                                key: ValueKey(
                                                  '${produtoId}_${chave}_$_rebuildKey',
                                                ),
                                                initialValue:
                                                    _frequenciaPorProduto[produtoId]?[chave]
                                                        ?.toString() ??
                                                    '0.0',
                                                decoration: InputDecoration(
                                                  labelText: qtd.sigla,
                                                  border:
                                                      const OutlineInputBorder(),
                                                  isDense: true,
                                                ),
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (value) {
                                                  final freq =
                                                      double.tryParse(value) ??
                                                      0.0;
                                                  if (_frequenciaPorProduto[produtoId] ==
                                                      null) {
                                                    _frequenciaPorProduto[produtoId] =
                                                        {};
                                                  }
                                                  _frequenciaPorProduto[produtoId]![chave] =
                                                      freq;
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Modalidades
                      const Text(
                        'Modalidades de Ensino:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ModalidadeEnsino.values.map((modalidade) {
                          final selecionado = _modalidadesSelecionadas.contains(
                            modalidade.name,
                          );
                          return FilterChip(
                            label: Text(modalidade.displayName),
                            selected: selecionado,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _modalidadesSelecionadas.add(modalidade.name);
                                } else {
                                  _modalidadesSelecionadas.remove(
                                    modalidade.name,
                                  );
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Regiões
                      const Text(
                        'Regiões:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.regioes.map((regiao) {
                          final selecionado = _regioesSelecionadas.contains(
                            regiao.id,
                          );
                          return FilterChip(
                            label: Text(regiao.nome),
                            selected: selecionado,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _regioesSelecionadas.add(regiao.id);
                                } else {
                                  _regioesSelecionadas.remove(regiao.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
