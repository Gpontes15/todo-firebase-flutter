import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TarefaService {
  final CollectionReference _tarefas = FirebaseFirestore.instance.collection('tarefas');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // AGORA FILTRAMOS PELO UID DO USUÁRIO LOGADO
  Stream<QuerySnapshot> getTarefasStream() {
    String uid = _auth.currentUser?.uid ?? 'anonimo';
    return _tarefas
        .where('userId', isEqualTo: uid) // <-- O FILTRO MÁGICO
        .orderBy('dataCriacao', descending: true)
        .snapshots();
  }

  Future<String?> adicionarTarefa(String nome, {DateTime? dataVencimento, bool? diaTodo, String recorrencia = 'nenhuma'}) async {
    try {
      String uid = _auth.currentUser?.uid ?? 'anonimo';
      DocumentReference docRef = await _tarefas.add({
        'userId': uid, // <-- GUARDAMOS O DONO
        'nome': nome,
        'concluida': false,
        'dataCriacao': FieldValue.serverTimestamp(),
        'dataVencimento': dataVencimento,
        'diaTodo': diaTodo ?? false,
        'recorrencia': recorrencia,
      });
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  Future<void> atualizarNomeTarefa(String id, String novoNome) async {
    await _tarefas.doc(id).update({"nome": novoNome});
  }

  Future<void> alternarStatusTarefa(String id, bool statusAtual) async {
    await _tarefas.doc(id).update({"concluida": !statusAtual});
  }

  Future<void> deletarTarefa(String id) async {
    await _tarefas.doc(id).delete();
  }
}