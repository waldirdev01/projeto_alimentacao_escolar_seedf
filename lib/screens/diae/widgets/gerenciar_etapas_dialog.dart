import 'package:flutter/material.dart';

import '../../../models/etapa_distribuicao.dart';

class GerenciarEtapasDialog extends StatefulWidget {
  final List<EtapaDistribuicao> etapasExistentes;
  final String distribuicaoId;

  const GerenciarEtapasDialog({
    super.key,
    required this.etapasExistentes,
    required this.distribuicaoId,
  });

  @override
  State<GerenciarEtapasDialog> createState() => _GerenciarEtapasDialogState();
}

class _GerenciarEtapasDialogState extends State<GerenciarEtapasDialog> {
  List<EtapaDistribuicao> _etapas = [];

  @override
  void initState() {
    super.initState();
    _etapas = List.from(widget.etapasExistentes);
  }

  void _adicionarEtapa() {
    showDialog(
      context: context,
      builder: (context) => _CriarEtapaDialog(
        distribuicaoId: widget.distribuicaoId,
        onEtapaCriada: (etapa) {
          setState(() {
            _etapas.add(etapa);
          });
        },
      ),
    );
  }

  void _editarEtapa(EtapaDistribuicao etapa) {
    showDialog(
      context: context,
      builder: (context) => _CriarEtapaDialog(
        distribuicaoId: widget.distribuicaoId,
        etapaExistente: etapa,
        onEtapaCriada: (etapaEditada) {
          setState(() {
            final index = _etapas.indexWhere((e) => e.id == etapa.id);
            if (index != -1) {
              _etapas[index] = etapaEditada;
            }
          });
        },
      ),
    );
  }

  void _removerEtapa(EtapaDistribuicao etapa) {
    setState(() {
      _etapas.removeWhere((e) => e.id == etapa.id);
    });
  }

  void _toggleAtiva(EtapaDistribuicao etapa) {
    setState(() {
      final index = _etapas.indexWhere((e) => e.id == etapa.id);
      if (index != -1) {
        _etapas[index] = etapa.copyWith(ativa: !etapa.ativa);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Gerenciar Etapas da Distribuição',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _adicionarEtapa,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Etapa'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _etapas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhuma etapa criada',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Adicione etapas para organizar o processo da distribuição',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _etapas.length,
                      itemBuilder: (context, index) {
                        final etapa = _etapas[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: etapa.ativa
                                  ? Colors.green[100]
                                  : Colors.grey[300],
                              child: Icon(
                                _getIconForTipo(etapa.tipo),
                                color: etapa.ativa
                                    ? Colors.green[700]
                                    : Colors.grey[600],
                              ),
                            ),
                            title: Text(
                              etapa.titulo,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: etapa.ativa ? null : Colors.grey[600],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(etapa.tipo.displayName),
                                if (etapa.descricao.isNotEmpty)
                                  Text(etapa.descricao),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: etapa.isDataLimiteUltrapassada
                                          ? Colors.red[600]
                                          : etapa.isDataLimiteProxima
                                          ? Colors.orange[600]
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Limite: ${etapa.dataLimiteTexto}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: etapa.isDataLimiteUltrapassada
                                            ? Colors.red[600]
                                            : etapa.isDataLimiteProxima
                                            ? Colors.orange[600]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    if (etapa.isDataLimiteUltrapassada) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'VENCIDA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[700],
                                          ),
                                        ),
                                      ),
                                    ] else if (etapa.isDataLimiteProxima) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'PRÓXIMA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'edit':
                                    _editarEtapa(etapa);
                                    break;
                                  case 'toggle':
                                    _toggleAtiva(etapa);
                                    break;
                                  case 'delete':
                                    _removerEtapa(etapa);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Row(
                                    children: [
                                      Icon(
                                        etapa.ativa
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        etapa.ativa ? 'Desativar' : 'Ativar',
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text(
                                        'Remover',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(_etapas),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
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

class _CriarEtapaDialog extends StatefulWidget {
  final String distribuicaoId;
  final EtapaDistribuicao? etapaExistente;
  final Function(EtapaDistribuicao) onEtapaCriada;

  const _CriarEtapaDialog({
    required this.distribuicaoId,
    this.etapaExistente,
    required this.onEtapaCriada,
  });

  @override
  State<_CriarEtapaDialog> createState() => _CriarEtapaDialogState();
}

class _CriarEtapaDialogState extends State<_CriarEtapaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  TipoEtapaDistribuicao _tipoSelecionado =
      TipoEtapaDistribuicao.quantidadesAlunos;
  DateTime _dataLimite = DateTime.now().add(const Duration(days: 7));
  bool _ativa = true;

  @override
  void initState() {
    super.initState();
    if (widget.etapaExistente != null) {
      final etapa = widget.etapaExistente!;
      _tituloController.text = etapa.titulo;
      _descricaoController.text = etapa.descricao;
      _tipoSelecionado = etapa.tipo;
      _dataLimite = etapa.dataLimite;
      _ativa = etapa.ativa;
    } else {
      _tituloController.text = _tipoSelecionado.displayName;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      final etapa = EtapaDistribuicao(
        id:
            widget.etapaExistente?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        distribuicaoId: widget.distribuicaoId,
        tipo: _tipoSelecionado,
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        dataLimite: _dataLimite,
        ativa: _ativa,
        concluida: widget.etapaExistente?.concluida ?? false,
        dataCriacao: widget.etapaExistente?.dataCriacao ?? DateTime.now(),
        dataConclusao: widget.etapaExistente?.dataConclusao,
        responsaveis: widget.etapaExistente?.responsaveis ?? [],
        dadosEtapa: widget.etapaExistente?.dadosEtapa ?? {},
      );

      widget.onEtapaCriada(etapa);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.etapaExistente != null ? 'Editar Etapa' : 'Nova Etapa',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tipo da Etapa
              DropdownButtonFormField<TipoEtapaDistribuicao>(
                initialValue: _tipoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo da Etapa',
                  border: OutlineInputBorder(),
                ),
                items: TipoEtapaDistribuicao.values.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSelecionado = value!;
                    if (widget.etapaExistente == null) {
                      _tituloController.text = value.displayName;
                    }
                  });
                },
                validator: (value) {
                  if (value == null) return 'Selecione o tipo da etapa';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título da Etapa',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite o título da etapa';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Data Limite
              InkWell(
                onTap: () async {
                  final data = await showDatePicker(
                    context: context,
                    initialDate: _dataLimite,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (data != null) {
                    setState(() {
                      _dataLimite = data;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data Limite',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_dataLimite.day}/${_dataLimite.month}/${_dataLimite.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ativa
              SwitchListTile(
                title: const Text('Etapa Ativa'),
                subtitle: const Text(
                  'Permitir que usuários acessem esta etapa',
                ),
                value: _ativa,
                onChanged: (value) {
                  setState(() {
                    _ativa = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvar,
          child: Text(widget.etapaExistente != null ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }
}
