import 'package:flutter/material.dart';
import '../../Simulados/SimuladosMateria_Screen.dart';
import 'materia_card.dart';

class AreaBlocos extends StatelessWidget {
  final Map<String, List<String>> topicosPorMateria;
  final Map<String, dynamic> resultados;
  final Map<String, String> areaPorMateria;

  const AreaBlocos({
    super.key,
    required this.topicosPorMateria,
    required this.resultados,
    required this.areaPorMateria,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Widget>> blocos = {
      'Exatas': [],
      'Humanas': [],
      'Biológicas': [],
      'Linguagens': [],
      'Outros': [],
    };

    final Map<String, List<String>> materiasPorArea = {
      'Exatas': [],
      'Humanas': [],
      'Biológicas': [],
      'Linguagens': [],
      'Outros': [],
    };

    for (final entry in topicosPorMateria.entries) {
      final area = areaPorMateria[entry.key] ?? 'Outros';
      blocos[area]!.add(MateriaCard(
        materia: entry.key,
        topicos: entry.value,
        resultados: resultados,
      ));
      materiasPorArea[area]!.add(entry.key);
    }

    final Map<String, IconData> iconesPorArea = {
      'Exatas': Icons.calculate,
      'Humanas': Icons.menu_book_rounded,
      'Biológicas': Icons.biotech,
      'Linguagens': Icons.language,
      'Outros': Icons.category,
    };

    final List<Widget> widgets = [];

    blocos.forEach((area, cards) {
      if (cards.isEmpty) return;

      final progressoArea = _calcularProgressoArea(materiasPorArea[area]!);

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(iconesPorArea[area] ?? Icons.school, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    area,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progressoArea * 100).toInt()}% concluído',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 240,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: cards,
                ),
              ),
              const SizedBox(height: 10),
              if (progressoArea < 0.01)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Só será desbloqueado o simulado quando chegar a 25% de conclusão',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: progressoArea >= 0.01
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SimuladoScreen(area: area),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: progressoArea >= 0.5 ? Colors.green : Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.quiz_outlined, color: Colors.white),
                  label: const Text('Realizar Simulado específico', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );

  }

  double _calcularProgressoArea(List<String> materias) {
    int total = 0;
    int feitos = 0;
    for (final materia in materias) {
      final topicos = topicosPorMateria[materia] ?? [];
      total += topicos.length;
      feitos += topicos.where((t) => resultados[t] == 'aprovado').length;
    }
    return total == 0 ? 0 : feitos / total;
  }
}
