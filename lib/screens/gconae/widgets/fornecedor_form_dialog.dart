import 'package:flutter/material.dart';

import '../../../models/fornecedor.dart';

class FornecedorFormDialog extends StatefulWidget {
  final Fornecedor? fornecedor;

  const FornecedorFormDialog({super.key, this.fornecedor});

  @override
  State<FornecedorFormDialog> createState() => _FornecedorFormDialogState();
}

class _FornecedorFormDialogState extends State<FornecedorFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _cnpjController;
  late final TextEditingController _inscricaoController;
  late final TextEditingController _responsavelController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _observacoesController;

  bool get _isEdicao => widget.fornecedor != null;

  @override
  void initState() {
    super.initState();
    final fornecedor = widget.fornecedor;

    _nomeController = TextEditingController(text: fornecedor?.nome ?? '');
    _cnpjController = TextEditingController(text: fornecedor?.cnpj ?? '');
    _inscricaoController =
        TextEditingController(text: fornecedor?.inscricaoEstadual ?? '');
    _responsavelController =
        TextEditingController(text: fornecedor?.responsavel ?? '');
    _telefoneController =
        TextEditingController(text: fornecedor?.telefone ?? '');
    _emailController = TextEditingController(text: fornecedor?.email ?? '');
    _enderecoController =
        TextEditingController(text: fornecedor?.endereco ?? '');
    _observacoesController =
        TextEditingController(text: fornecedor?.observacoes ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _inscricaoController.dispose();
    _responsavelController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final fornecedorBase = widget.fornecedor;
    final fornecedor = Fornecedor(
      id: fornecedorBase?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      nome: _nomeController.text.trim(),
      cnpj: _cnpjController.text.trim().isEmpty
          ? null
          : _cnpjController.text.trim(),
      inscricaoEstadual: _inscricaoController.text.trim().isEmpty
          ? null
          : _inscricaoController.text.trim(),
      responsavel: _responsavelController.text.trim().isEmpty
          ? null
          : _responsavelController.text.trim(),
      telefone: _telefoneController.text.trim().isEmpty
          ? null
          : _telefoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      endereco: _enderecoController.text.trim().isEmpty
          ? null
          : _enderecoController.text.trim(),
      observacoes: _observacoesController.text.trim().isEmpty
          ? null
          : _observacoesController.text.trim(),
      ativo: fornecedorBase?.ativo ?? true,
      criadoEm: fornecedorBase?.criadoEm,
      atualizadoEm: DateTime.now(),
    );

    Navigator.of(context).pop(fornecedor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdicao ? 'Editar fornecedor' : 'Novo fornecedor'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CampoTexto(
                  controller: _nomeController,
                  label: 'Razão social / Nome fantasia *',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Informe o nome do fornecedor';
                    }
                    if (value.trim().length < 3) {
                      return 'Informe pelo menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                _CampoTexto(
                  controller: _cnpjController,
                  label: 'CNPJ',
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                ),
                _CampoTexto(
                  controller: _inscricaoController,
                  label: 'Inscrição estadual',
                  icon: Icons.confirmation_number,
                ),
                _CampoTexto(
                  controller: _responsavelController,
                  label: 'Responsável',
                  icon: Icons.person,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _CampoTexto(
                        controller: _telefoneController,
                        label: 'Telefone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CampoTexto(
                        controller: _emailController,
                        label: 'E-mail',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final email = value.trim();
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Informe um e-mail válido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                _CampoTexto(
                  controller: _enderecoController,
                  label: 'Endereço completo',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                _CampoTexto(
                  controller: _observacoesController,
                  label: 'Observações',
                  icon: Icons.notes,
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _salvar,
          icon: const Icon(Icons.save),
          label: Text(_isEdicao ? 'Salvar alterações' : 'Cadastrar'),
        ),
      ],
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

