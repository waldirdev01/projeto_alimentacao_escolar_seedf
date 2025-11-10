class Regiao {
  final String id;
  final String nome;
  final int numero;
  final List<Regional> regionais;

  Regiao({
    required this.id,
    required this.nome,
    required this.numero,
    required this.regionais,
  });

  Regiao copyWith({
    String? id,
    String? nome,
    int? numero,
    List<Regional>? regionais,
  }) {
    return Regiao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      numero: numero ?? this.numero,
      regionais: regionais ?? this.regionais,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'numero': numero,
      'regionais': regionais.map((r) => r.toJson()).toList(),
    };
  }

  factory Regiao.fromJson(Map<String, dynamic> json) {
    return Regiao(
      id: json['id'],
      nome: json['nome'],
      numero: json['numero'],
      regionais: (json['regionais'] as List)
          .map((r) => Regional.fromJson(r))
          .toList(),
    );
  }
}

class Regional {
  final String id;
  final String nome;
  final String sigla;

  Regional({required this.id, required this.nome, required this.sigla});

  Regional copyWith({String? id, String? nome, String? sigla}) {
    return Regional(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sigla: sigla ?? this.sigla,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'sigla': sigla};
  }

  factory Regional.fromJson(Map<String, dynamic> json) {
    return Regional(id: json['id'], nome: json['nome'], sigla: json['sigla']);
  }
}
