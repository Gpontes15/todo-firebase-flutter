import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaService {
  final CollectionReference _tarefas = FirebaseFirestore.instance.collection('tarefas');

  Stream<QuerySnapshot> getTarefasStream() {
    return _tarefas.orderBy('dataCriacao', descending: true).snapshots();
  }

  // Adicionámos a variável 'recorrencia' com valor padrão 'nenhuma'
  Future<String?> adicionarTarefa(String nome, {DateTime? dataVencimento, bool? diaTodo, String recorrencia = 'nenhuma'}) async {
    try {
      DocumentReference docRef = await _tarefas.add({
        'nome': nome,
        'concluida': false,
        'dataCriacao': FieldValue.serverTimestamp(),
        'dataVencimento': dataVencimento,
        'diaTodo': diaTodo ?? false,
        'recorrencia': recorrencia, // O Firebase agora guarda isto!
      });
      return docRef.id;
    } catch (e) {
      print('Erro ao adicionar tarefa: $e');
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