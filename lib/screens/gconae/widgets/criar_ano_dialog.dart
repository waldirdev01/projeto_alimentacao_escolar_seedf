import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/ano_letivo.dart';

class CriarAnoDialog extends StatefulWidget {
  final List<AnoLetivo> anosExistentes;

  const CriarAnoDialog({super.key, required this.anosExistentes});

  @override
  State<CriarAnoDialog> createState() => _CriarAnoDialogState();
}

class _CriarAnoDialogState extends State<CriarAnoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _anoController = TextEditingController();
  AnoLetivo? _anoParaReplicar;

  @override
  void initState() {
    super.initState();
    // Sugerir o próximo ano
    if (widget.anosExistentes.isNotEmpty) {
      final ultimoAno = widget.anosExistentes
          .map((a) => a.ano)
          .reduce((a, b) => a > b ? a : b);
      _anoController.text = '${ultimoAno + 1}';
    } else {
      _anoController.text = '${DateTime.now().year}';
    }
  }

  @override
  void dispose() {
    _anoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final ano = int.parse(_anoController.text);

      Navigator.of(
        context,
      ).pop({'ano': ano, 'anoReplicado': _anoParaReplicar?.id});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar Novo Ano Letivo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _anoController,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  hintText: '2026',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o ano';
                  }
                  final ano = int.tryParse(value);
                  if (ano == null || ano < 2020 || ano > 2100) {
                    return 'Ano inválido';
                  }
                  if (widget.anosExistentes.any((a) => a.ano == ano)) {
                    return 'Este ano já existe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (widget.anosExistentes.isNotEmpty) ...[
                const Text(
                  'Replicar configurações de:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AnoLetivo?>(
                  initialValue: _anoParaReplicar,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.copy),
                  ),
                  hint: const Text('Criar do zero'),
                  items: [
                    const DropdownMenuItem<AnoLetivo?>(
                      value: null,
                      child: Text('Criar do zero'),
                    ),
                    ...widget.anosExistentes.map((ano) {
                      return DropdownMenuItem<AnoLetivo?>(
                        value: ano,
                        child: Text('Ano ${ano.ano}'),
                      );
                    }),
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _anoParaReplicar = valor;
                    });
                  },
                ),
                const SizedBox(height: 12),
                if (_anoParaReplicar != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'As aquisições de ${_anoParaReplicar!.ano} serão replicadas para o novo ano',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
