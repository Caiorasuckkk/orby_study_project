import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Retorna o nome completo do usuário e os dados do Orby
  static Future<Map<String, dynamic>?> getUsuarioInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      final data = doc.data();
      if (data == null) return null;

      return {
        'nomeCompleto':
            '${data['primeiro_nome'] ?? ''} ${data['sobrenome'] ?? ''}',
        'orby_nome': data['orby_nome'] ?? 'Orby',
        'orby_cor': data['orby_cor'] ?? 'Azul',
        'orby_avatar': data['orby_avatar'] ?? 'assets/images/orby_base2.png',
      };
    } catch (e) {
      print('Erro ao buscar usuário: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getTopicosPorMateria(
    Map<String, String> areaPorMateria,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final Map<String, List<String>> topicos = {};
      final List<String> materias = areaPorMateria.keys.toList();

      for (final materia in materias) {
        final subtopicosSnap =
            await _firestore
                .collection('Estudo')
                .doc(materia)
                .collection(materia)
                .get();

        if (subtopicosSnap.docs.isNotEmpty) {
          topicos[materia] = subtopicosSnap.docs.map((e) => e.id).toList();
        }
      }

      // Buscar os resultados da subcoleção "Resultados"
      final resultadosSnapshot =
          await _firestore
              .collection("usuarios")
              .doc(user.uid)
              .collection("Resultados")
              .get();

      final Map<String, dynamic> resultados = {
        for (final doc in resultadosSnapshot.docs)
          doc.id: doc.data()['status'] ?? 'pendente',
      };

      return {'topicos': topicos, 'resultados': resultados};
    } catch (e) {
      print('Erro ao carregar matérias: $e');
      return {};
    }
  }
}
