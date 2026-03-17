import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaService {
  // 1. A referência do banco de dados agora vive EXCLUSIVAMENTE aqui.
  // Como ela é privada (tem o _), nenhuma outra classe consegue mexer nela direto.
  final CollectionReference _tarefas = FirebaseFirestore.instance.collection('tarefas');

  // CREATE
  Future<void> adicionarTarefa(String nome) async {
    await _tarefas.add({
      "nome": nome, 
      "concluida": false
    });
  }

  // UPDATE - Alterar o nome
  Future<void> atualizarNomeTarefa(String id, String novoNome) async {
    await _tarefas.doc(id).update({"nome": novoNome});
  }

  // UPDATE - Alterar o status (concluída/não concluída)
  Future<void> alternarStatusTarefa(String id, bool statusAtual) async {
    await _tarefas.doc(id).update({"concluida": !statusAtual});
  }

  // DELETE
  Future<void> deletarTarefa(String id) async {
    await _tarefas.doc(id).delete();
  }

  // READ - O "cano" de dados em tempo real
  // Retornamos o Stream para que o StreamBuilder lá na tela possa escutar
  Stream<QuerySnapshot> getTarefasStream() {
    return _tarefas.snapshots();
  }
}