// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/distribuicao.dart';
import '../../models/etapa_distribuicao.dart';

class EtapasDistribuicaoScreen extends StatefulWidget {
  final Distribuicao distribuicao;
  final String escolaId;
  final VoidCallback? onQuantidadesAlunos;

  const EtapasDistribuicaoScreen({
    super.key,
    required this.distribuicao,
    required this.escolaId,
    this.onQuantidadesAlunos,
  });

  @override
  State<EtapasDistribuicaoScreen> createState() =>
      _EtapasDistribuicaoScreenState();
}

class _EtapasDistribuicaoScreenState extends State<EtapasDistribuicaoScreen> {
  final Map<String, bool> _etapasComDados = {};

  @override
  void initState() {
    super.initState();
    _verificarDadosSalvos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar dados quando a tela volta ao foco
    _verificarDadosSalvos();
  }

  Future<void> _verificarDadosSalvos() async {
    try {
      final db = FirestoreHelper();
      final dadosAlunos = await db.getDadosAlunosPorEscolaEDistribuicao(
        widget.escolaId,
        widget.distribuicao.id,
      );

      setState(() {
        _etapasComDados['quantidadesAlunos'] =
            dadosAlunos != null && dadosAlunos.enviado;
      });

      // Debug
      print('DadosAlunos encontrado: ${dadosAlunos != null}');
      if (dadosAlunos != null) {
        print('DadosAlunos.enviado: ${dadosAlunos.enviado}');
      }
      print(
        '_etapasComDados[quantidadesAlunos]: ${_etapasComDados['quantidadesAlunos']}',
      );
    } catch (e) {
      print('Erro ao verificar dados salvos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Etapas - ${widget.distribuicao.titulo}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações da Distribuição
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribuição ${widget.distribuicao.numero}/${widget.distribuicao.anoLetivo}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Período: ${widget.distribuicao.periodoTexto}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${widget.distribuicao.status.displayName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.distribuicao.isLiberadaParaEscolas
                            ? Colors.green[600]
                            : Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lista de Etapas
            Text(
              'Etapas Disponíveis',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: widget.distribuicao.etapas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma etapa disponível',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Aguarde a DIAE configurar as etapas desta distribuição',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: widget.distribuicao.etapas.length,
                      itemBuilder: (context, index) {
                        final etapa = widget.distribuicao.etapas[index];
                        return _EtapaPastaCard(
                          etapa: etapa,
                          etapaConcluida:
                              _etapasComDados[etapa.tipo.name] ?? false,
                          onAcessar: () => _acessarEtapa(context, etapa),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _acessarEtapa(BuildContext context, EtapaDistribuicao etapa) async {
    // Aqui será implementado o acesso específico a cada tipo de etapa
    switch (etapa.tipo) {
      case TipoEtapaDistribuicao.quantidadesAlunos:
        // Chama o callback para abrir a tela de quantidades de alunos
        widget.onQuantidadesAlunos?.call();
        // Recarregar dados para atualizar o status
        await _verificarDadosSalvos();
        break;
      case TipoEtapaDistribuicao.pdga:
        _mostrarMensagemEtapa(
          context,
          'PDGA',
          'Plano de Distribuição de Gêneros Alimentícios',
        );
        break;
      case TipoEtapaDistribuicao.pdgp:
        _mostrarMensagemEtapa(
          context,
          'PDGP',
          'Plano de Distribuição de Gêneros Perisháveis',
        );
        break;
      case TipoEtapaDistribuicao.cardapios:
        _mostrarMensagemEtapa(context, 'Cardápios', 'Definição de cardápios');
        break;
    }
  }

  void _mostrarMensagemEtapa(
    BuildContext context,
    String titulo,
    String descricao,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(
          '$descricao\n\nEsta funcionalidade será implementada em breve.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _EtapaPastaCard extends StatelessWidget {
  final EtapaDistribuicao etapa;
  final bool etapaConcluida;
  final VoidCallback onAcessar;

  const _EtapaPastaCard({
    required this.etapa,
    required this.etapaConcluida,
    required this.onAcessar,
  });

  @override
  Widget build(BuildContext context) {
    final etapaRealmenteConcluida = etapa.concluida || etapaConcluida;
    final podeAcessar = etapa.ativa && !etapaRealmenteConcluida;
    final corStatus = _getCorStatus(etapa, etapaRealmenteConcluida);

    return GestureDetector(
      onTap: podeAcessar ? onAcessar : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: podeAcessar
              ? Border.all(color: Colors.blue[300]!, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: podeAcessar
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
              spreadRadius: podeAcessar ? 2 : 1,
              blurRadius: podeAcessar ? 6 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Cabeçalho da pasta
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: corStatus,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    _getIconForTipo(etapa.tipo),
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      etapa.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (etapa.concluida)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),

            // Conteúdo da pasta
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo da etapa
                    Text(
                      etapa.tipo.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Checklist de status
                    _buildChecklist(),

                    const Spacer(),

                    // Data limite
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: corStatus),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Limite: ${etapa.dataLimiteTexto}',
                            style: TextStyle(
                              fontSize: 11,
                              color: corStatus,
                              fontWeight: etapa.isDataLimiteUltrapassada
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Status badge
                    Center(
                      child: _buildStatusBadge(etapa, etapaRealmenteConcluida),
                    ),

                    // Indicador de clique
                    if (podeAcessar) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 12,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Toque para acessar',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist() {
    final etapaRealmenteConcluida = etapa.concluida || etapaConcluida;

    return Column(
      children: [
        _buildChecklistItem(
          'Etapa Ativa',
          etapa.ativa,
          etapa.ativa ? Colors.green : Colors.grey,
        ),
        _buildChecklistItem(
          'Dentro do Prazo',
          !etapa.isDataLimiteUltrapassada,
          etapa.isDataLimiteUltrapassada ? Colors.red : Colors.green,
        ),
        _buildChecklistItem(
          etapaRealmenteConcluida ? 'Concluída' : 'Não Concluída',
          etapaRealmenteConcluida,
          etapaRealmenteConcluida ? Colors.green : Colors.orange,
        ),
        _buildChecklistItem(
          'Pode Acessar',
          etapa.ativa &&
              !etapaRealmenteConcluida &&
              !etapa.isDataLimiteUltrapassada,
          (etapa.ativa &&
                  !etapaRealmenteConcluida &&
                  !etapa.isDataLimiteUltrapassada)
              ? Colors.green
              : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String label, bool isCompleted, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCorStatus(
    EtapaDistribuicao etapa, [
    bool etapaRealmenteConcluida = false,
  ]) {
    if (!etapa.ativa) return Colors.grey[400]!;
    if (etapa.concluida || etapaRealmenteConcluida) return Colors.green[600]!;
    if (etapa.isDataLimiteUltrapassada) return Colors.red[600]!;
    if (etapa.isDataLimiteProxima) return Colors.orange[600]!;
    return Colors.blue[600]!;
  }

  Widget _buildStatusBadge(
    EtapaDistribuicao etapa, [
    bool etapaRealmenteConcluida = false,
  ]) {
    if (!etapa.ativa) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'INATIVA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    if (etapa.concluida || etapaRealmenteConcluida) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'CONCLUÍDA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      );
    }

    if (etapa.isDataLimiteUltrapassada) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'VENCIDA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
      );
    }

    if (etapa.isDataLimiteProxima) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'PRÓXIMA',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'DISPONÍVEL',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  IconData _getIconForTipo(TipoEtapaDistribuicao tipo) {
    switch (tipo) {
      case TipoEtapaDistribuicao.quantidadesAlunos:
        return Icons.people;
      case TipoEtapaDistribuicao.pdga:
        return Icons.assignment;
      case TipoEtapaDistribuicao.pdgp:
        return Icons.inventory;
      case TipoEtapaDistribuicao.cardapios:
        return Icons.restaurant_menu;
    }
  }
}
