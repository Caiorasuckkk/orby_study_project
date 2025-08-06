import 'package:flutter/material.dart';
import '../../aulas/Aulasscreen.dart';


class MateriaCard extends StatelessWidget {
  final String materia;
  final List<String> topicos;
  final Map<String, dynamic> resultados;

  const MateriaCard({
    super.key,
    required this.materia,
    required this.topicos,
    required this.resultados,
  });

  @override
  Widget build(BuildContext context) {
    int ultimoAprovadoIndex = -1;
    for (int i = 0; i < topicos.length; i++) {
      if (resultados[topicos[i]] == 'aprovado') {
        ultimoAprovadoIndex = i;
      }
    }

    double progresso = _calcularProgresso();

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3D),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: CircularProgressIndicator(
                            value: progresso,
                            strokeWidth: 6,
                            backgroundColor: Colors.grey.shade700,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progresso == 1.0 ? Colors.amberAccent : Colors.greenAccent,
                            ),
                          ),
                        ),
                        Text(
                          '${(progresso * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        materia,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: topicos.length,
                    itemBuilder: (context, index) {
                      final topico = topicos[index];
                      final desbloqueado = index <= ultimoAprovadoIndex + 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: InkWell(
                            onTap: desbloqueado
                                ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AulasScreen(
                                    submateria: topico,
                                    materia: materia,
                                  ),
                                ),
                              );
                            }
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: desbloqueado ? const Color(0xFF1F2F3F) : Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade500, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      topico,
                                      style: TextStyle(
                                        color: desbloqueado ? Colors.white : Colors.white54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (resultados[topico] == 'aprovado')
                                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
                                  else if (!desbloqueado)
                                    const Icon(Icons.lock_outline, color: Colors.white54, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calcularProgresso() {
    if (topicos.isEmpty) return 0;
    final total = topicos.length;
    final feitos = topicos.where((t) => resultados[t] == 'aprovado').length;
    return feitos / total;
  }
}
