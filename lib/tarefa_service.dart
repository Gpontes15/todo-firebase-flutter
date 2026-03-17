import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaService {
  final CollectionReference _tarefas = FirebaseFirestore.instance.collection('tarefas');

  // CREATE - Agora salvando a data exata da criação!
  Future<void> adicionarTarefa(String nome) async {
    await _tarefas.add({
      "nome": nome, 
      "concluida": false,
      // Pede para o servidor do Firebase carimbar a hora exata
      "dataCriacao": FieldValue.serverTimestamp(), 
    });
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

  // READ - Agora com a instrução ORDER BY do Firebase!
  Stream<QuerySnapshot> getTarefasStream() {
    // orderBy('campo', descending: true) faz com que as mais novas fiquem no topo
    return _tarefas.orderBy('dataCriacao', descending: true).snapshots();
  }
}