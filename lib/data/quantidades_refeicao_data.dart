import '../models/quantidade_refeicao.dart';

class QuantidadesRefeicaoData {
  static List<QuantidadeRefeicao> getQuantidadesIniciais() {
    return [
      QuantidadeRefeicao(
        id: '1',
        nome: 'Uma Refeição',
        sigla: '1 REF',
        descricao: 'Alunos que fazem apenas uma refeição na escola',
      ),
      QuantidadeRefeicao(
        id: '2',
        nome: 'Duas Refeições',
        sigla: '2 REF',
        descricao: 'Alunos que fazem duas refeições na escola',
      ),
      QuantidadeRefeicao(
        id: '3',
        nome: 'Três Refeições',
        sigla: '3 REF',
        descricao: 'Alunos que fazem três refeições na escola',
      ),
      QuantidadeRefeicao(
        id: '4',
        nome: 'Quatro Refeições',
        sigla: '4 REF',
        descricao: 'Alunos que fazem quatro refeições na escola',
      ),
      QuantidadeRefeicao(
        id: '5',
        nome: 'Programa Candanga',
        sigla: 'Candanga',
        descricao: 'Alunos do programa Candanga',
      ),
      QuantidadeRefeicao(
        id: '6',
        nome: 'Lanche Fácil',
        sigla: 'Lanche Fácil',
        descricao: 'Alunos que recebem lanche fácil',
      ),
    ];
  }
}
