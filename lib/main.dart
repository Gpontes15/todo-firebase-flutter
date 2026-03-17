import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarefa_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Firebase',
      debugShowCheckedModeBanner: false,
      // 1. ESTILIZAÇÃO GLOBAL: Aqui definimos a "cara" do app
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[100], // Fundo levemente cinza
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white, // Cor do texto e ícones na AppBar
        ),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final CollectionReference _tarefas = FirebaseFirestore.instance.collection('tarefas');
  final TextEditingController _controladorTexto = TextEditingController();

  void _abrirModalTarefa([DocumentSnapshot? documentoAtual]) {
    if (documentoAtual != null) {
      _controladorTexto.text = documentoAtual['nome'];
    } else {
      _controladorTexto.text = '';
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        // 2. ESTILIZAÇÃO DO MODAL: Bordas arredondadas no topo
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Estica os botões
              children: [
                Text(
                  documentoAtual != null ? 'Editar Tarefa' : 'Nova Tarefa',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controladorTexto,
                  autofocus: true, // Já abre o teclado direto
                  decoration: InputDecoration(
                    labelText: 'Nome da Tarefa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Campo de texto moderno
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    documentoAtual != null ? 'Atualizar' : 'Adicionar',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () async {
                    final String nomeTarefa = _controladorTexto.text;
                    if (nomeTarefa.isNotEmpty) {
                      if (documentoAtual != null) {
                        await _tarefas.doc(documentoAtual.id).update({"nome": nomeTarefa});
                      } else {
                        await _tarefas.add({"nome": nomeTarefa, "concluida": false});
                      }
                      _controladorTexto.text = '';
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  Future<void> _atualizarTarefa(String id, bool statusAtual) async {
    await _tarefas.doc(id).update({"concluida": !statusAtual});
  }

  Future<void> _deletarTarefa(String id) async {
    bool? confirmarExclusao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Alerta arredondado
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja apagar esta tarefa? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apagar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmarExclusao == true) {
      await _tarefas.doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder(
        stream: _tarefas.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            final documentos = streamSnapshot.data!.docs;
            
            if (documentos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Nenhuma tarefa ainda.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12), // Espaço nas bordas da lista
              itemCount: documentos.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documento = documentos[index];
                final idDaTarefa = documento.id;
                final bool estaConcluida = documento['concluida'];

              // Ao invés de um Card gigante, chamamos nosso componente
                // passando as "props" que ele exige no construtor.
                return TarefaItem(
                  nome: documento['nome'],
                  estaConcluida: estaConcluida,
                  // Aqui dizemos o que as funções do componente devem fazer no main.dart
                  onChanged: (bool? novoValor) {
                    _atualizarTarefa(idDaTarefa, estaConcluida);
                  },
                  onEdit: () => _abrirModalTarefa(documento),
                  onDelete: () => _deletarTarefa(idDaTarefa),
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalTarefa(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'), // FAB extendido fica bem bonito!
        elevation: 4,
      ),
    );
  }
}