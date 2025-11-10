class ValoresNutricionaisData {
  // Valores nutricionais baseados na TACO (Tabela Brasileira de Composição de Alimentos)
  // e padrões do FNDE para merenda escolar
  static Map<String, Map<String, double>> getValoresNutricionaisPadrao() {
    return {
      // Cereais e derivados
      'arroz': {
        'calorias': 130.0, // kcal por 100g
        'proteina': 2.7, // g por 100g
        'carboidrato': 28.0, // g por 100g
        'lipideo': 0.3, // g por 100g
        'fibra': 0.4, // g por 100g
        'calcio': 8.0, // mg por 100g
        'ferro': 0.4, // mg por 100g
        'sodio': 1.0, // mg por 100g
      },
      'feijao': {
        'calorias': 76.0,
        'proteina': 4.8,
        'carboidrato': 13.6,
        'lipideo': 0.5,
        'fibra': 8.7,
        'calcio': 27.0,
        'ferro': 1.5,
        'sodio': 2.0,
      },
      'macarrao': {
        'calorias': 131.0,
        'proteina': 5.0,
        'carboidrato': 25.0,
        'lipideo': 1.2,
        'fibra': 1.8,
        'calcio': 8.0,
        'ferro': 1.2,
        'sodio': 2.0,
      },
      'milho': {
        'calorias': 98.0,
        'proteina': 3.2,
        'carboidrato': 17.1,
        'lipideo': 1.2,
        'fibra': 2.4,
        'calcio': 2.0,
        'ferro': 0.8,
        'sodio': 1.0,
      },

      // Carnes
      'carne_bovina': {
        'calorias': 213.0,
        'proteina': 21.5,
        'carboidrato': 0.0,
        'lipideo': 12.7,
        'fibra': 0.0,
        'calcio': 7.0,
        'ferro': 2.4,
        'sodio': 65.0,
      },
      'frango': {
        'calorias': 190.0,
        'proteina': 20.8,
        'carboidrato': 0.0,
        'lipideo': 11.3,
        'fibra': 0.0,
        'calcio': 9.0,
        'ferro': 1.2,
        'sodio': 68.0,
      },

      // Laticínios
      'leite_pó': {
        'calorias': 496.0,
        'proteina': 25.4,
        'carboidrato': 38.4,
        'lipideo': 26.3,
        'fibra': 0.0,
        'calcio': 912.0,
        'ferro': 0.4,
        'sodio': 371.0,
      },

      // Óleos e gorduras
      'oleo': {
        'calorias': 884.0,
        'proteina': 0.0,
        'carboidrato': 0.0,
        'lipideo': 100.0,
        'fibra': 0.0,
        'calcio': 0.0,
        'ferro': 0.0,
        'sodio': 0.0,
      },

      // Hortaliças
      'tomate': {
        'calorias': 15.0,
        'proteina': 1.1,
        'carboidrato': 3.1,
        'lipideo': 0.2,
        'fibra': 1.2,
        'calcio': 8.0,
        'ferro': 0.3,
        'sodio': 2.0,
      },
      'cebola': {
        'calorias': 32.0,
        'proteina': 1.4,
        'carboidrato': 7.2,
        'lipideo': 0.2,
        'fibra': 2.1,
        'calcio': 23.0,
        'ferro': 0.2,
        'sodio': 2.0,
      },
      'cenoura': {
        'calorias': 34.0,
        'proteina': 1.3,
        'carboidrato': 7.7,
        'lipideo': 0.2,
        'fibra': 3.2,
        'calcio': 33.0,
        'ferro': 0.3,
        'sodio': 4.0,
      },

      // Frutas
      'banana': {
        'calorias': 89.0,
        'proteina': 1.1,
        'carboidrato': 22.8,
        'lipideo': 0.1,
        'fibra': 2.6,
        'calcio': 5.0,
        'ferro': 0.3,
        'sodio': 1.0,
      },
      'laranja': {
        'calorias': 45.0,
        'proteina': 1.0,
        'carboidrato': 11.5,
        'lipideo': 0.1,
        'fibra': 1.1,
        'calcio': 40.0,
        'ferro': 0.1,
        'sodio': 0.0,
      },

      // Tubérculos
      'batata': {
        'calorias': 77.0,
        'proteina': 2.0,
        'carboidrato': 17.8,
        'lipideo': 0.1,
        'fibra': 1.8,
        'calcio': 8.0,
        'ferro': 0.4,
        'sodio': 1.0,
      },
    };
  }

  // Método para obter valores nutricionais de um produto específico
  static Map<String, double> getValoresNutricionais(String nomeProduto) {
    final valores = getValoresNutricionaisPadrao();

    // Normalizar nome do produto para busca
    String nomeNormalizado = nomeProduto
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záàâãéèêíìîóòôõúùûç\s]'), '')
        .trim();

    // Buscar correspondência exata ou parcial
    for (final entry in valores.entries) {
      if (nomeNormalizado.contains(entry.key) ||
          entry.key.contains(nomeNormalizado.split(' ').first)) {
        return entry.value;
      }
    }

    // Retornar valores padrão se não encontrar
    return {
      'calorias': 0.0,
      'proteina': 0.0,
      'carboidrato': 0.0,
      'lipideo': 0.0,
      'fibra': 0.0,
      'calcio': 0.0,
      'ferro': 0.0,
      'sodio': 0.0,
    };
  }

  // Lista de nutrientes disponíveis
  static List<Map<String, String>> getNutrientesDisponiveis() {
    return [
      {'codigo': 'calorias', 'nome': 'Calorias', 'unidade': 'kcal'},
      {'codigo': 'proteina', 'nome': 'Proteína', 'unidade': 'g'},
      {'codigo': 'carboidrato', 'nome': 'Carboidrato', 'unidade': 'g'},
      {'codigo': 'lipideo', 'nome': 'Lipídeo', 'unidade': 'g'},
      {'codigo': 'fibra', 'nome': 'Fibra', 'unidade': 'g'},
      {'codigo': 'calcio', 'nome': 'Cálcio', 'unidade': 'mg'},
      {'codigo': 'ferro', 'nome': 'Ferro', 'unidade': 'mg'},
      {'codigo': 'sodio', 'nome': 'Sódio', 'unidade': 'mg'},
    ];
  }

  // Mapa de nutrientes para uso nos dialogs
  static Map<String, String> get nutrientes {
    return {
      'calorias': 'kcal',
      'proteina': 'g',
      'carboidrato': 'g',
      'lipideo': 'g',
      'fibra': 'g',
      'calcio': 'mg',
      'ferro': 'mg',
      'sodio': 'mg',
    };
  }

  // Método para obter valor nutricional específico
  static double getValorNutricional(String nomeProduto, String nutriente) {
    final valores = getValoresNutricionais(nomeProduto);
    return valores[nutriente] ?? 0.0;
  }
}
