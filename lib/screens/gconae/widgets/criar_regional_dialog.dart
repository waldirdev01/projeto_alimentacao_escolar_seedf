import 'package:flutter/material.dart';

import '../../../models/regiao.dart';

class CriarRegionalDialog extends StatefulWidget {
  final List<Regiao> regioes;

  const CriarRegionalDialog({super.key, required this.regioes});

  @override
  State<CriarRegionalDialog> createState() => _CriarRegionalDialogState();
}

class _CriarRegionalDialogState extends State<CriarRegionalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _siglaController = TextEditingController();
  Regiao? _regiaoSelecionada;

  @override
  void dispose() {
    _nomeController.dispose();
    _siglaController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate() && _regiaoSelecionada != null) {
      final regional = Regional(
        id: 'cre_${DateTime.now().millisecondsSinceEpoch}',
        nome: _nomeController.text.trim(),
        sigla: _siglaController.text.trim(),
      );

      Navigator.of(context).pop({
        'regiaoId': _regiaoSelecionada!.id,
        'regional': regional,
      });
    } else if (_regiaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma região')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar Nova Regional'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Região:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Regiao>(
                initialValue: _regiaoSelecionada,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Selecione a região',
                ),
                items: widget.regioes.map((regiao) {
                  return DropdownMenuItem<Regiao>(
                    value: regiao,
                    child: Text(regiao.nome),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _regiaoSelecionada = valor;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Selecione uma região';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Nome Completo:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Coordenação Regional de Ensino de...',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite o nome completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Sigla:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _siglaController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: CRE Taguatinga',
                  prefixIcon: Icon(Icons.short_text),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite a sigla';
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
        ElevatedButton(onPressed: _salvar, child: const Text('Criar')),
      ],
    );
  }
}

