import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/fornecedor.dart';
import '../../models/memoria_calculo.dart';
import '../../models/processo_aquisicao.dart';
import '../../models/produto.dart';
import '../../models/quadro_tecnico_descritivo.dart';
import '../../models/regiao.dart';
import '../diae/widgets/registrar_quadro_tecnico_dialog.dart';

class MemoriaCalculoQtdScreen extends StatefulWidget {
  final AnoLetivo anoLetivo;
  final MemoriaCalculo memoria;
  final List<Produto> produtos;
  final List<Regiao> regioes;

  const MemoriaCalculoQtdScreen({
    super.key,
    required this.anoLetivo,
    required this.memoria,
    required this.produtos,
    required this.regioes,
  });

  @override
  State<MemoriaCalculoQtdScreen> createState() =>
      _MemoriaCalculoQtdScreenState();
}

class _MemoriaCalculoQtdScreenState extends State<MemoriaCalculoQtdScreen> {
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool _carregando = true;
  bool _processaAcao = false;

  List<ProcessoAquisicao> _processos = [];
  ProcessoAquisicao? _processoSelecionado;
  List<QuadroTecnicoDescritivo> _quadros = [];
  List<Fornecedor> _fornecedores = [];

  final Set<String> _produtosSelecionados = {};
  Fornecedor? _fornecedorSelecionado;

  String? _mensagemRestricao;

  List<Produto> get _produtosMemoria {
    final ids = widget.memoria.produtosSelecionados.toSet();
    return widget.produtos.where((produto) => ids.contains(produto.id)).toList();
  }

  @override
  void initState() {
    super.initState();
    _inicializarSelecaoProdutos();
    _carregarDados();
  }

