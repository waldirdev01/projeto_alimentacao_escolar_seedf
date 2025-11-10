import 'package:flutter/material.dart';

import '../../../models/regiao.dart';

class MoverRegionalDialog extends StatefulWidget {
  final Regional regional;
  final List<Regiao> regioes;
  final String regiaoAtualId;

  const MoverRegionalDialog({
    super.key,
    required this.regional,
    required this.regioes,
    required this.regiaoAtualId,
  });

  @override
  State<MoverRegionalDialog> createState() => _MoverRegionalDialogState();
}

class _MoverRegionalDialogState extends State<MoverRegionalDialog> {
  Regiao? _regiaoDestino;

  void _mover() {
    if (_regiaoDestino != null) {
      Navigator.of(context).pop(_regiaoDestino!.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a região de destino')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final regioesDisponiveis = widget.regioes
        .where((r) => r.id != widget.regiaoAtualId)
        .toList();

    final regiaoAtual = widget.regioes.firstWhere(
      (r) => r.id == widget.regiaoAtualId,
    );

    return AlertDialog(
      title: const Text('Mover Regional'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Regional:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.regional.sigla,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Região atual:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(regiaoAtual.nome, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mover para:',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Regiao>(
            initialValue: _regiaoDestino,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
              hintText: 'Selecione a região de destino',
            ),
            items: regioesDisponiveis.map((regiao) {
              return DropdownMenuItem<Regiao>(
                value: regiao,
                child: Text(
                  '${regiao.nome} (${regiao.regionais.length} regionais)',
                ),
              );
            }).toList(),
            onChanged: (valor) {
              setState(() {
                _regiaoDestino = valor;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _mover, child: const Text('Mover')),
      ],
    );
  }
}
