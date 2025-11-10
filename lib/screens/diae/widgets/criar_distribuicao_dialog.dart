import 'package:flutter/material.dart';

import '../../../models/ano_letivo.dart';
import '../../../models/distribuicao.dart';

class CriarDistribuicaoDialog extends StatefulWidget {
  final List<AnoLetivo> anosLetivos;
  final Distribuicao? distribuicaoExistente;

  const CriarDistribuicaoDialog({
    super.key,
    required this.anosLetivos,
    this.distribuicaoExistente,
  });

  @override
  State<CriarDistribuicaoDialog> createState() =>
      _CriarDistribuicaoDialogState();
}

class _CriarDistribuicaoDialogState extends State<CriarDistribuicaoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _numeroController;
  AnoLetivo? _anoSelecionado;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  // Removido _dataLimiteEnvio - agora gerenciado por etapas

  @override
  void initState() {
    super.initState();

    if (widget.distribuicaoExistente != null) {
      final dist = widget.distribuicaoExistente!;
      _tituloController = TextEditingController(text: dist.titulo);
      _descricaoController = TextEditingController(text: dist.descricao);
      _numeroController = TextEditingController(text: dist.numero.toString());
      _anoSelecionado = widget.anosLetivos.firstWhere(
        (ano) => ano.ano.toString() == dist.anoLetivo,
        orElse: () => widget.anosLetivos.first,
      );
      _dataInicio = dist.dataInicio;
      _dataFim = dist.dataFim;
      // Removido dataLimiteEnvio - agora gerenciado por etapas
    } else {
      _tituloController = TextEditingController();
      _descricaoController = TextEditingController();
      _numeroController = TextEditingController(text: '1');
      _anoSelecionado = widget.anosLetivos.firstWhere(
        (ano) => ano.ativo,
        orElse: () => widget.anosLetivos.first,
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context, int tipo) async {
    DateTime? dataInicial;
    switch (tipo) {
      case 0: // Início
        dataInicial = _dataInicio ?? DateTime.now();
        break;
      case 1: // Fim
        dataInicial = _dataFim ?? DateTime.now();
        break;
      // Removido caso 2 - data limite de envio
    }

    final data = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (data != null) {
      setState(() {
        switch (tipo) {
          case 0:
            _dataInicio = data;
            break;
          case 1:
            _dataFim = data;
            break;
          // Removido caso 2 - data limite de envio
        }
      });
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      if (_anoSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione um ano letivo')),
        );
        return;
      }

      if (_dataInicio == null || _dataFim == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione as datas de início e fim')),
        );
        return;
      }

      if (_dataFim!.isBefore(_dataInicio!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A data de fim deve ser posterior à data de início'),
          ),
        );
        return;
      }

      // Removida validação de data limite de envio - agora gerenciado por etapas

      final distribuicao = Distribuicao(
        id:
            widget.distribuicaoExistente?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        anoLetivo: _anoSelecionado!.ano.toString(),
        numero: int.parse(_numeroController.text),
        titulo: _tituloController.text,
        descricao: _descricaoController.text,
        dataInicio: _dataInicio!,
        dataFim: _dataFim!,
        // dataLimiteEnvio removido - agora gerenciado por etapas
        status:
            widget.distribuicaoExistente?.status ??
            StatusDistribuicao.planejada,
        dataCriacao:
            widget.distribuicaoExistente?.dataCriacao ?? DateTime.now(),
        dataLiberacao: widget.distribuicaoExistente?.dataLiberacao,
        escolasQueEnviaramDados:
            widget.distribuicaoExistente?.escolasQueEnviaramDados ?? [],
        regioesSelecionadas:
            widget.distribuicaoExistente?.regioesSelecionadas ?? [],
        modalidadesSelecionadas:
            widget.distribuicaoExistente?.modalidadesSelecionadas ?? [],
        produtosSelecionados:
            widget.distribuicaoExistente?.produtosSelecionados ?? [],
        alunosPorRegiaoModalidade:
            widget.distribuicaoExistente?.alunosPorRegiaoModalidade ?? {},
        frequenciaPorQuantidadeRefeicao:
            widget.distribuicaoExistente?.frequenciaPorQuantidadeRefeicao ?? {},
      );

      Navigator.of(context).pop(distribuicao);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.distribuicaoExistente == null
            ? 'Nova Distribuição'
            : 'Editar Distribuição',
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ano Letivo
                DropdownButtonFormField<AnoLetivo>(
                  initialValue: _anoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Ano Letivo',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.anosLetivos.map((ano) {
                    return DropdownMenuItem(
                      value: ano,
                      child: Text('Ano ${ano.ano}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _anoSelecionado = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Selecione um ano letivo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Número
                TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número da Distribuição',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 1, 2, 3...',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite o número da distribuição';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Digite um número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: Primeira Distribuição',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite um título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descrição
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Detalhes sobre esta distribuição',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Data Início
                InkWell(
                  onTap: () => _selecionarData(context, 0),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de Início',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dataInicio != null
                          ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                          : 'Selecione a data',
                      style: TextStyle(
                        color: _dataInicio != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Data Fim
                InkWell(
                  onTap: () => _selecionarData(context, 1),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de Fim',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dataFim != null
                          ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                          : 'Selecione a data',
                      style: TextStyle(
                        color: _dataFim != null ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
