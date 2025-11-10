import 'package:flutter/material.dart';

import '../gconae/anos_letivos_screen.dart';
import '../gconae/escolas_screen.dart';
import '../gconae/gconae_home_screen.dart';
import '../gconae/quantidades_refeicao_screen.dart';
import '../gconae/regioes_screen.dart';
import 'distribuicoes_screen.dart';
import 'processos_aquisicao_screen.dart';

class DiaeHomeScreen extends StatelessWidget {
  const DiaeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DIAE - Diretoria de Alimentação Escolar'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'DIAE - Diretoria de Alimentação Escolar',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Cards de cadastros gerais em SingleChildScrollView
                const Text(
                  'Configurações do Sistema',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Card de Anos Letivos
                        _ConfigCard(
                          title: 'Cadastro de Anos Letivos',
                          description: 'Gerencie os anos letivos do sistema',
                          icon: Icons.calendar_today,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AnosLetivosScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Card de Escolas
                        _ConfigCard(
                          title: 'Cadastro de Escolas',
                          description: 'Gerencie as escolas por regional',
                          icon: Icons.school,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EscolasScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Card de Quantidades de Refeição
                        _ConfigCard(
                          title: 'Quantidades de Refeição',
                          description: 'Gerenciar tipos de refeição',
                          icon: Icons.restaurant,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const QuantidadesRefeicaoScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Card de Regiões
                        _ConfigCard(
                          title: 'Regiões e Regionais',
                          description: 'Gerencie as CREs por região',
                          icon: Icons.map,
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegioesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Card de Gerenciar Aquisições
                        _ConfigCard(
                          title: 'Gerenciar Aquisições',
                          description:
                              'Gerencie processos de aquisição e acompanhe o status dos produtos',
                          icon: Icons.shopping_cart,
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProcessosAquisicaoScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Card de Gerenciar Distribuições
                        _ConfigCard(
                          title: 'Gerenciar Distribuições',
                          description:
                              'Crie e libere distribuições para escolas',
                          icon: Icons.local_shipping,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DistribuicoesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gerências',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _GerenciaCard(
                        title: 'GPAE',
                        fullName:
                            'Gerência de Planejamento, Acompanhamento e Oferta da Alimentação Escolar',
                        icon: Icons.assessment,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GconaeHomeScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _GerenciaCard(
                        title: 'GEVMON',
                        fullName:
                            'Gerência de Vigilância e Monitoramento da Qualidade Alimentar',
                        icon: Icons.health_and_safety,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('GEVMON - Em desenvolvimento'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _GerenciaCard(
                        title: 'GCONAE',
                        fullName:
                            'Gerência de Contas e Controle da Distribuição, Aquisição e Fornecimento da Alimentação Escolar',
                        icon: Icons.inventory,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('GCONAE - Em desenvolvimento'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConfigCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color.withValues(alpha: 0.8),
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
                    Text(description, style: const TextStyle(fontSize: 12)),
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

class _GerenciaCard extends StatelessWidget {
  final String title;
  final String fullName;
  final IconData icon;
  final VoidCallback onTap;

  const _GerenciaCard({
    required this.title,
    required this.fullName,
    required this.icon,
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullName,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
