import 'package:flutter/material.dart';

import '../../../models/escola.dart';
import '../../../models/quantidade_refeicao.dart';

class DadosAlunosDialog extends StatefulWidget {
  final String escolaId;
  final String anoLetivo;
  final int numeroDistribuicao;
  final List<QuantidadeRefeicao> quantidadesRefeicao;
  final DadosAlunos dadosExistentes;
  final ModalidadeEnsino? modalidadeFiltro;
  final bool dadosCopiados;

  const DadosAlunosDialog({
    super.key,
    required this.escolaId,
    required this.anoLetivo,
    required this.numeroDistribuicao,
    required this.quantidadesRefeicao,
    required this.dadosExistentes,
    this.modalidadeFiltro,
    this.dadosCopiados = false,
  });

  @override
  State<DadosAlunosDialog> createState() => _DadosAlunosDialogState();
}

class _DadosAlunosDialogState extends State<DadosAlunosDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Map<String, Map<String, int>> _quantidadesRefeicoes = {};

  @override
  void initState() {
    super.initState();
    _inicializarControllers();
  }

  void _inicializarControllers() {
    final modalidades = widget.modalidadeFiltro != null
        ? [widget.modalidadeFiltro!]
        : ModalidadeEnsino.values;

    for (final modalidade in modalidades) {
      _controllers[modalidade.name] = {};
      _quantidadesRefeicoes[modalidade.name] = {};

      // Controller para matriculados
      _controllers[modalidade.name]!['matriculados'] = TextEditingController(
        text:
            widget.dadosExistentes.modalidades[modalidade.name]?.matriculados
                .toString() ??
            '0',
      );

      // Controllers para cada Tipo de refeição
      for (final quantidade in widget.quantidadesRefeicao.where(
        (q) => q.ativo,
      )) {
        final valor =
            widget
                .dadosExistentes
                .modalidades[modalidade.name]
                ?.quantidadeRefeicoes[quantidade.id] ??
            0;

        _controllers[modalidade.name]![quantidade.id] = TextEditingController(
          text: valor.toString(),
        );
        _quantidadesRefeicoes[modalidade.name]![quantidade.id] = valor;
      }
    }
  }

  @override
  void dispose() {
    for (final modalidade in _controllers.values) {
      for (final controller in modalidade.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _salvar({bool enviar = false}) {
    if (_formKey.currentState!.validate()) {
      final modalidades = <String, DadosModalidade>{};
      final erros = <String>[];

      for (final modalidade in ModalidadeEnsino.values) {
        final matriculados =
            int.tryParse(
              _controllers[modalidade.name]!['matriculados']!.text,
            ) ??
            0;
        final quantidadeRefeicoes = <String, int>{};
        var somaAlunos = 0;

        for (final quantidade in widget.quantidadesRefeicao.where(
          (q) => q.ativo,
        )) {
          final valor =
              int.tryParse(
                _controllers[modalidade.name]![quantidade.id]!.text,
              ) ??
              0;
          if (valor > 0) {
            quantidadeRefeicoes[quantidade.id] = valor;
            somaAlunos += valor;
          }
        }

        // Validar se soma não excede matriculados
        if (somaAlunos > matriculados && matriculados > 0) {
          erros.add(
            '${modalidade.displayName}: $somaAlunos alunos fazem refeição, mas apenas $matriculados estão matriculados',
          );
        }

        modalidades[modalidade.name] = DadosModalidade(
          modalidade: modalidade.name,
          matriculados: matriculados,
          quantidadeRefeicoes: quantidadeRefeicoes,
        );
      }

      // Se houver erros, mostrar alerta
      if (erros.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚠️ Atenção'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'A quantidade de alunos que fazem refeição não pode ser maior que os matriculados:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...erros.map(
                  (erro) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $erro'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final dadosAlunos = DadosAlunos(
        id: widget.dadosExistentes.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : widget.dadosExistentes.id,
        escolaId: widget.escolaId,
        distribuicaoId: widget.dadosExistentes.distribuicaoId,
        anoLetivo: widget.anoLetivo,
        numeroDistribuicao: widget.numeroDistribuicao,
        modalidades: modalidades,
        dataAtualizacao: DateTime.now(),
        enviado: enviar,
      );

      Navigator.of(context).pop({'dados': dadosAlunos, 'enviado': enviar});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Quantidade de Alunos',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Informe a quantidade de alunos matriculados e quantos fazem cada tipo de refeição',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (widget.dadosCopiados) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Os dados foram pré-preenchidos com base na distribuição anterior. Você pode editá-los se necessário.',
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linhas para cada modalidade
                      ...(widget.modalidadeFiltro != null
                              ? [widget.modalidadeFiltro!]
                              : ModalidadeEnsino.values)
                          .map((modalidade) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Cabeçalho da modalidade com Matriculados
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          modalidade.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Expanded(
                                              flex: 2,
                                              child: Text(
                                                'Matriculados:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: TextFormField(
                                                controller:
                                                    _controllers[modalidade
                                                        .name]!['matriculados'],
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      filled: true,
                                                      fillColor: Colors.white,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                      isDense: true,
                                                    ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Obrigatório';
                                                  }
                                                  final numero = int.tryParse(
                                                    value,
                                                  );
                                                  if (numero == null ||
                                                      numero < 0) {
                                                    return 'Inválido';
                                                  }
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Tipo  de Refeição
                                  const Text(
                                    'Quantidade de alunos que fazem refeição:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ...widget.quantidadesRefeicao
                                          .where((q) => q.ativo)
                                          .map((quantidade) {
                                            return Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                    ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      quantidade.sigla,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    TextFormField(
                                                      controller:
                                                          _controllers[modalidade
                                                              .name]![quantidade
                                                              .id],
                                                      keyboardType:
                                                          TextInputType.number,
                                                      textAlign:
                                                          TextAlign.center,
                                                      decoration: const InputDecoration(
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 8,
                                                            ),
                                                        isDense: true,
                                                        hintText: '0',
                                                      ),
                                                      onChanged: (value) {
                                                        setState(
                                                          () {},
                                                        ); // Atualizar soma
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Mostrar soma total
                                  Builder(
                                    builder: (context) {
                                      final matriculados =
                                          int.tryParse(
                                            _controllers[modalidade
                                                    .name]!['matriculados']!
                                                .text,
                                          ) ??
                                          0;

                                      var somaAlunos = 0;
                                      for (final qtd
                                          in widget.quantidadesRefeicao.where(
                                            (q) => q.ativo,
                                          )) {
                                        final valor =
                                            int.tryParse(
                                              _controllers[modalidade.name]![qtd
                                                      .id]!
                                                  .text,
                                            ) ??
                                            0;
                                        somaAlunos += valor;
                                      }

                                      final excedeu = somaAlunos > matriculados;

                                      return Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: excedeu
                                              ? Colors.red[50]
                                              : Colors.green[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Total de alunos que fazem refeição:',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: excedeu
                                                    ? Colors.red[700]
                                                    : Colors.green[700],
                                              ),
                                            ),
                                            Text(
                                              '$somaAlunos de $matriculados',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: excedeu
                                                    ? Colors.red[700]
                                                    : Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Obs: Cada aluno é contado apenas uma vez, mesmo fazendo múltiplas refeições',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[700],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ),
            ),

            // Totalizador Geral da Escola
            Builder(
              builder: (context) {
                int totalMatriculados = 0;
                final totaisPorQuantidade = <String, int>{};

                // Somar por modalidade
                for (final modalidade in ModalidadeEnsino.values) {
                  final matriculados =
                      int.tryParse(
                        _controllers[modalidade.name]?['matriculados']?.text ??
                            '',
                      ) ??
                      0;
                  totalMatriculados += matriculados;

                  // Somar alunos por Tipo de refeição
                  for (final qtd in widget.quantidadesRefeicao.where(
                    (q) => q.ativo,
                  )) {
                    final valor =
                        int.tryParse(
                          _controllers[modalidade.name]?[qtd.id]?.text ?? '',
                        ) ??
                        0;
                    totaisPorQuantidade[qtd.id] =
                        (totaisPorQuantidade[qtd.id] ?? 0) + valor;
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo[300]!, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.summarize,
                            color: Colors.indigo[700],
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'TOTALIZADOR GERAL DA ESCOLA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      // Total de Matriculados
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total de Matriculados:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.indigo[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              totalMatriculados.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Total por Tipo de refeição
                      const Text(
                        'Total por Tipo de Refeição:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: widget.quantidadesRefeicao
                            .where((q) => q.ativo)
                            .map((qtd) {
                              final total = totaisPorQuantidade[qtd.id] ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.indigo[200]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${qtd.sigla}:',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      total.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo[700],
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            // Botões
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _salvar(enviar: false),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Salvar Rascunho'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _salvar(enviar: true),
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Salvar e Enviar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                      ),
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
}
