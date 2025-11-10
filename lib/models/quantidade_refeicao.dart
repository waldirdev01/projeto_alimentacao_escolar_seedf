class QuantidadeRefeicao {
  final String id;
  final String nome;
  final String sigla;
  final String descricao;
  final bool ativo;

  QuantidadeRefeicao({
    required this.id,
    required this.nome,
    required this.sigla,
    required this.descricao,
    this.ativo = true,
  });

  QuantidadeRefeicao copyWith({
    String? id,
    String? nome,
    String? sigla,
    String? descricao,
    bool? ativo,
  }) {
    return QuantidadeRefeicao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sigla: sigla ?? this.sigla,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'sigla': sigla,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  factory QuantidadeRefeicao.fromJson(Map<String, dynamic> json) {
    return QuantidadeRefeicao(
      id: json['id'],
      nome: json['nome'],
      sigla: json['sigla'],
      descricao: json['descricao'],
      ativo: json['ativo'] ?? true,
    );
  }

  // Métodos para banco de dados
  Map<String, dynamic> toMap() {
    return {'id': id, 'nome': nome, 'sigla': sigla, 'ativo': ativo ? 1 : 0};
  }

  factory QuantidadeRefeicao.fromMap(Map<String, dynamic> map) {
    return QuantidadeRefeicao(
      id: map['id'],
      nome: map['nome'],
      sigla: map['sigla'],
      descricao: '', // Não armazenamos descricao no BD
      ativo: map['ativo'] == 1,
    );
  }
}
