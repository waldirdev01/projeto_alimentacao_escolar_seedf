import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/distribuicao.dart';
import 'ano_letivo_overview_screen.dart';
import 'widgets/criar_ano_dialog.dart';

class AnosLetivosScreen extends StatefulWidget {
  const AnosLetivosScreen({super.key});

  @override
  State<AnosLetivosScreen> createState() => _AnosLetivosScreenState();
}

class _AnosLetivosScreenState extends State<AnosLetivosScreen> {
  List<AnoLetivo> anosLetivos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final firestore = FirestoreHelper();
      final anos = await firestore.getAnosLetivos();
      setState(() {
        anosLetivos = anos;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar anos letivos: $e')),
        );
      }
    }
  }

  void _criarNovoAno() async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CriarAnoDialog(anosExistentes: anosLetivos),
    );

    if (resultado != null) {
      try {
        final novoAno = AnoLetivo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          ano: resultado['ano'],
          dataCriacao: DateTime.now(),
        );

        final firestore = FirestoreHelper();
        await firestore.saveAnoLetivo(novoAno);

        // Se for replicar, copiar as distribuições do ano anterior
        if (resultado['anoReplicado'] != null) {
          final anoReplicado = anosLetivos.firstWhere(
            (a) => a.id == resultado['anoReplicado'],
          );
          final distribuicoesAnteriores = await firestore
              .getDistribuicoesPorAno(anoReplicado.ano.toString());

          for (final distAntiga in distribuicoesAnteriores) {
            final novaDistribuicao = distAntiga.copyWith(
              id: '${DateTime.now().millisecondsSinceEpoch}_${distAntiga.numero}',
              anoLetivo: novoAno.ano.toString(),
              dataCriacao: DateTime.now(),
              status: StatusDistribuicao.planejada,
              dataLiberacao: null,
              escolasQueEnviaramDados: [],
            );
            await firestore.saveDistribuicao(novaDistribuicao);
          }
        }

        await _carregarDados();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resultado['anoReplicado'] != null
                    ? 'Ano letivo criado e aquisições replicadas!'
                    : 'Ano letivo criado com sucesso!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar ano letivo: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Anos Letivos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _criarNovoAno,
            tooltip: 'Criar novo ano letivo',
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : anosLetivos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum ano letivo cadastrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie o primeiro ano letivo para começar',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _criarNovoAno,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar primeiro ano'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: anosLetivos.length,
              itemBuilder: (context, index) {
                final ano = anosLetivos[index];
                return _AnoLetivoCard(
                  anoLetivo: ano,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AnoLetivoOverviewScreen(
                          anoLetivo: ano,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _AnoLetivoCard extends StatelessWidget {
  final AnoLetivo anoLetivo;
  final VoidCallback onTap;

  const _AnoLetivoCard({
    required this.anoLetivo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Spacer(),
                  if (anoLetivo.ativo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Ativo',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${anoLetivo.ano}',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Ano Letivo',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
