import 'dart:convert';

import 'escola.dart';

enum TipoProduto { perecivel, naoPerecivel }

class Produto {
  final String id;
  final String nome;
  final String? fabricante;
  final String? distribuidor;
  final String? marca;
  final String? ingredientes;
  final TipoProduto tipo;
  final Map<String, double>
  perCapita; // Chave: modalidade_quantidadeRefeicao, Valor: per capita
  // Multi-domínios: ex.: gpae, distribuicao, etc. Usa a mesma chave flat
  // (modalidade_quantidadeRefeicao) para compatibilidade.
  final Map<String, Map<String, double>> perCapitaByDomain;
  final Map<String, double>
  valoresNutricionais; // Valores nutricionais por 100g

  Produto({
    required this.id,
    required this.nome,
    this.fabricante,
    this.distribuidor,
    this.marca,
    this.ingredientes,
    required this.tipo,
    required this.perCapita,
    this.perCapitaByDomain = const {},
    this.valoresNutricionais = const {},
  });

  double getPerCapita(
    ModalidadeEnsino modalidade,
    String quantidadeRefeicaoId,
  ) {
    final chave = '${modalidade.name}_$quantidadeRefeicaoId';
    return perCapita[chave] ?? 0.0;
  }

  double getValorNutricional(String nutriente) {
    return valoresNutricionais[nutriente] ?? 0.0;
  }

  double getPerCapitaForDomain(
    String domainId,
    ModalidadeEnsino modalidade,
    String quantidadeRefeicaoId,
  ) {
    final chave = '${modalidade.name}_$quantidadeRefeicaoId';
    final mapaDominio = perCapitaByDomain[domainId];
    if (mapaDominio != null && mapaDominio.containsKey(chave)) {
      return mapaDominio[chave] ?? 0.0;
    }
    // Fallback para o mapa legado
    return getPerCapita(modalidade, quantidadeRefeicaoId);
  }

  Produto copyWith({
    String? id,
    String? nome,
    String? fabricante,
    String? distribuidor,
    String? marca,
    String? ingredientes,
    TipoProduto? tipo,
    Map<String, double>? perCapita,
    Map<String, Map<String, double>>? perCapitaByDomain,
    Map<String, double>? valoresNutricionais,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      fabricante: fabricante ?? this.fabricante,
      distribuidor: distribuidor ?? this.distribuidor,
      marca: marca ?? this.marca,
      ingredientes: ingredientes ?? this.ingredientes,
      tipo: tipo ?? this.tipo,
      perCapita: perCapita ?? this.perCapita,
      perCapitaByDomain: perCapitaByDomain ?? this.perCapitaByDomain,
      valoresNutricionais: valoresNutricionais ?? this.valoresNutricionais,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'fabricante': fabricante,
      'distribuidor': distribuidor,
      'marca': marca,
      'ingredientes': ingredientes,
      'tipo': tipo.name,
      'perCapita': perCapita,
      'perCapitaByDomain': perCapitaByDomain,
      'valoresNutricionais': valoresNutricionais,
    };
  }

  factory Produto.fromJson(Map<String, dynamic> json) {
    // Normalizar perCapitaByDomain
    final dynamicPcbd = json['perCapitaByDomain'];
    final Map<String, Map<String, double>> pcbd = {};
    if (dynamicPcbd is Map) {
      dynamicPcbd.forEach((key, value) {
        if (value is Map) {
          pcbd[key as String] = Map<String, double>.from(value);
        }
      });
    }

    return Produto(
      id: json['id'],
      nome: json['nome'],
      fabricante: json['fabricante'],
      distribuidor: json['distribuidor'],
      marca: json['marca'],
      ingredientes: json['ingredientes'],
      tipo: TipoProduto.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoProduto.naoPerecivel,
      ),
      perCapita: Map<String, double>.from(json['perCapita'] ?? {}),
      perCapitaByDomain: pcbd,
      valoresNutricionais: Map<String, double>.from(
        json['valoresNutricionais'] ?? {},
      ),
    );
  }

  // Métodos para banco de dados
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'idProduto': id,
      'fabricante': fabricante,
      'distribuidora': distribuidor,
      'marca': marca,
      'ingredientes': ingredientes,
      'tipo': tipo.name,
      'valoresPerCapita': jsonEncode(perCapita),
      'valoresPerCapitaByDomain': jsonEncode(perCapitaByDomain),
      'valoresNutricionais': jsonEncode(valoresNutricionais),
    };
  }

  factory Produto.fromMap(Map<String, dynamic> map) {
    // Normalizar perCapitaByDomain
    final Map<String, Map<String, double>> pcbd = {};
    try {
      final decoded = jsonDecode(map['valoresPerCapitaByDomain'] ?? '{}');
      if (decoded is Map) {
        decoded.forEach((key, value) {
          if (value is Map) {
            pcbd[key as String] = Map<String, double>.from(value);
          }
        });
      }
    } catch (_) {}

    return Produto(
      id: map['id'],
      nome: map['nome'],
      fabricante: map['fabricante'],
      distribuidor: map['distribuidora'],
      marca: map['marca'],
      ingredientes: map['ingredientes'],
      tipo: TipoProduto.values.firstWhere(
        (e) => e.name == map['tipo'],
        orElse: () => TipoProduto.naoPerecivel,
      ),
      perCapita: Map<String, double>.from(
        jsonDecode(map['valoresPerCapita'] ?? '{}'),
      ),
      perCapitaByDomain: pcbd,
      valoresNutricionais: Map<String, double>.from(
        jsonDecode(map['valoresNutricionais'] ?? '{}'),
      ),
    );
  }
}

extension ModalidadeEnsinoExtension on ModalidadeEnsino {
  String get displayName {
    switch (this) {
      case ModalidadeEnsino.preEscola:
        return 'Pré-Escola';
      case ModalidadeEnsino.fundamental1:
        return 'Fundamental 1';
      case ModalidadeEnsino.fundamental2:
        return 'Fundamental 2';
      case ModalidadeEnsino.ensinoMedio:
        return 'Ensino Médio';
      case ModalidadeEnsino.eja:
        return 'EJA';
    }
  }
}
