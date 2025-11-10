import 'package:flutter/material.dart';

import '../../../models/escola.dart';
import '../../../models/regiao.dart';

class CriarEscolaDialog extends StatefulWidget {
  final List<Regiao> regioes;

  const CriarEscolaDialog({super.key, required this.regioes});

  @override
  State<CriarEscolaDialog> createState() => _CriarEscolaDialogState();
}

class _CriarEscolaDialogState extends State<CriarEscolaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  Regional? _regionalSelecionada;
  bool _ativo = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      if (_regionalSelecionada == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Selecione uma regional')));
        return;
      }

      final escola = Escola(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        codigo: _codigoController.text.trim(),
        regionalId: _regionalSelecionada!.id,
        dataCriacao: DateTime.now(),
        ativo: _ativo,
      );

      Navigator.of(context).pop(escola);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Coletar todas as regionais de todas as regiões
    final todasRegionais = <Regional>[];
    for (final regiao in widget.regioes) {
      todasRegionais.addAll(regiao.regionais);
    }

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Nova Escola',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Escola',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite o nome da escola';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código da Escola',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Digite o código da escola';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Regional>(
                    decoration: const InputDecoration(
                      labelText: 'Regional',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    items: todasRegionais.map((regional) {
                      return DropdownMenuItem<Regional>(
                        value: regional,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              regional.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              regional.sigla,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _regionalSelecionada = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione uma regional';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _ativo,
                        onChanged: (value) {
                          setState(() {
                            _ativo = value ?? true;
                          });
                        },
                      ),
                      const Text('Escola ativa'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(onPressed: _salvar, child: const Text('Salvar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
