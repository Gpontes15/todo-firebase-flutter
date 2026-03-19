import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarefa_item.dart';
import 'tarefa_service.dart';
import 'notificacao_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o motor de notificações
  await NotificacaoService().init();

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
                      subtitle: const Text('Avisa no dia anterior às 09:00'),
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

                    // --- BOTÃO DO RELÓGIO ---
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
                          } else {
                            
                            // 1. Salva a tarefa e pega o ID gerado pelo Firebase
                            final idGerado = await _tarefaService.adicionarTarefa(
                              nomeTarefa, 
                              dataVencimento: dataSelecionada,
                              diaTodo: diaTodo
                            );

                            // 2. LÓGICA DO ALARME
                            // Se o usuário escolheu uma data e o Firebase devolveu o ID com sucesso:
                            if (dataSelecionada != null && idGerado != null) {
                              DateTime dataAlarme = dataSelecionada!;

                              if (diaTodo) {
                                // Se for o dia todo, volta 1 dia e crava às 09:00 da manhã
                                dataAlarme = DateTime(
                                  dataSelecionada!.year, 
                                  dataSelecionada!.month, 
                                  dataSelecionada!.day - 1, 
                                  9, 0
                                );
                              }

                              // O Dart só permite agendar alarmes para o futuro
                              if (dataAlarme.isAfter(DateTime.now())) {
                                await NotificacaoService().agendarNotificacao(
                                  id: idGerado.hashCode,
                                  titulo: diaTodo ? 'Amanhã: $nomeTarefa' : 'Lembrete de Tarefa',
                                  corpo: diaTodo ? 'Você tem uma tarefa pendente para amanhã!' : 'Sua tarefa está próxima do prazo.',
                                  dataAgendada: dataAlarme,
                                );
                              }
                            }
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
    // Se estava pendente (false), vai virar concluída (true)
    bool vaiConcluir = !statusAtual;
    
    await _tarefaService.alternarStatusTarefa(id, statusAtual);

    // Se o usuário marcou como concluída, nós desarmamos a bomba!
    if (vaiConcluir) {
      await NotificacaoService().cancelarNotificacao(id.hashCode);
    }
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
      // 1. Deleta do banco de dados
      await _tarefaService.deletarTarefa(id);
      
      // 2. Apaga o alarme do celular para não tocar à toa
      await NotificacaoService().cancelarNotificacao(id.hashCode);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarefa apagada com sucesso!'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
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
                setState(() {
                  _filtroAtual = novaSelecao.first;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _tarefaService.getTarefasStream(),
              builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                if (streamSnapshot.hasData) {
                  var documentos = streamSnapshot.data!.docs;

                  if (_filtroAtual == FiltroTarefa.pendentes) {
                    documentos = documentos.where((doc) => doc['concluida'] == false).toList();
                  } else if (_filtroAtual == FiltroTarefa.concluidas) {
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
                      
                      DateTime? dataExtraida;
                      if (documento.data().toString().contains('dataVencimento') && documento['dataVencimento'] != null) {
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
                          dataVencimento: dataExtraida,
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