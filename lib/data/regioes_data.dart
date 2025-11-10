import '../models/regiao.dart';

class RegioesData {
  static List<Regiao> getRegioesIniciais() {
    return [
      Regiao(
        id: 'reg01',
        nome: 'REGIÃO 01',
        numero: 1,
        regionais: [
          Regional(
            id: 'cre_brazlandia',
            nome: 'Coordenação Regional de Ensino de Brazlândia',
            sigla: 'CRE Brazlândia',
          ),
          Regional(
            id: 'cre_ceilandia',
            nome: 'Coordenação Regional de Ensino de Ceilândia',
            sigla: 'CRE Ceilândia',
          ),
          Regional(
            id: 'cre_taguatinga',
            nome: 'Coordenação Regional de Ensino de Taguatinga',
            sigla: 'CRE Taguatinga',
          ),
        ],
      ),
      Regiao(
        id: 'reg02',
        nome: 'REGIÃO 02',
        numero: 2,
        regionais: [
          Regional(
            id: 'cre_gama',
            nome: 'Coordenação Regional de Ensino do Gama',
            sigla: 'CRE Gama',
          ),
          Regional(
            id: 'cre_recanto',
            nome: 'Coordenação Regional de Ensino do Recanto das Emas',
            sigla: 'CRE Recanto das Emas',
          ),
          Regional(
            id: 'cre_samambaia',
            nome: 'Coordenação Regional de Ensino de Samambaia',
            sigla: 'CRE Samambaia',
          ),
          Regional(
            id: 'cre_santa_maria',
            nome: 'Coordenação Regional de Ensino de Santa Maria',
            sigla: 'CRE Santa Maria',
          ),
        ],
      ),
      Regiao(
        id: 'reg03',
        nome: 'REGIÃO 03',
        numero: 3,
        regionais: [
          Regional(
            id: 'cre_guara',
            nome: 'Coordenação Regional de Ensino do Guará',
            sigla: 'CRE Guará',
          ),
          Regional(
            id: 'cre_nucleo',
            nome: 'Coordenação Regional de Ensino do Núcleo Bandeirante',
            sigla: 'CRE Núcleo Bandeirante',
          ),
          Regional(
            id: 'cre_plano',
            nome: 'Coordenação Regional de Ensino do Plano Piloto',
            sigla: 'CRE Plano Piloto',
          ),
          Regional(
            id: 'cre_sobradinho',
            nome: 'Coordenação Regional de Ensino de Sobradinho',
            sigla: 'CRE Sobradinho',
          ),
        ],
      ),
      Regiao(
        id: 'reg04',
        nome: 'REGIÃO 04',
        numero: 4,
        regionais: [
          Regional(
            id: 'cre_planaltina',
            nome: 'Coordenação Regional de Ensino de Planaltina',
            sigla: 'CRE Planaltina',
          ),
          Regional(
            id: 'cre_sao_sebastiao',
            nome: 'Coordenação Regional de Ensino de São Sebastião',
            sigla: 'CRE São Sebastião',
          ),
          Regional(
            id: 'cre_paranoa',
            nome: 'Coordenação Regional de Ensino do Paranoá',
            sigla: 'CRE Paranoá',
          ),
        ],
      ),
    ];
  }
}