  void _inicializarSelecaoProdutos() {
    _produtosSelecionados.clear();
    for (final produto in _produtosMemoria) {
      final status = widget.memoria.getStatusProduto(produto.id);
      if (status == StatusProdutoMemoria.adquirido) {
        _produtosSelecionados.add(produto.id);
      }
    }
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _mensagemRestricao = null;
    });

    try {
      final db = FirestoreHelper();
      final processos = await db.getProcessosAquisicaoPorMemoria(
        widget.memoria.id,
      );

      final fornecedores = await db.getFornecedores();
      String? mensagemRestricao;

      ProcessoAquisicao? processoSelecionado = _processoSelecionado;
      if (processoSelecionado != null) {
        processoSelecionado = processos.firstWhere(
          (p) => p.id == processoSelecionado!.id,
          orElse: () => processoSelecionado!,
        );
      } else if (processos.isNotEmpty) {
        final publicados = processos.where(
          (p) => p.faseAtual == FaseProcessoAquisicao.publicado,
        );
        processoSelecionado =
            publicados.isNotEmpty ? publicados.first : processos.first;
      }

      List<QuadroTecnicoDescritivo> quadros = [];
      if (processoSelecionado != null) {
        quadros = await db.getQuadrosTecnicosPorProcesso(
          processoSelecionado.id,
        );

        if (processoSelecionado.faseAtual !=
            FaseProcessoAquisicao.publicado) {
          mensagemRestricao =
              'O processo selecionado ainda não está na fase "Publicado". O registro de QTD ficará disponível assim que a DIAE avançar o processo.';
        }
      } else {
        mensagemRestricao =
            'Nenhum processo de aquisição foi encontrado para esta memória. Aguardando a DIAE iniciar e avançar o processo até a fase "Publicado".';
      }

      setState(() {
        _inicializarSelecaoProdutos();
        _processos = processos;
        _processoSelecionado = processoSelecionado;
        _quadros = quadros;
        _fornecedores = fornecedores;
        _mensagemRestricao = mensagemRestricao;
        _fornecedorSelecionado = fornecedores.isNotEmpty
            ? fornecedores.firstWhere(
                (f) => _fornecedorSelecionado?.id == f.id,
                orElse: () =>
                    _fornecedorSelecionado ?? fornecedores.first,
              )
            : null;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  bool get _podeRegistrarQtd {
    if (_processoSelecionado == null) return false;
    if (_processoSelecionado!.faseAtual != FaseProcessoAquisicao.publicado) {
      return false;
    }
    if (_produtosSelecionados.isEmpty) return false;
    if (_fornecedorSelecionado == null) return false;
    return true;
  }

  Future<void> _criarQtd() async {
    final processo = _processoSelecionado;
    final fornecedor = _fornecedorSelecionado;

    if (!_podeRegistrarQtd || processo == null || fornecedor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione ao menos um produto adquirido e um fornecedor para criar o QTD.',
          ),
        ),
      );
      return;
    }

    final produtosSelecionados = _produtosMemoria
        .where((p) => _produtosSelecionados.contains(p.id))
        .toList();

    setState(() => _processaAcao = true);

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RegistrarQuadroTecnicoDialog(
        processo: processo,
        memoria: widget.memoria,
        produtosSelecionados: produtosSelecionados,
        regioes: widget.regioes,
        fornecedorInicial: fornecedor,
        quadroExistente: null,
        permitirMultiplosFornecedores: false,
      ),
    );

    setState(() => _processaAcao = false);

    if (resultado == true) {
      await _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QTD registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editarQtd(QuadroTecnicoDescritivo qtd) async {
    final processo = _processoSelecionado;
    if (processo == null) return;

    final produtosParaEdicao = _produtosMemoria;
    final fornecedorAtual = _fornecedores.firstWhere(
      (f) => f.id == (qtd.fornecedores.isNotEmpty ? qtd.fornecedores.first.id : ''),
      orElse: () => _fornecedorSelecionado ?? (_fornecedores.isNotEmpty ? _fornecedores.first : Fornecedor(id: qtd.fornecedores.first.id, nome: qtd.fornecedores.first.nome)),
    );

    setState(() => _processaAcao = true);

    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RegistrarQuadroTecnicoDialog(
        processo: processo,
        memoria: widget.memoria,
        produtosSelecionados: produtosParaEdicao,
        regioes: widget.regioes,
        quadroExistente: qtd,
        fornecedorInicial: fornecedorAtual,
        permitirMultiplosFornecedores: false,
      ),
    );

    setState(() => _processaAcao = false);

    if (resultado == true) {
      await _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QTD atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _excluirQtd(QuadroTecnicoDescritivo qtd) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir QTD'),
        content: const Text(
          'Confirma a exclusão deste Quadro Técnico Descritivo? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      setState(() => _processaAcao = true);
      await FirestoreHelper().deleteQuadroTecnico(qtd.id);
      await _carregarDados();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QTD excluído.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir QTD: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processaAcao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'QTD • ${widget.anoLetivo.ano} • Memória ${widget.memoria.numero.toString().padLeft(2, '0')}',
        ),
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
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProcessoSection(),
                  const SizedBox(height: 16),
                  if (_mensagemRestricao != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Text(
                        _mensagemRestricao!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSelecaoProdutos(),
                          const SizedBox(height: 16),
                          _buildSelecaoFornecedor(),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _processaAcao || !_podeRegistrarQtd
                                      ? null
                                      : _criarQtd,
                              icon: _processaAcao
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.receipt_long_outlined),
                              label: Text(
                                _processaAcao ? 'Processando...' : 'Criar QTD',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildQuadrosRegistrados(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProcessoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.ballot_outlined, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Processo de Aquisição vinculado à memória',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_processos.isEmpty)
              const Text(
                'Nenhum processo de aquisição vinculado até o momento.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _processoSelecionado?.id,
                    decoration: const InputDecoration(
                      labelText: 'Processo',
                      border: OutlineInputBorder(),
                    ),
                    items: _processos
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(
                              '${p.titulo} • ${p.faseAtual.displayName}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (valor) {
                      if (valor == null) return;
                      final processo = _processos.firstWhere(
                        (p) => p.id == valor,
                      );
                      setState(() {
                        _processoSelecionado = processo;
                      });
                      _carregarDados();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_processoSelecionado != null)
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _ChipInfo(
                          icon: Icons.flag_outlined,
                          label:
                              'Fase: ${_processoSelecionado!.faseAtual.displayName}',
                          color: Colors.indigo,
                        ),
                        if (_processoSelecionado!.observacoes?.isNotEmpty ??
                            false)
                          _ChipInfo(
                            icon: Icons.note_alt_outlined,
                            label: 'Observações disponíveis',
                            color: Colors.deepOrange,
                          ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoProdutos() {
    final produtos = _produtosMemoria;
    if (produtos.isEmpty) {
      return const SizedBox();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produtos da memória',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione os produtos (status "Adquirido") que serão contemplados neste QTD.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: produtos.map((produto) {
                final status = widget.memoria.getStatusProduto(produto.id);
                final habilitado =
                    status == StatusProdutoMemoria.adquirido;

                return FilterChip(
                  label: Text(produto.nome),
                  selected: _produtosSelecionados.contains(produto.id),
                  onSelected: habilitado
                      ? (selecionado) {
                          setState(() {
                            if (selecionado) {
                              _produtosSelecionados.add(produto.id);
                            } else {
                              _produtosSelecionados.remove(produto.id);
                            }
                          });
                        }
                      : null,
                  avatar: Icon(
                    habilitado
                        ? Icons.check_circle_outline
                        : Icons.lock_outline,
                    size: 18,
                    color:
                        habilitado ? Colors.green[600] : Colors.grey[500],
                  ),
                  backgroundColor: habilitado
                      ? Colors.green[50]
                      : Colors.grey[200],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelecaoFornecedor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fornecedor responsável pelo QTD',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_fornecedores.isEmpty)
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nenhum fornecedor cadastrado. Cadastre fornecedores antes de registrar QTDs.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.orange[800]),
                    ),
                  ),
                ],
              )
            else
              DropdownButtonFormField<String>(
                value: _fornecedorSelecionado?.id,
                decoration: const InputDecoration(
                  labelText: 'Fornecedor',
                  border: OutlineInputBorder(),
                ),
                items: _fornecedores
                    .map(
                      (f) => DropdownMenuItem(
                        value: f.id,
                        child: Text(f.nome),
                      ),
                    )
                    .toList(),
                onChanged: (valor) {
                  if (valor == null) return;
                  final fornecedor = _fornecedores.firstWhere(
                    (f) => f.id == valor,
                  );
                  setState(() => _fornecedorSelecionado = fornecedor);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrosRegistrados() {
    if (_quadros.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quadros Técnicos Descritivos registrados',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nenhum QTD cadastrado ainda para esta memória.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quadros Técnicos Descritivos registrados',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._quadros.map(
          (qtd) {
            final fornecedor = qtd.fornecedores.isNotEmpty
                ? qtd.fornecedores.first
                : null;
            final total = qtd.fornecedores.fold<double>(
              0,
              (valor, f) => valor + f.subtotalValor,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.brown[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'QTD - Ata ${qtd.numeroAtaJulgamento}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(qtd.dataAta),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (fornecedor != null)
                      Text(
                        'Fornecedor: ${fornecedor.nome}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Valor total estimado: ${_currencyFormat.format(total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _processaAcao
                              ? null
                              : () => _editarQtd(qtd),
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _processaAcao
                              ? null
                              : () => _excluirQtd(qtd),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ChipInfo({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}

