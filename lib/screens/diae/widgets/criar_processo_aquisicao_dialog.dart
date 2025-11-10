import 'package:flutter/material.dart';

import '../../../database/firestore_helper.dart';
import '../../../models/memoria_calculo.dart';
import '../../../models/processo_aquisicao.dart';

class CriarProcessoAquisicaoDialog extends StatefulWidget {
  final String anoLetivo;
  final List<MemoriaCalculo> memoriasDisponiveis;

  const CriarProcessoAquisicaoDialog({
    super.key,
    required this.anoLetivo,
    required this.memoriasDisponiveis,
  });

  @override
  State<CriarProcessoAquisicaoDialog> createState() =>
      _CriarProcessoAquisicaoDialogState();
}

class _CriarProcessoAquisicaoDialogState
    extends State<CriarProcessoAquisicaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacoesController = TextEditingController();

  MemoriaCalculo? _memoriaSelecionada;
  bool _salvando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_memoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma memória de cálculo')),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final db = FirestoreHelper();
      final processoId = DateTime.now().millisecondsSinceEpoch.toString();

      // Inicializar todas as fases
      final fases = <FaseProcessoAquisicao, FaseProcesso>{
        FaseProcessoAquisicao.processoIniciado: FaseProcesso(
          concluida: true,
          dataInicio: DateTime.now(),
          dataConclusao: DateTime.now(),
          observacoes: _observacoesController.text.trim(),
        ),
        FaseProcessoAquisicao.editalPublicado: FaseProcesso(concluida: false),
        FaseProcessoAquisicao.analisePropostas: FaseProcesso(concluida: false),
        FaseProcessoAquisicao.resultadoFinal: FaseProcesso(concluida: false),
        FaseProcessoAquisicao.publicado: FaseProcesso(concluida: false),
      };

      final processo = ProcessoAquisicao(
        id: processoId,
        anoLetivo: widget.anoLetivo,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        memoriaCalculoId: _memoriaSelecionada!.id,
        faseAtual: FaseProcessoAquisicao.processoIniciado,
        status: StatusProcessoAquisicao.ativo,
        dataCriacao: DateTime.now(),
        observacoes: _observacoesController.text.trim().isNotEmpty
            ? _observacoesController.text.trim()
            : null,
        fases: fases,
      );

      await db.saveProcessoAquisicao(processo);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processo de aquisição criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao criar processo: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Criar Processo de Aquisição'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título do Processo',
                    hintText: 'Ex: Aquisição de Gêneros Alimentícios 2025',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Título é obrigatório';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descrição detalhada do processo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Memória de Cálculo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<MemoriaCalculo>(
                  initialValue: _memoriaSelecionada,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Selecione uma memória de cálculo',
                  ),
                  items: widget.memoriasDisponiveis.map((memoria) {
                    return DropdownMenuItem<MemoriaCalculo>(
                      value: memoria,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memória ${memoria.numero} - ${memoria.titulo}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${memoria.produtosSelecionados.length} produtos',
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
                      _memoriaSelecionada = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma memória de cálculo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _observacoesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações Iniciais',
                    hintText: 'Observações para a fase "Processo Iniciado"',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
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
                        'Fases do Processo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...FaseProcessoAquisicao.values.map((fase) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(
                                fase == FaseProcessoAquisicao.processoIniciado
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color:
                                    fase ==
                                        FaseProcessoAquisicao.processoIniciado
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                fase.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      fase ==
                                          FaseProcessoAquisicao.processoIniciado
                                      ? Colors.green[700]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Criar Processo'),
        ),
      ],
    );
  }
}
