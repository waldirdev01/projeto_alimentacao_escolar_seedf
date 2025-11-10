import 'package:flutter/material.dart';

import '../../../database/firestore_helper.dart';
import '../../../models/processo_aquisicao.dart';
import '../memorias_calculo_status_screen.dart';

class ProcessoAquisicaoDetailDialog extends StatefulWidget {
  final ProcessoAquisicao processo;

  const ProcessoAquisicaoDetailDialog({super.key, required this.processo});

  @override
  State<ProcessoAquisicaoDetailDialog> createState() =>
      _ProcessoAquisicaoDetailDialogState();
}

class _ProcessoAquisicaoDetailDialogState
    extends State<ProcessoAquisicaoDetailDialog> {
  late ProcessoAquisicao _processo;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _processo = widget.processo;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = false;
    });
  }

  Future<void> _avancarFase() async {
    final fases = FaseProcessoAquisicao.values;
    final indiceAtual = fases.indexOf(_processo.faseAtual);

    if (indiceAtual >= fases.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processo já está na última fase')),
      );
      return;
    }

    final proximaFase = fases[indiceAtual + 1];
    final observacoes = await _solicitarObservacoes(proximaFase);

    if (observacoes == null) return; // Usuário cancelou

    try {
      final db = FirestoreHelper();

      // Marcar a fase atual como concluída
      final faseAtualConcluida = FaseProcesso(
        concluida: true,
        dataInicio:
            _processo.fases[_processo.faseAtual]?.dataInicio ?? DateTime.now(),
        dataConclusao: DateTime.now(),
        observacoes: _processo.fases[_processo.faseAtual]?.observacoes,
        responsavel: _processo.fases[_processo.faseAtual]?.responsavel,
      );

      // Criar a nova fase como "em andamento"
      final novaFase = FaseProcesso(
        concluida: false, // Nova fase inicia como "em andamento"
        dataInicio: DateTime.now(),
        dataConclusao: null, // Sem data de conclusão ainda
        observacoes: observacoes,
      );

      // Atualizar ambas as fases
      await db.atualizarFaseProcesso(
        _processo.id,
        _processo.faseAtual,
        faseAtualConcluida,
      );
      await db.atualizarFaseProcesso(_processo.id, proximaFase, novaFase);

      // Atualizar processo local
      final fasesAtualizadas = Map<FaseProcessoAquisicao, FaseProcesso>.from(
        _processo.fases,
      );
      fasesAtualizadas[_processo.faseAtual] = faseAtualConcluida;
      fasesAtualizadas[proximaFase] = novaFase;

      setState(() {
        _processo = _processo.copyWith(
          faseAtual: proximaFase,
          fases: fasesAtualizadas,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fase atualizada para: ${proximaFase.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar fase: $e')));
      }
    }
  }

  Future<void> _editarObservacoesFase(FaseProcessoAquisicao fase) async {
    final dadosFaseAtual = _processo.fases[fase];
    final observacoesAtuais = dadosFaseAtual?.observacoes ?? '';

    final observacoes = await _solicitarObservacoes(fase, observacoesAtuais);

    if (observacoes == null) return; // Usuário cancelou

    try {
      final db = FirestoreHelper();
      final faseAtualizada = FaseProcesso(
        concluida: dadosFaseAtual?.concluida ?? false, // Mantém o status atual
        dataInicio: dadosFaseAtual?.dataInicio ?? DateTime.now(),
        dataConclusao:
            dadosFaseAtual?.dataConclusao, // Mantém a data de conclusão atual
        observacoes: observacoes,
        responsavel: dadosFaseAtual?.responsavel,
      );

      await db.atualizarFaseProcesso(_processo.id, fase, faseAtualizada);

      // Atualizar processo local
      final fasesAtualizadas = Map<FaseProcessoAquisicao, FaseProcesso>.from(
        _processo.fases,
      );
      fasesAtualizadas[fase] = faseAtualizada;

      setState(() {
        _processo = _processo.copyWith(fases: fasesAtualizadas);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Observações da fase ${fase.displayName} atualizadas',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar observações: $e')),
        );
      }
    }
  }

  Future<String?> _solicitarObservacoes(
    FaseProcessoAquisicao fase, [
    String? observacoesExistentes,
  ]) async {
    final controller = TextEditingController(text: observacoesExistentes ?? '');

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Observações - ${fase.displayName}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Digite as observações para ${fase.displayName}',
            border: const OutlineInputBorder(),
            helperText: 'Você pode editar as observações a qualquer momento',
          ),
          maxLines: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(
              observacoesExistentes != null ? 'Atualizar' : 'Confirmar',
            ),
          ),
        ],
      ),
    );
  }

  void _verStatusProdutos() {
    Navigator.of(context).pop(); // Fechar o dialog atual
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MemoriasCalculoStatusScreen(),
      ),
    );
  }

  Future<void> _concluirProcesso() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Concluir Processo'),
        content: const Text(
          'Tem certeza que deseja concluir este processo de aquisição? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final db = FirestoreHelper();
      await db.concluirProcessoAquisicao(_processo.id);

      setState(() {
        _processo = _processo.copyWith(
          status: StatusProcessoAquisicao.concluido,
          dataConclusao: DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Processo concluído! Status dos produtos atualizado para "Adquirido".',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir processo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _processo.titulo,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status e fase atual
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCorStatus(_processo.status),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _processo.status.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCorFase(_processo.faseAtual),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _processo.faseAtual.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Fases do processo
                  const Text(
                    'Fases do Processo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: ListView.builder(
                      itemCount: FaseProcessoAquisicao.values.length,
                      itemBuilder: (context, index) {
                        final fase = FaseProcessoAquisicao.values[index];
                        final dadosFase = _processo.fases[fase];
                        final isAtual = fase == _processo.faseAtual;
                        final isConcluida = dadosFase?.concluida ?? false;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isAtual ? Colors.blue[50] : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isConcluida
                                  ? Colors.green
                                  : isAtual
                                  ? Colors.blue
                                  : Colors.grey,
                              child: Icon(
                                isConcluida
                                    ? Icons.check
                                    : isAtual
                                    ? Icons.play_arrow
                                    : Icons.radio_button_unchecked,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              fase.displayName,
                              style: TextStyle(
                                fontWeight: isAtual
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(fase.descricao),
                                if (dadosFase?.observacoes != null &&
                                    dadosFase!.observacoes!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Obs: ${dadosFase.observacoes!}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                if (dadosFase?.dataConclusao != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Concluído em: ${_formatarData(dadosFase!.dataConclusao!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  onPressed: () => _editarObservacoesFase(fase),
                                  tooltip: 'Editar Observações',
                                  color: Colors.blue,
                                ),
                                if (isAtual &&
                                    _processo.status ==
                                        StatusProcessoAquisicao.ativo)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                    ),
                                    onPressed: _avancarFase,
                                    tooltip: 'Avançar Fase',
                                    color: Colors.green,
                                  ),
                                if (fase == FaseProcessoAquisicao.publicado &&
                                    (isConcluida || isAtual))
                                  IconButton(
                                    icon: const Icon(
                                      Icons.visibility,
                                      size: 18,
                                    ),
                                    onPressed: _verStatusProdutos,
                                    tooltip: 'Ver Status dos Produtos',
                                    color: Colors.purple,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ação de conclusão (apenas quando na fase "Publicado")
                  if (_processo.status == StatusProcessoAquisicao.ativo &&
                      _processo.faseAtual == FaseProcessoAquisicao.publicado)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _concluirProcesso,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Concluir Processo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
      ),
    );
  }

  Color _getCorStatus(StatusProcessoAquisicao status) {
    switch (status) {
      case StatusProcessoAquisicao.ativo:
        return Colors.blue;
      case StatusProcessoAquisicao.concluido:
        return Colors.green;
      case StatusProcessoAquisicao.cancelado:
        return Colors.red;
    }
  }

  Color _getCorFase(FaseProcessoAquisicao fase) {
    switch (fase) {
      case FaseProcessoAquisicao.processoIniciado:
        return Colors.blue;
      case FaseProcessoAquisicao.editalPublicado:
        return Colors.orange;
      case FaseProcessoAquisicao.analisePropostas:
        return Colors.purple;
      case FaseProcessoAquisicao.resultadoFinal:
        return Colors.indigo;
      case FaseProcessoAquisicao.publicado:
        return Colors.green;
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
