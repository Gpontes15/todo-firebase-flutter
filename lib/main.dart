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
  final TarefaService _tarefaService = TarefaService();
  final TextEditingController _controladorTexto = TextEditingController();
  
  FiltroTarefa _filtroAtual = FiltroTarefa.todas;

  void _abrirModalTarefa([DocumentSnapshot? documentoAtual]) {
    DateTime? dataSelecionada;
    TimeOfDay? horaSelecionada; 
    bool diaTodo = false;       

    if (documentoAtual != null) {
      _controladorTexto.text = documentoAtual['nome'];
      if (documentoAtual.data().toString().contains('dataVencimento') && documentoAtual['dataVencimento'] != null) {
        dataSelecionada = (documentoAtual['dataVencimento'] as Timestamp).toDate();
        horaSelecionada = TimeOfDay(hour: dataSelecionada!.hour, minute: dataSelecionada!.minute);
      }
      if (documentoAtual.data().toString().contains('diaTodo')) {
        diaTodo = documentoAtual['diaTodo'] ?? false;
      }
    } else {
      _controladorTexto.text = '';
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- O INTERRUPTOR DE "DIA TODO" ---
                    SwitchListTile(
                      title: const Text('Dia todo'),
                      subtitle: const Text('Avisa no dia anterior'),
                      value: diaTodo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (bool valor) {
                        setModalState(() {
                          diaTodo = valor;
                          if (diaTodo) horaSelecionada = null; // Limpa a hora se for o dia todo
                        });
                      },
                    ),

                    // --- BOTÃO DO CALENDÁRIO ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dataSelecionada == null 
                            ? 'Nenhuma data' 
                            : 'Data: ${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}',
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: const Text('Escolher Data'),
                          onPressed: () async {
                            final DateTime? dataEscolhida = await showDatePicker(
                              context: context,
                              initialDate: dataSelecionada ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                            );
                            if (dataEscolhida != null) {
                              setModalState(() {
                                // Preserva a hora se já tinha sido escolhida
                                if (horaSelecionada != null) {
                                  dataSelecionada = DateTime(
                                    dataEscolhida.year, dataEscolhida.month, dataEscolhida.day,
                                    horaSelecionada!.hour, horaSelecionada!.minute
                                  );
                                } else {
                                  dataSelecionada = dataEscolhida;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    // --- BOTÃO DO RELÓGIO (SÓ APARECE SE NÃO FOR "DIA TODO") ---
                    if (!diaTodo)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            horaSelecionada == null 
                              ? 'Nenhuma hora' 
                              : 'Hora: ${horaSelecionada!.format(context)}',
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: const Text('Escolher Hora'),
                            onPressed: () async {
                              final TimeOfDay? horaEscolhida = await showTimePicker(
                                context: context,
                                initialTime: horaSelecionada ?? TimeOfDay.now(),
                              );
                              if (horaEscolhida != null) {
                                setModalState(() {
                                  horaSelecionada = horaEscolhida;
                                  // Se já tinha data, junta a data com a nova hora
                                  if (dataSelecionada != null) {
                                    dataSelecionada = DateTime(
                                      dataSelecionada!.year, dataSelecionada!.month, dataSelecionada!.day,
                                      horaEscolhida.hour, horaEscolhida.minute
                                    );
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        documentoAtual != null ? 'Atualizar' : 'Adicionar',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        final String nomeTarefa = _controladorTexto.text;
                        if (nomeTarefa.isNotEmpty) {
                          if (documentoAtual != null) {
                            await _tarefaService.atualizarNomeTarefa(documentoAtual.id, nomeTarefa);
                            // Desafio para depois: atualizar data/hora na edição
                          } else {
                            await _tarefaService.adicionarTarefa(
                              nomeTarefa, 
                              dataVencimento: dataSelecionada,
                              diaTodo: diaTodo // Passamos o novo booleano para o Firebase!
                            );
                          }
                          _controladorTexto.text = '';
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                    )
                  ],
                ),
              );
            }
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
                      
                      // Lógica para pegar a data (se ela existir no documento)
                      DateTime? dataExtraida;
                      // Checamos se o campo existe para não dar erro nas tarefas antigas
                      if (documento.data().toString().contains('dataVencimento') && documento['dataVencimento'] != null) {
                        // O Firebase salva como Timestamp, então convertemos para o DateTime do Dart
                        dataExtraida = (documento['dataVencimento'] as Timestamp).toDate();
                      }

                      return Dismissible(
                        key: Key(idDaTarefa),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                        ),
                        confirmDismiss: (direction) async {
                          return await _deletarTarefa(idDaTarefa);
                        },
                        child: TarefaItem(
                          nome: documento['nome'],
                          estaConcluida: estaConcluida,
                          dataVencimento: dataExtraida, // Passamos a data extraída para o componente!
                          onChanged: (bool? novoValor) {
                            _atualizarTarefa(idDaTarefa, estaConcluida);
                          },
                          onEdit: () => _abrirModalTarefa(documento),
                          onDelete: () => _deletarTarefa(idDaTarefa),
                        ),
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