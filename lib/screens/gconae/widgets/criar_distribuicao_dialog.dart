import 'package:flutter/material.dart';

import '../../../models/distribuicao.dart';
import '../../../models/escola.dart';
import '../../../models/produto.dart';
import '../../../models/quantidade_refeicao.dart';
import '../../../models/regiao.dart';

class CriarDistribuicaoDialog extends StatefulWidget {
  final String anoLetivo;
  final int numeroDistribuicao;
  final List<Produto> produtos;
  final List<QuantidadeRefeicao> quantidadesRefeicao;
  final List<Regiao> regioes;
  final Distribuicao? distribuicaoExistente;

  const CriarDistribuicaoDialog({
    super.key,
    required this.anoLetivo,
    required this.numeroDistribuicao,
    required this.produtos,
    required this.quantidadesRefeicao,
    required this.regioes,
    this.distribuicaoExistente,
  });

  @override
  State<CriarDistribuicaoDialog> createState() =>
      _CriarDistribuicaoDialogState();
}

class _CriarDistribuicaoDialogState extends State<CriarDistribuicaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now().add(const Duration(days: 30));
  StatusDistribuicao _status = StatusDistribuicao.planejada;

  final Set<String> _regioesSelecionadas = {};
  final Set<String> _modalidadesSelecionadas = {};
  final Set<String> _produtosSelecionados = {};
  final Map<String, Map<String, TextEditingController>> _frequenciaControllers =
      {};

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  void _inicializarDados() {
    if (widget.distribuicaoExistente != null) {
      final dist = widget.distribuicaoExistente!;
      _tituloController.text = dist.titulo;
      _descricaoController.text = dist.descricao;
      _dataInicio = dist.dataInicio;
      _dataFim = dist.dataFim;
      _status = dist.status;
      _regioesSelecionadas.addAll(dist.regioesSelecionadas);
      _modalidadesSelecionadas.addAll(dist.modalidadesSelecionadas);
      _produtosSelecionados.addAll(dist.produtosSelecionados);

      // Inicializar controllers de frequência
      _inicializarFrequenciaControllers();
    } else {
      _tituloController.text =
          'Memória de Cálculo ${widget.numeroDistribuicao}';
      _inicializarFrequenciaControllers();
    }
  }

  void _inicializarFrequenciaControllers() {
    for (final produto in widget.produtos) {
      _frequenciaControllers[produto.id] = {};
      for (final quantidade in widget.quantidadesRefeicao) {
        final valor =
            widget
                .distribuicaoExistente
                ?.frequenciaPorQuantidadeRefeicao[produto.id]?[quantidade.id] ??
            0;
        _frequenciaControllers[produto.id]![quantidade.id] =
            TextEditingController(text: valor > 0 ? valor.toString() : '');
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    for (final produtoControllers in _frequenciaControllers.values) {
      for (final controller in produtoControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      if (_regioesSelecionadas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos uma região')),
        );
        return;
      }

      if (_modalidadesSelecionadas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos uma modalidade')),
        );
        return;
      }

      if (_produtosSelecionados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos um produto')),
        );
        return;
      }

      // Coletar frequências
      final frequenciaPorQuantidadeRefeicao = <String, Map<String, int>>{};
      for (final produtoId in _produtosSelecionados) {
        frequenciaPorQuantidadeRefeicao[produtoId] = {};
        for (final quantidade in widget.quantidadesRefeicao) {
          final controller = _frequenciaControllers[produtoId]?[quantidade.id];
          if (controller != null && controller.text.isNotEmpty) {
            final frequencia = int.tryParse(controller.text) ?? 0;
            if (frequencia > 0) {
              frequenciaPorQuantidadeRefeicao[produtoId]![quantidade.id] =
                  frequencia;
            }
          }
        }
      }

      final distribuicao = Distribuicao(
        id:
            widget.distribuicaoExistente?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        anoLetivo: widget.anoLetivo,
        numero: widget.numeroDistribuicao,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        status: _status,
        dataCriacao:
            widget.distribuicaoExistente?.dataCriacao ?? DateTime.now(),
        dataLiberacao: _status == StatusDistribuicao.liberada
            ? DateTime.now()
            : widget.distribuicaoExistente?.dataLiberacao,
        regioesSelecionadas: _regioesSelecionadas.toList(),
        modalidadesSelecionadas: _modalidadesSelecionadas.toList(),
        produtosSelecionados: _produtosSelecionados.toList(),
        alunosPorRegiaoModalidade:
            widget.distribuicaoExistente?.alunosPorRegiaoModalidade ?? {},
        frequenciaPorQuantidadeRefeicao: frequenciaPorQuantidadeRefeicao,
      );

      Navigator.of(context).pop(distribuicao);
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
              'Configurar Memória de Cálculo ${widget.numeroDistribuicao}',
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
                        decoration: const InputDecoration(
                          labelText: 'Descrição',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
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
                      const SizedBox(height: 16),

                      // Status
                      DropdownButtonFormField<StatusDistribuicao>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: StatusDistribuicao.values.map((status) {
                          return DropdownMenuItem<StatusDistribuicao>(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Seleção de Regiões
                      const Text(
                        'Regiões',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.regioes.map((regiao) {
                        return CheckboxListTile(
                          title: Text(regiao.nome),
                          subtitle: Text(
                            '${regiao.regionais.length} regionais',
                          ),
                          value: _regioesSelecionadas.contains(regiao.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _regioesSelecionadas.add(regiao.id);
                              } else {
                                _regioesSelecionadas.remove(regiao.id);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 24),

                      // Seleção de Modalidades
                      const Text(
                        'Modalidades de Ensino',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ModalidadeEnsino.values.map((modalidade) {
                        return CheckboxListTile(
                          title: Text(modalidade.displayName),
                          value: _modalidadesSelecionadas.contains(
                            modalidade.name,
                          ),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _modalidadesSelecionadas.add(modalidade.name);
                              } else {
                                _modalidadesSelecionadas.remove(
                                  modalidade.name,
                                );
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 24),

                      // Seleção de Produtos
                      const Text(
                        'Produtos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.produtos.map((produto) {
                        return ExpansionTile(
                          title: CheckboxListTile(
                            title: Text(produto.nome),
                            subtitle: Text(
                              '${produto.fabricante} - ${produto.tipo.name}',
                            ),
                            value: _produtosSelecionados.contains(produto.id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _produtosSelecionados.add(produto.id);
                                } else {
                                  _produtosSelecionados.remove(produto.id);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          children: _produtosSelecionados.contains(produto.id)
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Frequência por Tipo de refeição:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...widget.quantidadesRefeicao.map((
                                          quantidade,
                                        ) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${quantidade.sigla} (${quantidade.nome}):',
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 80,
                                                  child: TextFormField(
                                                    controller:
                                                        _frequenciaControllers[produto
                                                            .id]?[quantidade
                                                            .id],
                                                    keyboardType:
                                                        TextInputType.number,
                                                    decoration: const InputDecoration(
                                                      labelText: 'Freq.',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
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
                                  ),
                                ]
                              : [],
                        );
                      }),
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
                  child: Text(
                    widget.distribuicaoExistente != null
                        ? 'Atualizar'
                        : 'Criar',
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
