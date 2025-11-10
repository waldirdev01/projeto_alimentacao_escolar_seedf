import 'package:flutter/material.dart';

import '../../../models/quantidade_refeicao.dart';

class EditarQuantidadeRefeicaoDialog extends StatefulWidget {
  final QuantidadeRefeicao quantidade;

  const EditarQuantidadeRefeicaoDialog({super.key, required this.quantidade});

  @override
  State<EditarQuantidadeRefeicaoDialog> createState() =>
      _EditarQuantidadeRefeicaoDialogState();
}

class _EditarQuantidadeRefeicaoDialogState
    extends State<EditarQuantidadeRefeicaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _siglaController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nomeController.text = widget.quantidade.nome;
    _siglaController.text = widget.quantidade.sigla;
    _descricaoController.text = widget.quantidade.descricao;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _siglaController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final quantidade = widget.quantidade.copyWith(
        nome: _nomeController.text.trim(),
        sigla: _siglaController.text.trim(),
        descricao: _descricaoController.text.trim(),
      );

      Navigator.of(context).pop(quantidade);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Tipo de refeição'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _siglaController,
                decoration: const InputDecoration(
                  labelText: 'Sigla',
                  hintText: 'Ex: 1 REF, 2 REF, Candanga',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite a sigla';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  hintText: 'Ex: Uma Refeição',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite o nome completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText:
                      'Ex: Alunos que fazem apenas uma refeição na escola',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite a descrição';
                  }
                  return null;
                },
              ),
            ],
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
