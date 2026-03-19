import 'package:cloud_firestore/cloud_firestore.dart';

class TarefaService {
  final CollectionReference _tarefas = FirebaseFirestore.instance.collection('tarefas');

  // Alterámos de Future<void> para Future<String?>
  Future<String?> adicionarTarefa(String nome, {DateTime? dataVencimento, bool? diaTodo}) async {
    try {
      // Quando adicionamos ao Firebase, ele devolve uma "Referência" do documento criado
      DocumentReference docRef = await _tarefas.add({
        'nome': nome,
        'concluida': false,
        'dataCriacao': FieldValue.serverTimestamp(), // Marca a hora que foi criada
        'dataVencimento': dataVencimento,
        'diaTodo': diaTodo ?? false,
      });
      
      // Devolvemos o ID maravilhoso que o Firebase gerou para usarmos no alarme!
      return docRef.id; 
      
    } catch (e) {
      print('Erro ao adicionar tarefa: $e');
      return null; // Se der erro, devolve nulo
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

  // READ - Agora com a instrução ORDER BY do Firebase!
  Stream<QuerySnapshot> getTarefasStream() {
    // orderBy('campo', descending: true) faz com que as mais novas fiquem no topo
    return _tarefas.orderBy('dataCriacao', descending: true).snapshots();
  }
}