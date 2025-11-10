import 'package:flutter/material.dart';

import '../../models/ano_letivo.dart';
import 'controle_denise_screen.dart';
import 'distribuicoes_por_ano_screen.dart';

class AnoLetivoOverviewScreen extends StatelessWidget {
  final AnoLetivo anoLetivo;

  const AnoLetivoOverviewScreen({super.key, required this.anoLetivo});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 3
        : screenWidth > 600
            ? 2
            : 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ano Letivo ${anoLetivo.ano}'),
            const SizedBox(height: 2),
            Text(
              'Selecione uma área',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha a área que deseja gerenciar',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _OverviewCard(
                    icon: Icons.manage_accounts,
                    title: 'Controle Denise',
                    description:
                        'Acesse os controles e memórias de cálculo gerenciados pela equipe da Denise.',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ControleDeniseScreen(
                            anoLetivo: anoLetivo,
                          ),
                        ),
                      );
                    },
                  ),
                  _OverviewCard(
                    icon: Icons.local_shipping,
                    title: 'Gerenciar Distribuições',
                    description:
                        'Crie, acompanhe e atualize as distribuições deste ano letivo.',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DistribuicoesPorAnoScreen(
                            anoLetivo: anoLetivo,
                          ),
                        ),
                      );
                    },
                  ),
                  _OverviewCard(
                    icon: Icons.pending_actions,
                    title: 'Outros Controles',
                    description:
                        'Área reservada para novos controles e processos. Em breve.',
                    color: Colors.orange,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidade em desenvolvimento.'),
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
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

