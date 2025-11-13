import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../database/firestore_helper.dart';
import '../../../models/fonte_pagamento.dart';
import '../../../models/fornecedor.dart';
import '../../../models/memoria_calculo.dart';
import '../../../models/processo_aquisicao.dart';
import '../../../models/produto.dart';
import '../../../models/quadro_tecnico_descritivo.dart';
import '../../../models/regiao.dart';

class RegistrarQuadroTecnicoDialog extends StatefulWidget {
  final ProcessoAquisicao processo;
  final MemoriaCalculo memoria;
  final List<Produto> produtosSelecionados;
  final List<Regiao> regioes;
  final QuadroTecnicoDescritivo? quadroExistente;
  final Fornecedor? fornecedorInicial;
  final bool permitirMultiplosFornecedores;

  const RegistrarQuadroTecnicoDialog({
    super.key,
    required this.processo,
    required this.memoria,
    required this.produtosSelecionados,
    required this.regioes,
    this.quadroExistente,
    this.fornecedorInicial,
    this.permitirMultiplosFornecedores = true,
  });

  @override
  State<RegistrarQuadroTecnicoDialog> createState() =>
      _RegistrarQuadroTecnicoDialogState();
}

class _RegistrarQuadroTecnicoDialogState
    extends State<RegistrarQuadroTecnicoDialog> {
  late final TextEditingController _numeroAtaJulgamentoController;
  late final TextEditingController _dataAtaController;
  late DateTime _dataAta;
  TipoAta _tipoAta = TipoAta.julgamento;
  FontePagamento? _fonteSelecionada;
  List<FontePagamento> _fontesDisponiveis = [];

  final List<_FornecedorFormData> _fornecedores = [];
  bool _salvando = false;
  bool _carregandoFontes = true;

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }


  @override
  void initState() {
    super.initState();
    _numeroAtaJulgamentoController = TextEditingController(
      text: widget.quadroExistente?.numeroAtaJulgamento ?? '',
    );
    _dataAta = widget.quadroExistente?.dataAta ?? DateTime.now();
    _dataAtaController = TextEditingController(
      text: _formatarData(_dataAta),
    );
    _tipoAta = widget.quadroExistente?.tipoAta ?? TipoAta.julgamento;
    _carregarFontes();

    if (widget.quadroExistente != null) {
      // Ao editar, mostrar apenas os produtos que já estão na QTD
      for (final fornecedor in widget.quadroExistente!.fornecedores) {
        // Coletar apenas os produtos que estão neste fornecedor
        final produtosDoFornecedor = fornecedor.itens
            .map((item) => widget.produtosSelecionados
                .firstWhere((p) => p.id == item.produtoId))
            .toList();
        
        _fornecedores.add(
          _FornecedorFormData.fromModel(
            fornecedor,
            produtosDoFornecedor,
            widget.regioes,
          ),
        );
      }
    } else {
      _fornecedores.add(
        _FornecedorFormData.create(
          widget.produtosSelecionados,
          widget.regioes,
          fornecedor: widget.fornecedorInicial,
          bloqueado: widget.fornecedorInicial != null &&
              widget.permitirMultiplosFornecedores == false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _numeroAtaJulgamentoController.dispose();
    _dataAtaController.dispose();
    for (final fornecedor in _fornecedores) {
      fornecedor.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarFontes() async {
    try {
      final db = FirestoreHelper();
      final fontes = await db.getFontesPagamentoAtivas();
      fontes.sort((a, b) => a.nome.compareTo(b.nome));
      
      setState(() {
        _fontesDisponiveis = fontes;
        _carregandoFontes = false;
        
        // Se estiver editando, selecionar a fonte existente
        if (widget.quadroExistente != null) {
          final fonteNome = widget.quadroExistente!.fonte;
          try {
            _fonteSelecionada = fontes.firstWhere(
              (f) => f.nome == fonteNome,
            );
          } catch (e) {
            // Se não encontrar, usar a primeira disponível
            _fonteSelecionada = fontes.isNotEmpty ? fontes.first : null;
          }
        } else if (fontes.isNotEmpty) {
          _fonteSelecionada = fontes.first;
        }
      });
    } catch (e) {
      setState(() {
        _carregandoFontes = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar fontes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 960,
        height: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.description, size: 28, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.quadroExistente == null
                              ? 'Registrar Quadro Técnico Descritivo (QTD)'
                              : 'Editar Quadro Técnico Descritivo (QTD)',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.processo.titulo,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 260,
                          child: TextField(
                            controller: _numeroAtaJulgamentoController,
                            decoration: const InputDecoration(
                              labelText: 'Número da Ata de Julgamento',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<TipoAta>(
                            value: _tipoAta,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Ata',
                              border: OutlineInputBorder(),
                            ),
                            items: TipoAta.values.map((tipo) {
                              return DropdownMenuItem(
                                value: tipo,
                                child: Text(
                                  tipo.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _tipoAta = value);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            readOnly: true,
                            controller: _dataAtaController,
                            decoration: InputDecoration(
                              labelText: 'Data da Ata',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today_outlined),
                                onPressed: _selecionarData,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: _carregandoFontes
                              ? const Center(child: CircularProgressIndicator())
                              : DropdownButtonFormField<FontePagamento>(
                                  value: _fonteSelecionada,
                                  decoration: const InputDecoration(
                                    labelText: 'Fonte de Pagamento *',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: _fontesDisponiveis.map((fonte) {
                                    return DropdownMenuItem(
                                      value: fonte,
                                      child: Text(
                                        fonte.nome,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _fonteSelecionada = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Selecione uma fonte';
                                    }
                                    return null;
                                  },
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Fornecedores e Itens',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.permitirMultiplosFornecedores)
                          TextButton.icon(
                            onPressed: _salvando ? null : _adicionarFornecedor,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar fornecedor'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._fornecedores.asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final fornecedor = entry.value;
                        return _FornecedorCard(
                          fornecedor: fornecedor,
                          regioes: widget.regioes,
                          numeroFornecedor: index + 1,
                          bloqueado: fornecedor.bloqueado,
                          onRemover: widget.permitirMultiplosFornecedores &&
                                  _fornecedores.length > 1
                              ? () => _removerFornecedor(index)
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _salvando ? null : _salvarQtd,
                    icon: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _salvando ? 'Salvando...' : 'Salvar QTD',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selecionarData() async {
    final novaData = await showDatePicker(
      context: context,
      initialDate: _dataAta,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (novaData != null) {
      setState(() {
        _dataAta = novaData;
        _dataAtaController.text = _formatarData(novaData);
      });
    }
  }

  void _adicionarFornecedor() {
    setState(() {
      _fornecedores.add(
        _FornecedorFormData.create(
          widget.produtosSelecionados,
          widget.regioes,
        ),
      );
    });
  }

  void _removerFornecedor(int index) {
    setState(() {
      _fornecedores.removeAt(index);
    });
  }

  Future<void> _salvarQtd() async {
    final numeroAtaJulgamento = _numeroAtaJulgamentoController.text.trim();
    if (numeroAtaJulgamento.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o número da Ata de Julgamento.')),
      );
      return;
    }

    final fornecedoresValidos = <FornecedorQtd>[];
    int itemSequencial = 1;

    for (final fornecedor in _fornecedores) {
      final nome = fornecedor.nomeController.text.trim();
      final itensValidos = <ItemQtd>[];

      for (final item in fornecedor.itens) {
        final valorUnitario = _parseValor(item.valorUnitarioController.text);
        final Map<String, double> quantidades = {}; // Mantido para compatibilidade
        final Map<String, double> cotaPrincipal = {};
        final Map<String, double> cotaReservada = {};
        double quantidadeTotal = 0;

        // Processar Cota Principal
        item.cotaPrincipalControllers.forEach((regiaoId, controller) {
          final quantidade = _parseValor(controller.text);
          if (quantidade > 0) {
            cotaPrincipal[regiaoId] = quantidade;
            quantidades[regiaoId] = (quantidades[regiaoId] ?? 0) + quantidade;
            quantidadeTotal += quantidade;
          }
        });

        // Processar Cota Reservada
        item.cotaReservadaControllers.forEach((regiaoId, controller) {
          final quantidade = _parseValor(controller.text);
          if (quantidade > 0) {
            cotaReservada[regiaoId] = quantidade;
            quantidades[regiaoId] = (quantidades[regiaoId] ?? 0) + quantidade;
            quantidadeTotal += quantidade;
          }
        });

        if (quantidadeTotal <= 0) continue;

        final numeroItemEdital = item.numeroItemEditalController.text.trim();
        if (numeroItemEdital.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Informe o número do item do edital para ${item.produto.nome}.',
              ),
            ),
          );
          return;
        }

        itensValidos.add(
          ItemQtd(
            numeroItemEdital: numeroItemEdital,
            itemNumero: itemSequencial++,
            produtoId: item.produto.id,
            produtoNome: item.produto.nome,
            valorUnitarioReais: valorUnitario,
            quantidadesPorRegiaoKg: quantidades,
            cotaPrincipalPorRegiaoKg: cotaPrincipal,
            cotaReservadaPorRegiaoKg: cotaReservada,
          ),
        );
      }

      if (itensValidos.isEmpty) continue;

      fornecedoresValidos.add(
        FornecedorQtd(
          id: fornecedor.id,
          nome: nome.isEmpty
              ? 'Fornecedor ${fornecedoresValidos.length + 1}'
              : nome,
          itens: itensValidos,
        ),
      );
    }

    if (fornecedoresValidos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe ao menos um fornecedor com quantidades para salvar o QTD.',
          ),
        ),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      if (_fonteSelecionada == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma fonte de pagamento.')),
        );
        setState(() => _salvando = false);
        return;
      }

      final agora = DateTime.now();
      final quadro = QuadroTecnicoDescritivo(
        id: widget.quadroExistente?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        processoId: widget.processo.id,
        memoriaCalculoId: widget.memoria.id,
        numeroAtaJulgamento: numeroAtaJulgamento,
        tipoAta: _tipoAta,
        dataAta: _dataAta,
        dataCriacao: widget.quadroExistente?.dataCriacao ?? agora,
        fonte: _fonteSelecionada!.nome,
        fornecedores: fornecedoresValidos,
      );

      await FirestoreHelper().saveQuadroTecnicoDescritivo(quadro);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar QTD: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  double _parseValor(String texto) {
    final normalizado = texto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0.0;
  }
}

class _FornecedorCard extends StatelessWidget {
  final _FornecedorFormData fornecedor;
  final List<Regiao> regioes;
  final int numeroFornecedor;
  final VoidCallback? onRemover;
  final bool bloqueado;

  static final NumberFormat _quantityFormat =
      NumberFormat('#,##0.000', 'pt_BR');

  const _FornecedorCard({
    required this.fornecedor,
    required this.regioes,
    required this.numeroFornecedor,
    this.onRemover,
    this.bloqueado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: fornecedor.nomeController,
                    enabled: !bloqueado,
                    decoration: InputDecoration(
                      labelText: 'Fornecedor $numeroFornecedor',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (onRemover != null) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onRemover,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red[400],
                    tooltip: 'Remover fornecedor',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fornecedor.itens.map(
                (item) {
                  // Calcular totais
                  double totalPrincipal = 0;
                  double totalReservada = 0;
                  
                  item.cotaPrincipalControllers.values.forEach((controller) {
                    final normalizado =
                        controller.text.replaceAll('.', '').replaceAll(',', '.');
                    totalPrincipal += double.tryParse(normalizado) ?? 0.0;
                  });
                  
                  item.cotaReservadaControllers.values.forEach((controller) {
                    final normalizado =
                        controller.text.replaceAll('.', '').replaceAll(',', '.');
                    totalReservada += double.tryParse(normalizado) ?? 0.0;
                  });
                  
                  final quantidadeTotal = totalPrincipal + totalReservada;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.produto.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 160,
                              child: TextField(
                                controller: item.numeroItemEditalController,
                                decoration: const InputDecoration(
                                  labelText: 'Número do Item (Edital)',
                                  border: OutlineInputBorder(),
                                  hintText: 'Ex: 1, 2, 3...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: item.valorUnitarioController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Valor unitário (R\$)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Cota Principal
                        Text(
                          'Cota Principal',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: regioes.map((regiao) {
                            final controller =
                                item.cotaPrincipalControllers[regiao.id]!;
                            return SizedBox(
                              width: 160,
                              child: TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d,\.]'),
                                  ),
                                  _QuantidadeInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: '${regiao.nome} - Principal (kg)',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Cota Reservada
                        Text(
                          'Cota Reservada',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: regioes.map((regiao) {
                            final controller =
                                item.cotaReservadaControllers[regiao.id]!;
                            return SizedBox(
                              width: 160,
                              child: TextField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d,\.]'),
                                  ),
                                  _QuantidadeInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: '${regiao.nome} - Reservada (kg)',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Total Principal: ${_quantityFormat.format(totalPrincipal)} kg',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Total Reservada: ${_quantityFormat.format(totalReservada)} kg',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Quantidade total: ${_quantityFormat.format(quantidadeTotal)} kg',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FornecedorFormData {
  final String id;
  final TextEditingController nomeController;
  final List<_ItemFormData> itens;
  final bool bloqueado;

  _FornecedorFormData({
    required this.id,
    required this.nomeController,
    required this.itens,
    this.bloqueado = false,
  });

  factory _FornecedorFormData.create(
    List<Produto> produtos,
    List<Regiao> regioes,
    {Fornecedor? fornecedor, bool bloqueado = false}
  ) {
    return _FornecedorFormData(
      id: fornecedor?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nomeController: TextEditingController(text: fornecedor?.nome ?? ''),
      itens: produtos
          .map((produto) => _ItemFormData.create(produto, regioes))
          .toList(),
      bloqueado: bloqueado,
    );
  }

  factory _FornecedorFormData.fromModel(
    FornecedorQtd fornecedor,
    List<Produto> produtos,
    List<Regiao> regioes,
  ) {
    final itensForm = produtos
        .map((produto) => _ItemFormData.create(produto, regioes))
        .toList();

    for (final itemModel in fornecedor.itens) {
      final itemForm = itensForm.firstWhere(
        (form) => form.produto.id == itemModel.produtoId,
        orElse: () => itensForm.first,
      );

      itemForm.numeroItemEditalController.text = itemModel.numeroItemEdital;
      itemForm.valorUnitarioController.text =
          itemModel.valorUnitarioReais.toStringAsFixed(2);

      // Carregar Cota Principal
      itemModel.cotaPrincipalPorRegiaoKg.forEach((regiaoId, quantidade) {
        if (itemForm.cotaPrincipalControllers.containsKey(regiaoId)) {
          final formatado = NumberFormat('#,##0.000', 'pt_BR').format(quantidade);
          itemForm.cotaPrincipalControllers[regiaoId]!.text = formatado;
        }
      });

      // Carregar Cota Reservada
      itemModel.cotaReservadaPorRegiaoKg.forEach((regiaoId, quantidade) {
        if (itemForm.cotaReservadaControllers.containsKey(regiaoId)) {
          final formatado = NumberFormat('#,##0.000', 'pt_BR').format(quantidade);
          itemForm.cotaReservadaControllers[regiaoId]!.text = formatado;
        }
      });
    }

    return _FornecedorFormData(
      id: fornecedor.id,
      nomeController: TextEditingController(text: fornecedor.nome),
      itens: itensForm,
      bloqueado: false,
    );
  }

  void dispose() {
    nomeController.dispose();
    for (final item in itens) {
      item.dispose();
    }
  }
}

class _ItemFormData {
  final Produto produto;
  final TextEditingController numeroItemEditalController;
  final TextEditingController valorUnitarioController;
  final Map<String, TextEditingController> quantidadeControllers; // Mantido para compatibilidade
  final Map<String, TextEditingController> cotaPrincipalControllers;
  final Map<String, TextEditingController> cotaReservadaControllers;

  _ItemFormData({
    required this.produto,
    required this.numeroItemEditalController,
    required this.valorUnitarioController,
    required this.quantidadeControllers,
    required this.cotaPrincipalControllers,
    required this.cotaReservadaControllers,
  });

  factory _ItemFormData.create(Produto produto, List<Regiao> regioes) {
    final mapaQuantidades = <String, TextEditingController>{};
    final mapaPrincipal = <String, TextEditingController>{};
    final mapaReservada = <String, TextEditingController>{};
    for (final regiao in regioes) {
      mapaQuantidades[regiao.id] = TextEditingController();
      mapaPrincipal[regiao.id] = TextEditingController();
      mapaReservada[regiao.id] = TextEditingController();
    }
    return _ItemFormData(
      produto: produto,
      numeroItemEditalController: TextEditingController(),
      valorUnitarioController: TextEditingController(),
      quantidadeControllers: mapaQuantidades,
      cotaPrincipalControllers: mapaPrincipal,
      cotaReservadaControllers: mapaReservada,
    );
  }

  void dispose() {
    numeroItemEditalController.dispose();
    valorUnitarioController.dispose();
    for (final controller in quantidadeControllers.values) {
      controller.dispose();
    }
    for (final controller in cotaPrincipalControllers.values) {
      controller.dispose();
    }
    for (final controller in cotaReservadaControllers.values) {
      controller.dispose();
    }
  }
}

class _QuantidadeInputFormatter extends TextInputFormatter {
  static final NumberFormat _format = NumberFormat('#,##0.000', 'pt_BR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove tudo exceto números
    final apenasNumeros = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (apenasNumeros.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Converte para número (assumindo 3 casas decimais)
    final numero = int.parse(apenasNumeros) / 1000.0;

    // Formata no padrão brasileiro
    final formatado = _format.format(numero);

    return TextEditingValue(
      text: formatado,
      selection: TextSelection.collapsed(offset: formatado.length),
    );
  }
}

