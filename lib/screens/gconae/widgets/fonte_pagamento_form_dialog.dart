import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/fonte_pagamento.dart';

class FontePagamentoFormDialog extends StatefulWidget {
  final FontePagamento? fonte;

  const FontePagamentoFormDialog({super.key, this.fonte});

  @override
  State<FontePagamentoFormDialog> createState() =>
      _FontePagamentoFormDialogState();
}

class _FontePagamentoFormDialogState extends State<FontePagamentoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _observacaoController;
  late final TextEditingController _valorController;

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool get _isEdicao => widget.fonte != null;

  @override
  void initState() {
    super.initState();
    final fonte = widget.fonte;

    _nomeController = TextEditingController(text: fonte?.nome ?? '');
    _observacaoController =
        TextEditingController(text: fonte?.observacao ?? '');
    _valorController = TextEditingController(
      text: fonte?.valor != null
          ? _currencyFormat.format(fonte!.valor)
          : '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _observacaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  double _parseValor(String texto) {
    final normalizado = texto
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0.0;
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final fonteBase = widget.fonte;
    final valor = _parseValor(_valorController.text);

    final fonte = FontePagamento(
      id: fonteBase?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      nome: _nomeController.text.trim(),
      observacao: _observacaoController.text.trim(),
      valor: valor,
      ativo: fonteBase?.ativo ?? true,
      dataCriacao: fonteBase?.dataCriacao ?? DateTime.now(),
      dataAtualizacao: DateTime.now(),
    );

    Navigator.of(context).pop(fonte);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdicao ? 'Editar fonte de pagamento' : 'Nova fonte de pagamento'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payment),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome da fonte';
                    }
                    if (value.trim().length < 3) {
                      return 'Informe pelo menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observacaoController,
                  decoration: const InputDecoration(
                    labelText: 'Observação',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    hintText: 'Ex: 1000000,00 ou 1000000.00',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o valor';
                    }
                    final valor = _parseValor(value);
                    if (valor <= 0) {
                      return 'O valor deve ser maior que zero';
                    }
                    return null;
                  },
                  onEditingComplete: () {
                    // Formatação quando o campo perde o foco
                    final texto = _valorController.text.trim();
                    if (texto.isNotEmpty) {
                      final valor = _parseValor(texto);
                      if (valor > 0) {
                        final formatado = _currencyFormat.format(valor);
                        _valorController.text = formatado;
                      }
                    }
                  },
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
        ElevatedButton(
          onPressed: _salvar,
          child: Text(_isEdicao ? 'Atualizar' : 'Salvar'),
        ),
      ],
    );
  }
}

