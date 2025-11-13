enum TipoAta {
  julgamento('Ata de Julgamento'),
  registroPreco('Ata de Registro de Preço');

  final String displayName;
  const TipoAta(this.displayName);
}

class QuadroTecnicoDescritivo {
  final String id;
  final String processoId;
  final String memoriaCalculoId;
  final String numeroAtaJulgamento;
  final TipoAta tipoAta;
  final DateTime dataAta;
  final DateTime dataCriacao; // Mantido para compatibilidade
  final String fonte;
  final List<FornecedorQtd> fornecedores;

  const QuadroTecnicoDescritivo({
    required this.id,
    required this.processoId,
    required this.memoriaCalculoId,
    required this.numeroAtaJulgamento,
    required this.tipoAta,
    required this.dataAta,
    required this.dataCriacao,
    required this.fonte,
    required this.fornecedores,
  });

  QuadroTecnicoDescritivo copyWith({
    String? id,
    String? processoId,
    String? memoriaCalculoId,
    String? numeroAtaJulgamento,
    TipoAta? tipoAta,
    DateTime? dataAta,
    DateTime? dataCriacao,
    String? fonte,
    List<FornecedorQtd>? fornecedores,
  }) {
    return QuadroTecnicoDescritivo(
      id: id ?? this.id,
      processoId: processoId ?? this.processoId,
      memoriaCalculoId: memoriaCalculoId ?? this.memoriaCalculoId,
      numeroAtaJulgamento: numeroAtaJulgamento ?? this.numeroAtaJulgamento,
      tipoAta: tipoAta ?? this.tipoAta,
      dataAta: dataAta ?? this.dataAta,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      fonte: fonte ?? this.fonte,
      fornecedores: fornecedores ?? this.fornecedores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'processoId': processoId,
      'memoriaCalculoId': memoriaCalculoId,
      'numeroAtaJulgamento': numeroAtaJulgamento,
      'tipoAta': tipoAta.name,
      'dataAta': dataAta.toIso8601String(),
      'dataCriacao': dataCriacao.toIso8601String(),
      'fonte': fonte,
      'fornecedores': fornecedores.map((f) => f.toJson()).toList(),
    };
  }

