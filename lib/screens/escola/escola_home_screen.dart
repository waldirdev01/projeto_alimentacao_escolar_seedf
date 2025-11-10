import 'package:flutter/material.dart';

import '../../database/firestore_helper.dart';
import '../../models/escola.dart';
import 'escola_detail_screen.dart';

class EscolaHomeScreen extends StatefulWidget {
  const EscolaHomeScreen({super.key});

  @override
  State<EscolaHomeScreen> createState() => _EscolaHomeScreenState();
}

class _EscolaHomeScreenState extends State<EscolaHomeScreen> {
  List<Escola> escolas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarEscolas();
  }

  Future<void> _carregarEscolas() async {
    setState(() {
      _carregando = true;
    });

    try {
      final db = FirestoreHelper();
      final escolasDb = await db.getEscolas();

      setState(() {
        escolas = escolasDb.where((e) => e.ativo).toList();
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _carregando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar escolas: $e')));
      }
    }
  }

  void _navegarParaEscola(Escola escola) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EscolaDetailScreen(escolaId: escola.id, escolaNome: escola.nome),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Alimentação - Escola'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarEscolas,
          ),
        ],
      ),
      body: escolas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma escola cadastrada',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entre em contato com o GCONAE',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecione sua escola:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: escolas.length,
                      itemBuilder: (context, index) {
                        final escola = escolas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(
                                Icons.school,
                                color: Colors.blue[700],
                              ),
                            ),
                            title: Text(
                              escola.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Código: ${escola.codigo}'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              _navegarParaEscola(escola);
                            },
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
}
