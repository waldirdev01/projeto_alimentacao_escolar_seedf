import 'package:flutter/material.dart';

import '../../models/ano_letivo.dart';
import 'ano_letivo_detail_screen.dart';
import 'controle_saldo_contrato_screen.dart';

class ControleDeniseScreen extends StatelessWidget {
  final AnoLetivo anoLetivo;

  const ControleDeniseScreen({super.key, required this.anoLetivo});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 2
        : screenWidth > 600
            ? 2
            : 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Controle Denise • ${anoLetivo.ano}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione uma opção',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.7,
                children: [
                  _OptionCard(
                    icon: Icons.calculate_outlined,
                    title: 'Memória de Cálculo',
                    description:
                        'Gerencie memórias de cálculo, distribuições e relatórios deste ano letivo.',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AnoLetivoDetailScreen(
                            anoLetivo: anoLetivo,
                          ),
                        ),
                      );
                    },
                  ),
                  _OptionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Controle Orçamentário',
                    description:
                        'Monitore previsões e execuções orçamentárias relacionadas às aquisições.',
                    color: Colors.deepPurple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Controle Orçamentário ainda em desenvolvimento.',
                          ),
                        ),
                      );
                    },
                  ),
                  _OptionCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Controle de Saldo de Contrato',
                    description:
                        'Acompanhe o saldo disponível nos contratos vigentes para cada produto.',
                    color: Colors.brown,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ControleSaldoContratoScreen(
                            anoLetivo: anoLetivo,
                          ),
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

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _OptionCard({
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

