import 'package:flutter/material.dart';

import '../../../models/escola.dart';
import '../../../models/quantidade_refeicao.dart';
import '../../../models/regiao.dart';

class DadosAlunosRegiaoWidget extends StatelessWidget {
  final String anoLetivo;
  final String? distribuicaoSelecionada;
  final List<Regiao> regioes;
  final Map<String, Map<String, Map<String, int>>>
  alunosPorRegiaoModalidadeQuantidade;
  final Map<String, Map<String, int>> matriculadosPorRegiaoModalidade;
  final List<QuantidadeRefeicao> quantidadesRefeicao;
  final VoidCallback? onSelecionarDistribuicao;
  final Function(String distribuicaoId)? onSelecionarDistribuicaoEspecifica;
  final List<Map<String, dynamic>>? distribuicoesComTotais;

  const DadosAlunosRegiaoWidget({
    super.key,
    required this.anoLetivo,
    this.distribuicaoSelecionada,
    required this.regioes,
    required this.alunosPorRegiaoModalidadeQuantidade,
    required this.matriculadosPorRegiaoModalidade,
    required this.quantidadesRefeicao,
    this.onSelecionarDistribuicao,
    this.onSelecionarDistribuicaoEspecifica,
    this.distribuicoesComTotais,
  });

  @override
  Widget build(BuildContext context) {
    final quantidadesAtivas = quantidadesRefeicao
        .where((q) => q.ativo)
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantidade de Alunos por Região e Programa de Trabalho',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Ano Letivo: $anoLetivo',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                          if (distribuicaoSelecionada != null) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    distribuicaoSelecionada == 'Valores Máximos'
                                    ? Colors.orange[100]
                                    : Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (distribuicaoSelecionada ==
                                      'Valores Máximos')
                                    Icon(
                                      Icons.trending_up,
                                      size: 14,
                                      color: Colors.orange[900],
                                    ),
                                  if (distribuicaoSelecionada ==
                                      'Valores Máximos')
                                    const SizedBox(width: 4),
                                  Text(
                                    distribuicaoSelecionada!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          distribuicaoSelecionada ==
                                              'Valores Máximos'
                                          ? Colors.orange[900]
                                          : Colors.blue[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onSelecionarDistribuicao != null)
                  IconButton(
                    icon: Icon(
                      distribuicaoSelecionada == null
                          ? Icons.filter_list
                          : Icons.arrow_back,
                    ),
                    onPressed: onSelecionarDistribuicao,
                    tooltip: distribuicaoSelecionada == null
                        ? 'Selecionar Distribuição'
                        : 'Voltar à Lista',
                  ),
              ],
            ),
            const Divider(height: 24),
            const SizedBox(height: 16),

