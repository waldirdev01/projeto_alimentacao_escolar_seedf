import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/ano_letivo.dart';
import 'ano_letivo_overview_screen.dart';
import 'produtos_screen.dart';
import 'fornecedores_management_screen.dart';
import 'fontes_pagamento_management_screen.dart';

class GconaeHomeScreen extends StatefulWidget {
  const GconaeHomeScreen({super.key});

  @override
  State<GconaeHomeScreen> createState() => _GconaeHomeScreenState();
}

class _GconaeHomeScreenState extends State<GconaeHomeScreen> {
  List<AnoLetivo> anosLetivos = [];
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
      final firestore = FirestoreHelper();
      final anosDb = await firestore.getAnosLetivos();

      setState(() {
        anosLetivos = anosDb;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPAE - Gerência de Planejamento')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gerência de Planejamento, Acompanhamento e Oferta da Alimentação Escolar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Planejamento e memória de cálculo das aquisições de alimentação escolar',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            // Card de Gerenciamento de Produtos
            _ManagementCard(
              title: 'Gerenciamento de Produtos para Aquisição',
              description:
                  'Gerencie produtos, per capita e valores para aquisição',
              icon: Icons.inventory_2,
              iconColor: Colors.teal[700]!,
              iconBackground: Colors.teal[100]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProdutosScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ManagementCard(
              title: 'Gerenciamento de Fornecedores',
              description:
                  'Cadastre fornecedores, contatos e acompanhe os contratos',
              icon: Icons.handshake,
              iconColor: Colors.deepPurple[700]!,
              iconBackground: Colors.deepPurple[100]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FornecedoresManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ManagementCard(
              title: 'Gerenciamento de Fontes de Pagamento',
              description:
                  'Cadastre fontes de pagamento com valores e observações',
              icon: Icons.payment,
              iconColor: Colors.orange[700]!,
              iconBackground: Colors.orange[100]!,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const FontesPagamentoManagementScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Anos Letivos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : anosLetivos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 80,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum ano letivo cadastrado',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Anos letivos são criados pela DIAE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Entre em contato com a direção para cadastrar anos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnoLetivoOverviewScreen(anoLetivo: ano),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnoLetivoCard extends StatelessWidget {
  final AnoLetivo anoLetivo;
  final VoidCallback onTap;

  const _AnoLetivoCard({required this.anoLetivo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
