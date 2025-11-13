import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/memoria_calculo.dart';
import '../../models/processo_aquisicao.dart';
import '../../models/quadro_tecnico_descritivo.dart';
import '../../models/regiao.dart';

class ControleSaldoContratoScreen extends StatefulWidget {
  final AnoLetivo anoLetivo;

  const ControleSaldoContratoScreen({super.key, required this.anoLetivo});

  @override
  State<ControleSaldoContratoScreen> createState() =>
      _ControleSaldoContratoScreenState();
}

class _ControleSaldoContratoScreenState
    extends State<ControleSaldoContratoScreen> {
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _carregando = true;
  final Map<String, List<_QuadroResumo>> _quadrosPorMemoria = {};
  final Map<String, MemoriaCalculo> _memoriasMap = {};
  List<Regiao> _regioes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    try {
      final db = FirestoreHelper();
      final memorias = await db.getMemoriasCalculoPorAno(
        widget.anoLetivo.ano.toString(),
      );
      final regioes = await db.getRegioes();

      final Map<String, List<_QuadroResumo>> agrupado = {};
      final Map<String, MemoriaCalculo> memoriasMap = {
        for (final memoria in memorias) memoria.id: memoria,
      };

      for (final memoria in memorias) {
        final processos = await db.getProcessosAquisicaoPorMemoria(memoria.id);

        for (final processo in processos) {
          final quadros = await db.getQuadrosTecnicosPorProcesso(processo.id);
          for (final qtd in quadros) {
            agrupado.putIfAbsent(memoria.id, () => []);
            agrupado[memoria.id]!.add(
              _QuadroResumo(
                memoria: memoria,
                processo: processo,
                qtd: qtd,
              ),
            );
          }
        }
      }

      setState(() {
        _quadrosPorMemoria
          ..clear()
          ..addAll(agrupado);
        _memoriasMap
          ..clear()
          ..addAll(memoriasMap);
        _regioes = regioes;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      debugPrint(
        '[ControleSaldoContrato] Erro ao carregar dados: $e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Controle de Saldo • ${widget.anoLetivo.ano}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _quadrosPorMemoria.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 72,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum Quadro Técnico Descritivo encontrado\npara o ano ${widget.anoLetivo.ano}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _quadrosPorMemoria.entries
                      .map((entry) => _buildMemoriaSection(entry.key, entry.value))
                      .toList(),
                ),
    );
  }

  Widget _buildMemoriaSection(
    String memoriaId,
    List<_QuadroResumo> quadros,
  ) {
    final memoria = _memoriasMap[memoriaId];
    if (memoria == null) return const SizedBox();

    quadros.sort(
      (a, b) => a.qtd.numeroAtaJulgamento.compareTo(b.qtd.numeroAtaJulgamento),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          'Memória ${memoria.numero} • ${memoria.titulo}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${quadros.length} QTD(s) registrados',
          style: const TextStyle(fontSize: 12),
        ),
        children: quadros
            .map((resumo) => _buildQuadroTile(resumo))
            .toList(),
      ),
    );
  }

  Widget _buildQuadroTile(_QuadroResumo resumo) {
    final fornecedor =
        resumo.qtd.fornecedores.isNotEmpty ? resumo.qtd.fornecedores.first : null;
    final total = resumo.qtd.fornecedores.fold<double>(
      0,
      (valor, fornecedor) => valor + fornecedor.subtotalValor,
    );

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.brown[100],
        child: Icon(Icons.receipt_long, color: Colors.brown[700]),
      ),
      title: Text('QTD - Ata ${resumo.qtd.numeroAtaJulgamento}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fornecedor != null) Text('Fornecedor: ${fornecedor.nome}'),
          Text('Processo: ${resumo.processo.titulo}'),
          Text(
            'Registrado em: ${DateFormat('dd/MM/yyyy').format(resumo.qtd.dataAta)}',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${resumo.qtd.fornecedores.fold<int>(0, (acc, f) => acc + f.itens.length)} item(ns)',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: () => _visualizarQtdCompleto(resumo),
    );
  }

  void _visualizarQtdCompleto(_QuadroResumo resumo) {
    showDialog(
      context: context,
      builder: (context) => _QtdDetailDialog(
        qtd: resumo.qtd,
        regioes: _regioes,
      ),
    );
  }
}

class _QuadroResumo {
  final MemoriaCalculo memoria;
  final ProcessoAquisicao processo;
  final QuadroTecnicoDescritivo qtd;

  _QuadroResumo({
    required this.memoria,
    required this.processo,
    required this.qtd,
  });
}

class _QtdDetailDialog extends StatelessWidget {
  final QuadroTecnicoDescritivo qtd;
  final List<Regiao> regioes;

