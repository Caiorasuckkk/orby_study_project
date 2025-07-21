import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> salvarConteudoConjuntos() async {
  final firestore = FirebaseFirestore.instance;

  final Map<String, dynamic> dados ={
    "tema": "Segundo Reinado: Café, Escravidão e Poder Moderador",
    "aula": "Durante o Segundo Reinado (1840–1889), o Brasil passou por grandes transformações sociais e econômicas. O cultivo do café tornou-se a principal atividade econômica, especialmente no Sudeste, consolidando uma elite cafeeira influente na política. A escravidão continuava como base da economia, apesar do avanço das ideias abolicionistas e da pressão internacional, principalmente da Inglaterra. O Poder Moderador, uma das quatro atribuições constitucionais do imperador, garantia a Dom Pedro II o controle sobre os demais poderes, conferindo-lhe grande influência. Esse período também marcou o surgimento de movimentos abolicionistas, a imigração europeia para substituir a mão de obra escravizada, e o fortalecimento do Estado brasileiro como monarquia constitucional centralizada.",
    "video": "https://www.youtube.com/watch?v=4AGGFS_fRPo",
    "video2": "https://www.youtube.com/watch?v=qM8Q5IByILk&t=3s",
    "exercicios": [
      {
        "pergunta": "Qual foi a principal base econômica do Segundo Reinado?",
        "alternativas": [
          "Extração de ouro.",
          "Plantio de cana-de-açúcar.",
          "Café.",
          "Mineração de diamantes."
        ],
        "resposta_correta": "Café.",
        "explicacao": "O café tornou-se a base da economia nacional, especialmente no Sudeste."
      },
      {
        "pergunta": "O Poder Moderador era:",
        "alternativas": [
          "Um ministério controlado pelo Parlamento.",
          "O poder de veto dos senadores.",
          "A autoridade do imperador sobre os três poderes.",
          "Um conselho de nobres para revisar leis."
        ],
        "resposta_correta": "A autoridade do imperador sobre os três poderes.",
        "explicacao": "O Poder Moderador dava a Dom Pedro II controle sobre Executivo, Legislativo e Judiciário."
      },
      {
        "pergunta": "A Inglaterra pressionava o Brasil para:",
        "alternativas": [
          "Aumentar a produção de açúcar.",
          "Adotar o parlamentarismo.",
          "Abolir a escravidão.",
          "Expandir as colônias no interior do país."
        ],
        "resposta_correta": "Abolir a escravidão.",
        "explicacao": "Os ingleses pressionavam o Brasil a acabar com o tráfico negreiro e a escravidão."
      },
      {
        "pergunta": "Com o fim gradual da escravidão, o Brasil incentivou:",
        "alternativas": [
          "A vinda de imigrantes europeus.",
          "O uso de mão de obra indígena.",
          "A volta do trabalho compulsório africano.",
          "A mecanização do campo."
        ],
        "resposta_correta": "A vinda de imigrantes europeus.",
        "explicacao": "Imigrantes passaram a ocupar os postos de trabalho antes destinados a escravizados."
      },
      {
        "pergunta": "O Segundo Reinado foi marcado politicamente por:",
        "alternativas": [
          "Ditadura militar.",
          "Alternância entre partidos liberal e conservador.",
          "Domínio das classes operárias.",
          "Descentralização do poder imperial."
        ],
        "resposta_correta": "Alternância entre partidos liberal e conservador.",
        "explicacao": "Esses dois partidos se revezavam no poder, com o aval do imperador através do Poder Moderador."
      }
    ]
  }


  ;

  await firestore
      .collection("Estudo")
      .doc("Historia")
      .collection("História do Brasil")
      .doc("Segundo Reinado: Café, Escravidão e Poder Moderador")
      .set(dados);

  print("Conteúdo salvo com sucesso.");
}
