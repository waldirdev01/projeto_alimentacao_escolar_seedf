import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import '../../models/memoria_calculo.dart';
import '../../models/produto.dart';
import '../../models/quantidade_refeicao.dart';
import '../../models/regiao.dart';
import 'distribuicoes_por_ano_screen.dart';
import 'widgets/criar_memoria_calculo_dialog.dart';

class AnoLetivoDetailScreen extends StatefulWidget {
  final AnoLetivo anoLetivo;

  const AnoLetivoDetailScreen({super.key, required this.anoLetivo});

  @override
  State<AnoLetivoDetailScreen> createState() => _AnoLetivoDetailScreenState();
}

class _AnoLetivoDetailScreenState extends State<AnoLetivoDetailScreen> {
  List<MemoriaCalculo> memoriasCalculo = [];
  List<Produto> produtos = [];
  List<QuantidadeRefeicao> quantidadesRefeicao = [];
  List<Regiao> regioes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final db = FirestoreHelper();
      final memoriasDb = await db.getMemoriasCalculoPorAno(
        widget.anoLetivo.ano.toString(),
      );
      final produtosDb = await db.getProdutos();
      final quantidadesDb = await db.getQuantidadesRefeicao();
      final regioesDb = await db.getRegioes();

      setState(() {
        memoriasCalculo = memoriasDb;
        produtos = produtosDb;
        quantidadesRefeicao = quantidadesDb;
        regioes = regioesDb;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ano Letivo ${widget.anoLetivo.ano}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do ano letivo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ano Letivo ${widget.anoLetivo.ano}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.anoLetivo.ativo
                                ? Colors.green[100]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.anoLetivo.ativo ? 'Ativo' : 'Inativo',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.anoLetivo.ativo
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.list_alt,
                          label:
                              '${memoriasCalculo.length} Memórias de Cálculo',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ações do ano letivo
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: Icon(
                          Icons.local_shipping,
                          color: Colors.teal[700],
                        ),
                      ),
                      title: const Text(
                        'Gerenciar Distribuições',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Crie e gerencie as distribuições deste ano letivo',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DistribuicoesPorAnoScreen(
                              anoLetivo: widget.anoLetivo,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de memórias de cálculo
            const Text(
              'Memórias de Cálculo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: memoriasCalculo.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assessment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma memória de cálculo criada',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie a primeira memória de cálculo para começar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: memoriasCalculo.length,
                      itemBuilder: (context, index) {
                        final memoria = memoriasCalculo[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(
                                Icons.calculate,
                                color: Colors.blue[700],
                              ),
                            ),
                            title: Text(memoria.titulo),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Memória de Cálculo ${memoria.numero}'),
                                Text(
                                  '${memoria.produtosSelecionados.length} produtos, ${memoria.modalidadesSelecionadas.length} modalidades',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () =>
                                  _configurarMemoriaCalculo(memoria.numero),
                              tooltip: 'Configurar',
                            ),
                            onTap: () =>
                                _configurarMemoriaCalculo(memoria.numero),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _adicionarNovaMemoriaCalculo();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Memória de Cálculo'),
      ),
    );
  }

  void _adicionarNovaMemoriaCalculo() {
    final proximoNumero = memoriasCalculo.isEmpty
        ? 1
        : memoriasCalculo.map((d) => d.numero).reduce((a, b) => a > b ? a : b) +
              1;
    _configurarMemoriaCalculo(proximoNumero);
  }

  void _configurarMemoriaCalculo(int numeroMemoriaCalculo) async {
    final resultado = await showDialog<MemoriaCalculo>(
      context: context,
      builder: (context) => CriarMemoriaCalculoDialog(
        numeroMemoriaCalculo: numeroMemoriaCalculo,
        produtos: produtos,
        quantidadesRefeicao: quantidadesRefeicao,
        regioes: regioes,
        memoriaExistente: memoriasCalculo.isNotEmpty
            ? memoriasCalculo.firstWhere(
                (d) => d.numero == numeroMemoriaCalculo,
                orElse: () => MemoriaCalculo(
                  id: '',
                  anoLetivo: widget.anoLetivo.ano.toString(),
                  numero: numeroMemoriaCalculo,
                  titulo: '',
                  descricao: '',
                  dataInicio: DateTime.now(),
                  dataFim: DateTime.now().add(const Duration(days: 30)),
                  dataCriacao: DateTime.now(),
                  produtosSelecionados: [],
                  modalidadesSelecionadas: [],
                  regioesSelecionadas: [],
                  frequenciaPorModalidadeQuantidade: {},
                ),
              )
            : null,
      ),
    );

    if (resultado != null) {
      try {
        final db = FirestoreHelper();
        final memoriaComAno = resultado.copyWith(
          anoLetivo: widget.anoLetivo.ano.toString(),
        );
        await db.saveMemoriaCalculo(memoriaComAno);
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Memória de Cálculo ${resultado.numero} configurada com sucesso!',
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar memória de cálculo: $e')),
          );
        }
      }
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