  const _QtdDetailDialog({
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

    return Dialog(
      child: Container(
        width: 900,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, size: 28, color: Colors.indigo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Quadro Técnico Descritivo (QTD)',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Número da Ata: ${qtd.numeroAtaJulgamento} • Fonte: ${qtd.fonte}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...qtd.fornecedores.map(
                      (fornecedor) => _TabelaFornecedorQtd(
                        fornecedor: fornecedor,
                        mapaRegioes: mapaRegioes,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total do QTD: ${_currencyFormat.format(totalQtd)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabelaFornecedorQtd extends StatelessWidget {
  final FornecedorQtd fornecedor;
  final Map<String, String> mapaRegioes;

  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final NumberFormat _quantityFormat =
      NumberFormat('#,##0.000', 'pt_BR');

  const _TabelaFornecedorQtd({
    required this.fornecedor,
    required this.mapaRegioes,
  });

  @override
  Widget build(BuildContext context) {
    final List<TableRow> linhas = [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey[200]),
        children: [
          _HeaderCellQtd('Região'),
          _HeaderCellQtd('Item'),
          _HeaderCellQtd('Produto'),
          _HeaderCellQtd('Valor unitário (R\$)'),
          _HeaderCellQtd('Cota Principal (kg)'),
          _HeaderCellQtd('Cota Reservada (kg)'),
          _HeaderCellQtd('Quantidade total (kg)'),
          _HeaderCellQtd('Valor total (R\$)'),
        ],
      ),
    ];

    // Coletar todas as regiões únicas e ordená-las
    final Set<String> regioesUnicas = {};
    for (final item in fornecedor.itens) {
      regioesUnicas.addAll(item.cotaPrincipalPorRegiaoKg.keys);
      regioesUnicas.addAll(item.cotaReservadaPorRegiaoKg.keys);
    }
    final regioesOrdenadas = regioesUnicas.toList()
      ..sort((a, b) => (mapaRegioes[a] ?? a).compareTo(mapaRegioes[b] ?? b));

    // Para cada região, mostrar todos os itens dessa região
    for (final regiaoId in regioesOrdenadas) {
      final nomeRegiao = mapaRegioes[regiaoId] ?? regiaoId;
      double subtotalRegiao = 0.0;

      // Mostrar todos os itens que têm quantidade nesta região
      for (final item in fornecedor.itens) {
        final cotaPrincipal = item.cotaPrincipalPorRegiaoKg[regiaoId] ?? 0.0;
        final cotaReservada = item.cotaReservadaPorRegiaoKg[regiaoId] ?? 0.0;
        final quantidadeTotalRegiao = cotaPrincipal + cotaReservada;
        
        if (quantidadeTotalRegiao > 0) {
          // Calcular o valor desta região: quantidade total * valor unitário
          final valorRegiao = quantidadeTotalRegiao * item.valorUnitarioReais;
          subtotalRegiao += valorRegiao;

          linhas.add(
            TableRow(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
              children: [
                _BodyCellQtd(nomeRegiao),
                _BodyCellQtd('Item ${item.numeroItemEdital}'),
                _BodyCellQtd(item.produtoNome),
                _BodyCellQtd(_currencyFormat.format(item.valorUnitarioReais)),
                _BodyCellQtd(_quantityFormat.format(cotaPrincipal)),
                _BodyCellQtd(_quantityFormat.format(cotaReservada)),
                _BodyCellQtd(_quantityFormat.format(item.quantidadeTotalKg)),
                _BodyCellQtd(_currencyFormat.format(item.valorTotalReais)),
              ],
            ),
          );
        }
      }

      // Adicionar linha de subtotal da região
      linhas.add(
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: const Border(
              top: BorderSide(color: Colors.grey, width: 1.5),
              bottom: BorderSide(color: Colors.grey, width: 1.5),
            ),
          ),
          children: [
            _FooterCellQtd('Subtotal $nomeRegiao'),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            _FooterCellQtd(_currencyFormat.format(subtotalRegiao)),
          ],
        ),
      );
    }

    // Subtotal geral do fornecedor
    linhas.add(
      TableRow(
        decoration: BoxDecoration(
          color: Colors.blueGrey[100],
          border: const Border(
            top: BorderSide(color: Colors.blueGrey, width: 2),
          ),
        ),
        children: [
          _FooterCellQtd('Subtotal ${fornecedor.nome}'),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          const SizedBox(),
          _FooterCellQtd(_currencyFormat.format(fornecedor.subtotalValor)),
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

class _HeaderCellQtd extends StatelessWidget {
  final String texto;

  const _HeaderCellQtd(this.texto);

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

class _BodyCellQtd extends StatelessWidget {
  final String texto;

  const _BodyCellQtd(this.texto);

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

class _FooterCellQtd extends StatelessWidget {
  final String texto;

  const _FooterCellQtd(this.texto);

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