  factory QuadroTecnicoDescritivo.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is Map && value.containsKey('_seconds')) {
        final seconds = value['_seconds'] as int? ?? 0;
        final nanos = value['_nanoseconds'] as int? ?? 0;
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + (nanos ~/ 1000000),
        );
      }
      return DateTime.now();
    }

    final dataAta = _parseDate(json['dataAta'] ?? json['dataCriacao']);
    final dataCriacao = _parseDate(json['dataCriacao']);
    final tipoAtaStr = json['tipoAta'] as String? ?? 'julgamento';
    final tipoAta = TipoAta.values.firstWhere(
      (t) => t.name == tipoAtaStr,
      orElse: () => TipoAta.julgamento,
    );

    return QuadroTecnicoDescritivo(
      id: json['id'],
      processoId: json['processoId'],
      memoriaCalculoId: json['memoriaCalculoId'],
      numeroAtaJulgamento: json['numeroAtaJulgamento'] ?? json['numeroQtd'] ?? '',
      tipoAta: tipoAta,
      dataAta: dataAta,
      dataCriacao: dataCriacao,
      fonte: json['fonte'] ?? '',
      fornecedores: (json['fornecedores'] as List<dynamic>? ?? [])
          .map((f) => FornecedorQtd.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FornecedorQtd {
  final String id;
  final String nome;
  final List<ItemQtd> itens;

  const FornecedorQtd({
    required this.id,
    required this.nome,
    required this.itens,
  });

  double get subtotalValor {
    return itens.fold<double>(
      0,
      (total, item) => total + item.valorTotalReais,
    );
  }

  Map<String, double> get totaisPorRegiao {
    final Map<String, double> totais = {};
    for (final item in itens) {
      item.quantidadesPorRegiaoKg.forEach((regiaoId, quantidade) {
        totais.update(
          regiaoId,
          (value) => value + quantidade,
          ifAbsent: () => quantidade,
        );
      });
    }
    return totais;
  }

  FornecedorQtd copyWith({
    String? id,
    String? nome,
    List<ItemQtd>? itens,
  }) {
    return FornecedorQtd(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      itens: itens ?? this.itens,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'itens': itens.map((i) => i.toJson()).toList(),
    };
  }

  factory FornecedorQtd.fromJson(Map<String, dynamic> json) {
    return FornecedorQtd(
      id: json['id'],
      nome: json['nome'] ?? '',
      itens: (json['itens'] as List<dynamic>? ?? [])
          .map((i) => ItemQtd.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ItemQtd {
  final String numeroItemEdital; // Número do item no edital (preenchido pelo usuário)
  final int itemNumero; // Mantido para compatibilidade
  final String produtoId;
  final String produtoNome;
  final double valorUnitarioReais;
  final Map<String, double> quantidadesPorRegiaoKg; // Mantido para compatibilidade
  final Map<String, double> cotaPrincipalPorRegiaoKg; // Cota Principal por região
  final Map<String, double> cotaReservadaPorRegiaoKg; // Cota Reservada por região

  const ItemQtd({
    required this.numeroItemEdital,
    required this.itemNumero,
    required this.produtoId,
    required this.produtoNome,
    required this.valorUnitarioReais,
    required this.quantidadesPorRegiaoKg,
    required this.cotaPrincipalPorRegiaoKg,
    required this.cotaReservadaPorRegiaoKg,
  });

  double get quantidadeTotalKg {
    // Soma das cotas principal e reservada
    final totalPrincipal = cotaPrincipalPorRegiaoKg.values.fold(
      0.0,
      (total, qtd) => total + qtd,
    );
    final totalReservada = cotaReservadaPorRegiaoKg.values.fold(
      0.0,
      (total, qtd) => total + qtd,
    );
    return totalPrincipal + totalReservada;
  }

  double get quantidadeTotalPrincipalKg {
    return cotaPrincipalPorRegiaoKg.values.fold(
      0.0,
      (total, qtd) => total + qtd,
    );
  }

  double get quantidadeTotalReservadaKg {
    return cotaReservadaPorRegiaoKg.values.fold(
      0.0,
      (total, qtd) => total + qtd,
    );
  }

  double get valorTotalReais {
    return quantidadeTotalKg * valorUnitarioReais;
  }

  ItemQtd copyWith({
    String? numeroItemEdital,
    int? itemNumero,
    String? produtoId,
    String? produtoNome,
    double? valorUnitarioReais,
    Map<String, double>? quantidadesPorRegiaoKg,
    Map<String, double>? cotaPrincipalPorRegiaoKg,
    Map<String, double>? cotaReservadaPorRegiaoKg,
  }) {
    return ItemQtd(
      numeroItemEdital: numeroItemEdital ?? this.numeroItemEdital,
      itemNumero: itemNumero ?? this.itemNumero,
      produtoId: produtoId ?? this.produtoId,
      produtoNome: produtoNome ?? this.produtoNome,
      valorUnitarioReais: valorUnitarioReais ?? this.valorUnitarioReais,
      quantidadesPorRegiaoKg:
          quantidadesPorRegiaoKg ?? this.quantidadesPorRegiaoKg,
      cotaPrincipalPorRegiaoKg:
          cotaPrincipalPorRegiaoKg ?? this.cotaPrincipalPorRegiaoKg,
      cotaReservadaPorRegiaoKg:
          cotaReservadaPorRegiaoKg ?? this.cotaReservadaPorRegiaoKg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numeroItemEdital': numeroItemEdital,
      'itemNumero': itemNumero,
      'produtoId': produtoId,
      'produtoNome': produtoNome,
      'valorUnitarioReais': valorUnitarioReais,
      'quantidadesPorRegiaoKg': quantidadesPorRegiaoKg,
      'cotaPrincipalPorRegiaoKg': cotaPrincipalPorRegiaoKg,
      'cotaReservadaPorRegiaoKg': cotaReservadaPorRegiaoKg,
    };
  }

  factory ItemQtd.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> quantidades =
        json['quantidadesPorRegiaoKg'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> cotaPrincipal =
        json['cotaPrincipalPorRegiaoKg'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> cotaReservada =
        json['cotaReservadaPorRegiaoKg'] as Map<String, dynamic>? ?? {};

    // Se não tiver as novas cotas, usar quantidadesPorRegiaoKg como fallback
    final cotaPrincipalFinal = cotaPrincipal.isEmpty && quantidades.isNotEmpty
        ? quantidades
        : cotaPrincipal;
    final cotaReservadaFinal = cotaReservada.isEmpty && quantidades.isNotEmpty
        ? <String, dynamic>{}
        : cotaReservada;

    return ItemQtd(
      numeroItemEdital: json['numeroItemEdital'] as String? ?? 
          (json['itemNumero'] != null ? json['itemNumero'].toString() : ''),
      itemNumero: json['itemNumero'] ?? 0,
      produtoId: json['produtoId'],
      produtoNome: json['produtoNome'] ?? '',
      valorUnitarioReais:
          (json['valorUnitarioReais'] as num?)?.toDouble() ?? 0.0,
      quantidadesPorRegiaoKg: quantidades.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      cotaPrincipalPorRegiaoKg: cotaPrincipalFinal.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      cotaReservadaPorRegiaoKg: cotaReservadaFinal.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}

