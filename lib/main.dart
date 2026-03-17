import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarefa_item.dart';
import 'tarefa_service.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const TodoListScreen(),
    );
  }
}

enum FiltroTarefa { todas, pendentes, concluidas }

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // Instância do nosso Serviço isolado
  final TarefaService _tarefaService = TarefaService();
  final TextEditingController _controladorTexto = TextEditingController();
  
  // O app sempre começa mostrando "Todas"
  FiltroTarefa _filtroAtual = FiltroTarefa.todas;

  void _abrirModalTarefa([DocumentSnapshot? documentoAtual]) {
    // 1. Prepara o modal: se tiver documento, preenche o campo. Se não, limpa.
    if (documentoAtual != null) {
      _controladorTexto.text = documentoAtual['nome'];
    } else {
      _controladorTexto.text = '';
    }

    // 2. Desenha o modal na tela
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  documentoAtual != null ? 'Editar Tarefa' : 'Nova Tarefa',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controladorTexto,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Nome da Tarefa',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                    // 3. A LÓGICA DE SALVAR FICA AQUI, APÓS O CLIQUE DO USUÁRIO
                    final String nomeTarefa = _controladorTexto.text;
                    
                    if (nomeTarefa.isNotEmpty) {
                      if (documentoAtual != null) {
                        // Chama o SERVIÇO para atualizar
                        await _tarefaService.atualizarNomeTarefa(documentoAtual.id, nomeTarefa);
                      } else {
                        // Chama o SERVIÇO para criar
                        await _tarefaService.adicionarTarefa(nomeTarefa);
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
    await _tarefaService.alternarStatusTarefa(id, statusAtual);
  }

  Future<bool> _deletarTarefa(String id) async {
    bool? confirmarExclusao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      // 1. Deleta do banco
      await _tarefaService.deletarTarefa(id);
      
      // 2. Verifica se a tela ainda existe antes de mostrar o aviso
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarefa apagada com sucesso!'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating, // Deixa a barrinha flutuando, mais moderno
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      
      return true; // Retorna true para confirmar que a tarefa foi apagada pro Dismissible
    }
    
    return false; // Retorna false se o usuário cancelou (o card volta pro lugar)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // BOTÕES DE FILTRO
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<FiltroTarefa>(
              segments: const [
                ButtonSegment(value: FiltroTarefa.todas, label: Text('Todas')),
                ButtonSegment(value: FiltroTarefa.pendentes, label: Text('Pendentes')),
                ButtonSegment(value: FiltroTarefa.concluidas, label: Text('Concluídas')),
              ],
              selected: {_filtroAtual},
              onSelectionChanged: (Set<FiltroTarefa> novaSelecao) {
                // O setState avisa o Flutter para desenhar a tela de novo!
                setState(() {
                  _filtroAtual = novaSelecao.first;
                });
              },
            ),
          ),

          // A LISTA DE TAREFAS (Ocupando o resto da tela com o Expanded)
          Expanded(
            child: StreamBuilder(
              stream: _tarefaService.getTarefasStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  // Pegamos todos os documentos do banco
                  var documentos = streamSnapshot.data!.docs;

                  // A LÓGICA DO FILTRO ACONTECE AQUI NO DART:
                  if (_filtroAtual == FiltroTarefa.pendentes) {
                    // Filtra mantendo apenas as que têm concluida == false
                    documentos = documentos.where((doc) => doc['concluida'] == false).toList();
                  } else if (_filtroAtual == FiltroTarefa.concluidas) {
                    // Filtra mantendo apenas as que têm concluida == true
                    documentos = documentos.where((doc) => doc['concluida'] == true).toList();
                  }
                  
                  if (documentos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('Nenhuma tarefa aqui.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: documentos.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot documento = documentos[index];
                      final idDaTarefa = documento.id;
                      final bool estaConcluida = documento['concluida'];

                      return TarefaItem(
                        nome: documento['nome'],
                        estaConcluida: estaConcluida,
                        onChanged: (bool? novoValor) {
                          _atualizarTarefa(idDaTarefa, estaConcluida);
                        },
                        onEdit: () => _abrirModalTarefa(documento),
                        onDelete: () async {
                          await _deletarTarefa(idDaTarefa);
                        },
                      );
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalTarefa(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
        elevation: 4,
      ),
    );
  }
}