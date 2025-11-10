// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/distribuicao.dart';
import '../../models/escola.dart';
import '../../models/etapa_distribuicao.dart';
import '../../models/quantidade_refeicao.dart';
import 'etapas_distribuicao_screen.dart';
import 'widgets/dados_alunos_dialog.dart';

class EscolaDetailScreen extends StatefulWidget {
  final String escolaId;
  final String escolaNome;

  const EscolaDetailScreen({
    super.key,
    required this.escolaId,
    required this.escolaNome,
  });

  @override
  State<EscolaDetailScreen> createState() => _EscolaDetailScreenState();
}

class _EscolaDetailScreenState extends State<EscolaDetailScreen> {
  List<Distribuicao> distribuicoesLiberadas = [];
  List<QuantidadeRefeicao> quantidadesRefeicao = [];
  Map<String, DadosAlunos?> dadosPorDistribuicao =
      {}; // distribuicaoId -> dados
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
    });

    try {
      final db = FirestoreHelper();
      final distribuicoesDb = await db.getDistribuicoes();
      final quantidadesDb = await db.getQuantidadesRefeicao();

      // Filtrar apenas distribuições liberadas para escolas
      final distribuicoesLiberadas =
          distribuicoesDb.where((d) => d.isLiberadaParaEscolas).toList()..sort(
            (a, b) => b.numero.compareTo(a.numero),
          ); // Mais recente primeiro

      // Carregar dados de alunos para cada distribuição
      final dadosPorDist = <String, DadosAlunos?>{};
      for (final dist in distribuicoesLiberadas) {
        final dados = await db.getDadosAlunosPorEscolaEDistribuicao(
          widget.escolaId,
          dist.id,
        );
        dadosPorDist[dist.id] = dados;
      }

      setState(() {
        this.distribuicoesLiberadas = distribuicoesLiberadas;
        quantidadesRefeicao = quantidadesDb;
        dadosPorDistribuicao = dadosPorDist;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  void _verEtapasDistribuicao(Distribuicao distribuicao) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EtapasDistribuicaoScreen(
          distribuicao: distribuicao,
          escolaId: widget.escolaId,
          onQuantidadesAlunos: () =>
              _informarDadosDistribuicao(distribuicao, context),
        ),
      ),
    );
  }

  void _informarDadosDistribuicao(
    Distribuicao distribuicao, [
    BuildContext? contextParam,
  ]) async {
    final contextToUse = contextParam ?? context;
    // Verificar se a etapa de quantidades de alunos está ativa
    final etapaQuantidades = distribuicao.getEtapaPorTipo(
      TipoEtapaDistribuicao.quantidadesAlunos,
    );
    if (etapaQuantidades == null) {
      ScaffoldMessenger.of(contextToUse).showSnackBar(
        SnackBar(
          content: Text(
            'A etapa de envio de quantidades de alunos não foi configurada para a Distribuição ${distribuicao.numero}/${distribuicao.anoLetivo}',
          ),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!etapaQuantidades.ativa) {
      ScaffoldMessenger.of(contextToUse).showSnackBar(
        SnackBar(
          content: Text(
            'A etapa de envio de quantidades de alunos não está ativa para a Distribuição ${distribuicao.numero}/${distribuicao.anoLetivo}',
          ),
          backgroundColor: Colors.orange[600],
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (etapaQuantidades.concluida) {
      ScaffoldMessenger.of(contextToUse).showSnackBar(
        SnackBar(
          content: Text(
            'A etapa de envio de quantidades de alunos já foi concluída para a Distribuição ${distribuicao.numero}/${distribuicao.anoLetivo}',
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Verificar se a data limite da etapa foi ultrapassada
    if (etapaQuantidades.isDataLimiteUltrapassada) {
      ScaffoldMessenger.of(contextToUse).showSnackBar(
        SnackBar(
          content: Text(
            'O prazo para envio de quantidades de alunos da Distribuição ${distribuicao.numero}/${distribuicao.anoLetivo} expirou em ${etapaQuantidades.dataLimiteTexto}',
          ),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Verificar se já existem dados para esta distribuição
    DadosAlunos dadosExistentes =
        dadosPorDistribuicao[distribuicao.id] ??
        DadosAlunos(
          id: '',
          escolaId: widget.escolaId,
          distribuicaoId: distribuicao.id,
          anoLetivo: distribuicao.anoLetivo,
          numeroDistribuicao: distribuicao.numero,
          modalidades: {},
          dataAtualizacao: DateTime.now(),
        );

    // Se não há dados para esta distribuição, buscar da distribuição anterior
    if (dadosExistentes.modalidades.isEmpty && distribuicao.numero > 1) {
      try {
        final db = FirestoreHelper();

        // Buscar distribuição anterior (número - 1)
        final distribuicaoAnterior = distribuicoesLiberadas.firstWhere(
          (d) =>
              d.numero == distribuicao.numero - 1 &&
              d.anoLetivo == distribuicao.anoLetivo,
          orElse: () => distribuicao,
        );

        if (distribuicaoAnterior.id != distribuicao.id) {
          // Buscar dados da distribuição anterior
          final dadosAnteriores = await db.getDadosAlunosPorEscolaEDistribuicao(
            widget.escolaId,
            distribuicaoAnterior.id,
          );

          if (dadosAnteriores != null &&
              dadosAnteriores.modalidades.isNotEmpty) {
            // Usar dados anteriores como base, mas com IDs da nova distribuição
            dadosExistentes = DadosAlunos(
              id: '', // Novo registro
              escolaId: widget.escolaId,
              distribuicaoId: distribuicao.id,
              anoLetivo: distribuicao.anoLetivo,
              numeroDistribuicao: distribuicao.numero,
              modalidades: dadosAnteriores.modalidades, // Copiar modalidades
              dataAtualizacao: DateTime.now(),
            );
          }
        }
      } catch (e) {
        // Se houver erro, continuar com dados vazios
        debugPrint('Erro ao buscar dados anteriores: $e');
      }
    }

    // Verificar se os dados foram copiados da distribuição anterior
    final dadosForamCopiados =
        dadosExistentes.id.isEmpty &&
        dadosExistentes.modalidades.isNotEmpty &&
        distribuicao.numero > 1;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: contextToUse,
      builder: (context) => DadosAlunosDialog(
        escolaId: widget.escolaId,
        anoLetivo: distribuicao.anoLetivo,
        numeroDistribuicao: distribuicao.numero,
        quantidadesRefeicao: quantidadesRefeicao,
        dadosExistentes: dadosExistentes,
        dadosCopiados: dadosForamCopiados,
      ),
    );

    if (resultado != null) {
      final dadosAlunos = resultado['dados'] as DadosAlunos;
      final enviado = resultado['enviado'] as bool;

      try {
        final db = FirestoreHelper();
        await db.saveDadosAlunos(dadosAlunos);

        // Se foi enviado, marcar escola como tendo enviado dados
        if (enviado &&
            !distribuicao.escolasQueEnviaramDados.contains(widget.escolaId)) {
          final distribuicaoAtualizada = distribuicao.copyWith(
            escolasQueEnviaramDados: [
              ...distribuicao.escolasQueEnviaramDados,
              widget.escolaId,
            ],
          );
          await db.updateDistribuicao(distribuicaoAtualizada);
        }

        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(contextToUse).showSnackBar(
            SnackBar(
              content: Text(
                enviado
                    ? 'Números de alunos enviados com sucesso!'
                    : 'Rascunho dos números de alunos salvo com sucesso!',
              ),
              backgroundColor: enviado ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao salvar dados: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.escolaNome),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com informações da escola
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.school,
                              size: 40,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.escolaNome,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Informe os números de alunos por modalidade de ensino',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Distribuições disponíveis
                  Row(
                    children: [
                      const Text(
                        'Distribuições Liberadas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${distribuicoesLiberadas.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Expanded(
                    child: distribuicoesLiberadas.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma distribuição liberada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aguarde a GCONAE liberar as distribuições',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: distribuicoesLiberadas.length,
                            itemBuilder: (context, index) {
                              final distribuicao =
                                  distribuicoesLiberadas[index];
                              final temDados =
                                  dadosPorDistribuicao[distribuicao.id] != null;

                              final etapaQuantidades = distribuicao
                                  .getEtapaPorTipo(
                                    TipoEtapaDistribuicao.quantidadesAlunos,
                                  );
                              final prazoExpirado =
                                  etapaQuantidades?.isDataLimiteUltrapassada ??
                                  true;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                color: prazoExpirado ? Colors.grey[100] : null,
                                child: ListTile(
                                  enabled: !prazoExpirado,
                                  leading: CircleAvatar(
                                    backgroundColor: prazoExpirado
                                        ? Colors.grey[300]
                                        : temDados
                                        ? Colors.green[100]
                                        : Colors.orange[100],
                                    child: Icon(
                                      prazoExpirado
                                          ? Icons.block
                                          : temDados
                                          ? Icons.check_circle
                                          : Icons.pending_actions,
                                      color: prazoExpirado
                                          ? Colors.grey[600]
                                          : temDados
                                          ? Colors.green[700]
                                          : Colors.orange[700],
                                    ),
                                  ),
                                  title: Text(
                                    distribuicao.titulo,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Distribuição ${distribuicao.numero}/${distribuicao.anoLetivo}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        distribuicao.periodoTexto,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (temDados) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Números de alunos enviados em ${_formatarData(dadosPorDistribuicao[distribuicao.id]!.dataAtualizacao)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _verEtapasDistribuicao(
                                          distribuicao,
                                        ),
                                        icon: const Icon(
                                          Icons.folder,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Etapas',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[100],
                                          foregroundColor: Colors.blue[700],
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: const Size(0, 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }
}
