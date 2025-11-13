import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../database/firestore_helper.dart';
import '../../../models/quadro_tecnico_descritivo.dart';
import '../../../models/processo_aquisicao.dart';
import '../../../models/regiao.dart';
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
  List<Regiao> _regioes = [];
  List<QuadroTecnicoDescritivo> _quadrosTecnicos = [];

  @override
  void initState() {
    super.initState();
    _processo = widget.processo;
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    try {
      final db = FirestoreHelper();
      final regioesDb = await db.getRegioes();
      final quadros = await db.getQuadrosTecnicosPorProcesso(_processo.id);

      if (!mounted) return;

      setState(() {
        _regioes = regioesDb;
        _quadrosTecnicos = quadros;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados do processo: $e')),
      );
    }
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
                    child: ListView(
                      children: [
                        ...FaseProcessoAquisicao.values.map(
                          (fase) {
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
                                      onPressed: () =>
                                          _editarObservacoesFase(fase),
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
                                    if (fase ==
                                            FaseProcessoAquisicao.publicado &&
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
                        if (_quadrosTecnicos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Quadros Técnicos Descritivos (QTD)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._quadrosTecnicos.map(
                            (qtd) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ResumoQtdWidget(
                                qtd: qtd,
                                regioes: _regioes,
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber[200]!),
                            ),
                            child: const Text(
                              'Nenhum QTD registrado ainda. A GPAE é responsável por registrar os quadros técnicos a partir desta fase.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ],
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

class _ResumoQtdWidget extends StatelessWidget {
  final QuadroTecnicoDescritivo qtd;
  final List<Regiao> regioes;

  const _ResumoQtdWidget({
    required this.qtd,
    required this.regioes,
  });

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final mapaRegioes = {for (final regiao in regioes) regiao.id: regiao.nome};
    final totalQtd = qtd.fornecedores.fold<double>(
      0,
      (valor, fornecedor) => valor + fornecedor.subtotalValor,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${qtd.tipoAta.displayName} • Número: ${qtd.numeroAtaJulgamento} • Fonte: ${qtd.fonte}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            ...qtd.fornecedores.map(
              (fornecedor) => _TabelaFornecedor(
                fornecedor: fornecedor,
                mapaRegioes: mapaRegioes,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total do QTD: ${_currencyFormat.format(totalQtd)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabelaFornecedor extends StatelessWidget {
  final FornecedorQtd fornecedor;
  final Map<String, String> mapaRegioes;

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final NumberFormat _quantityFormat =
      NumberFormat('#,##0.000', 'pt_BR');

  const _TabelaFornecedor({
    required this.fornecedor,
    required this.mapaRegioes,
  });

  @override
  Widget build(BuildContext context) {
    final List<TableRow> linhas = [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey[200]),
        children: [
          _HeaderCell('Região'),
          _HeaderCell('Item'),
          _HeaderCell('Produto'),
          _HeaderCell('Valor unitário (R\$)'),
          _HeaderCell('Cota Principal (kg)'),
          _HeaderCell('Cota Reservada (kg)'),
          _HeaderCell('Quantidade total (kg)'),
          _HeaderCell('Valor total (R\$)'),
        ],
      ),
    ];

    // Coletar todas as regiões únicas
    final Set<String> regioesUnicas = {};
    for (final item in fornecedor.itens) {
      regioesUnicas.addAll(item.cotaPrincipalPorRegiaoKg.keys);
      regioesUnicas.addAll(item.cotaReservadaPorRegiaoKg.keys);
    }
    final regioesOrdenadas = regioesUnicas.toList()
      ..sort((a, b) => (mapaRegioes[a] ?? a).compareTo(mapaRegioes[b] ?? b));

    for (final regiaoId in regioesOrdenadas) {
      for (final item in fornecedor.itens) {
        final cotaPrincipal = item.cotaPrincipalPorRegiaoKg[regiaoId] ?? 0.0;
        final cotaReservada = item.cotaReservadaPorRegiaoKg[regiaoId] ?? 0.0;
        final quantidadeTotalRegiao = cotaPrincipal + cotaReservada;

        if (quantidadeTotalRegiao > 0) {
          linhas.add(
            TableRow(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              children: [
                _BodyCell(mapaRegioes[regiaoId] ?? regiaoId),
                _BodyCell('Item ${item.numeroItemEdital}'),
                _BodyCell(item.produtoNome),
                _BodyCell(_currencyFormat.format(item.valorUnitarioReais)),
                _BodyCell(_quantityFormat.format(cotaPrincipal)),
                _BodyCell(_quantityFormat.format(cotaReservada)),
                _BodyCell(_quantityFormat.format(item.quantidadeTotalKg)),
                _BodyCell(_currencyFormat.format(item.valorTotalReais)),
              ],
            ),
          );
        }
      }
    }

    linhas.add(
      TableRow(
        children: [
          _FooterCell('Subtotal ${fornecedor.nome}'),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          _FooterCell(_currencyFormat.format(fornecedor.subtotalValor)),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Text(
              fornecedor.nome,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(120),
                1: FixedColumnWidth(90),
                2: FixedColumnWidth(220),
                3: FixedColumnWidth(140),
                4: FixedColumnWidth(150),
                5: FixedColumnWidth(150),
                6: FixedColumnWidth(180),
                7: FixedColumnWidth(160),
              },
              children: linhas,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String texto;

  const _HeaderCell(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String texto;

  const _BodyCell(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}

class _FooterCell extends StatelessWidget {
  final String texto;

  const _FooterCell(this.texto);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