            // Mostrar lista de distribuições com totais ou dados da distribuição selecionada
            if (distribuicaoSelecionada == null &&
                distribuicoesComTotais != null)
              _buildListaDistribuicoes(context, quantidadesAtivas)
            else if (distribuicaoSelecionada != null)
              // Lista de regiões da distribuição selecionada
              ...regioes.map((regiao) {
                final dadosRegiao =
                    alunosPorRegiaoModalidadeQuantidade[regiao.id] ?? {};

                return _buildRegiaoSection(
                  context,
                  regiao,
                  dadosRegiao,
                  matriculadosPorRegiaoModalidade[regiao.id] ?? {},
                  quantidadesAtivas,
                );
              })
            else
              const Center(
                child: Text(
                  'Nenhuma distribuição disponível',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegiaoSection(
    BuildContext context,
    Regiao regiao,
    Map<String, Map<String, int>> dadosRegiao,
    Map<String, int> matriculadosRegiao,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    // Calcular totais
    final Map<String, int> totaisPorModalidade = {};
    int totalGeral = 0;

    for (final modalidade in ModalidadeEnsino.values) {
      int totalModalidade = 0;
      final dadosModalidade = dadosRegiao[modalidade.name] ?? {};

      for (final qtd in quantidadesAtivas) {
        final qtdAlunos = dadosModalidade[qtd.id] ?? 0;
        totalModalidade += qtdAlunos;
      }

      totaisPorModalidade[modalidade.name] = totalModalidade;
      totalGeral += totalModalidade;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REGIÃO ${regiao.id} - ${regiao.nome}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (regiao.regionais.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'CREs: ${regiao.regionais.map((r) => r.nome).join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Tabela com dados por modalidade
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
            columns: [
              const DataColumn(
                label: Text(
                  'Programa de Trabalho',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Matriculados',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...quantidadesAtivas.map(
                (qtd) => DataColumn(
                  label: Text(
                    qtd.sigla,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const DataColumn(
                label: Text(
                  'Total Refeições',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: [
              ...ModalidadeEnsino.values.map((modalidade) {
                final dadosModalidade = dadosRegiao[modalidade.name] ?? {};
                final totalModalidade =
                    totaisPorModalidade[modalidade.name] ?? 0;
                final matriculados = matriculadosRegiao[modalidade.name] ?? 0;

                return DataRow(
                  cells: [
                    DataCell(Text(modalidade.displayName)),
                    DataCell(
                      Text(
                        matriculados.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    ...quantidadesAtivas.map(
                      (qtd) => DataCell(
                        Text(
                          (dadosModalidade[qtd.id] ?? 0).toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        totalModalidade.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                );
              }),
              // Linha de total
              DataRow(
                color: WidgetStateProperty.all(Colors.blue[50]),
                cells: [
                  const DataCell(
                    Text(
                      'TOTAL GERAL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Text(
                      matriculadosRegiao.values
                          .fold(0, (a, b) => a + b)
                          .toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'monospace',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ...quantidadesAtivas.map((qtd) {
                    int totalQtd = 0;
                    for (final modalidade in ModalidadeEnsino.values) {
                      final dadosModalidade =
                          dadosRegiao[modalidade.name] ?? {};
                      totalQtd += dadosModalidade[qtd.id] ?? 0;
                    }
                    return DataCell(
                      Text(
                        totalQtd.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }),
                  DataCell(
                    Text(
                      totalGeral.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildListaDistribuicoes(
    BuildContext context,
    List<QuantidadeRefeicao> quantidadesAtivas,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantidade de Alunos por Tipo de Refeição - Todas as Distribuições:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 16),

        // Tabela comparativa de todas as distribuições
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Cabeçalho da tabela
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Distribuição',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Matriculados',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Colunas dinâmicas para cada quantidade de alunos por tipo de refeição
                      ...quantidadesAtivas.map(
                        (qtd) => Expanded(
                          child: Text(
                            'Alunos ${qtd.sigla}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Total Alunos',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Linhas das distribuições
                ...distribuicoesComTotais!.map((distribuicao) {
                  final numero = distribuicao['numero'] as int;
                  final titulo = distribuicao['titulo'] as String;
                  final totais = distribuicao['totais'] as Map<String, int>;

                  return InkWell(
                    onTap: () {
                      // Chamar callback para selecionar distribuição diretamente
                      if (onSelecionarDistribuicaoEspecifica != null) {
                        onSelecionarDistribuicaoEspecifica!(
                          distribuicao['id'] as String,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Distribuição $numero',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  titulo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${totais['matriculados'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          // Colunas dinâmicas para cada Tipo de refeição ativa
                          ...quantidadesAtivas.map((qtd) {
                            final valor = totais[qtd.id] ?? 0;
                            return Expanded(
                              child: Text(
                                '$valor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }),
                          Expanded(
                            child: Text(
                              '${totais['total_refeicoes'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                fontFamily: 'monospace',
                                color: Colors.purple,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Instrução para o usuário
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Clique em uma distribuição para ver a quantidade de alunos por região e modalidade',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
