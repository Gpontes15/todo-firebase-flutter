import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tarefa_item.dart';
import 'tarefa_service.dart';
import 'notificacao_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificacaoService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do Premium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Uma paleta de cores mais moderna e vibrante
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Índigo moderno
          primary: const Color(0xFF6366F1),
          surface: const Color(0xFFF8FAFC), // Fundo ultra claro e limpo
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
        // Deixando a fonte padrão com um aspecto mais arredondado e limpo
        fontFamily: 'Roboto', 
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
        backgroundColor: Colors.white, // Fundo branco puro para contrastar com o app
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)), // Bordas mais arredondadas
        ),
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 12, // Reduzido para dar espaço ao "puxador"
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- DRAG HANDLE (O "puxador" moderno no topo do modal) ---
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      documentoAtual != null ? 'Editar Tarefa' : 'Nova Tarefa',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.left, // Alinhado à esquerda para um ar mais limpo
                    ),
                    const SizedBox(height: 24),
                    
                    // --- TEXTFIELD MODERNO ---
                    TextField(
                      controller: _controladorTexto,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'O que você precisa fazer?',
                        labelStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.grey.shade100, // Fundo cinza suave
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none, // Sem borda preta
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2), // Borda fina ao clicar
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- OPÇÕES EM CARDS MODERNOS ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Dia todo', style: TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Text('Avisa no dia anterior às 09:00', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            value: diaTodo,
                            activeColor: const Color(0xFF6366F1),
                            onChanged: (bool valor) {
                              setModalState(() {
                                diaTodo = valor;
                                if (diaTodo) horaSelecionada = null; 
                              });
                            },
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.calendar_month, color: Color(0xFF6366F1)),
                            ),
                            title: Text(dataSelecionada == null ? 'Escolher Data' : 'Data: ${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}'),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () async {
                              final DateTime? dataEscolhida = await showDatePicker(
                                context: context,
                                initialDate: dataSelecionada ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2030),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
                                    ),
                                    child: child!,
                                  );
                                },
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
                          if (!diaTodo) ...[
                            const Divider(height: 1, indent: 16, endIndent: 16),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                              ),
                              title: Text(horaSelecionada == null ? 'Escolher Hora' : 'Hora: ${horaSelecionada!.format(context)}'),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () async {
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
                        ],
                      ),
                    ),
                      
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        documentoAtual != null ? 'Atualizar Tarefa' : 'Adicionar Tarefa',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        final String nomeTarefa = _controladorTexto.text;
                        if (nomeTarefa.isNotEmpty) {
                          if (documentoAtual != null) {
                            await _tarefaService.atualizarNomeTarefa(documentoAtual.id, nomeTarefa);
                          } else {
                            final idGerado = await _tarefaService.adicionarTarefa(
                              nomeTarefa, 
                              dataVencimento: dataSelecionada,
                              diaTodo: diaTodo
                            );

                            if (dataSelecionada != null && idGerado != null) {
                              DateTime dataAlarme = dataSelecionada!;
                              if (diaTodo) {
                                dataAlarme = DateTime(
                                  dataSelecionada!.year, 
                                  dataSelecionada!.month, 
                                  dataSelecionada!.day - 1, 
                                  9, 0
                                );
                              }

                              if (dataAlarme.isAfter(DateTime.now())) {
                                await NotificacaoService().agendarNotificacao(
                                  id: idGerado.hashCode.abs(), 
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
    bool vaiConcluir = !statusAtual;
    await _tarefaService.alternarStatusTarefa(id, statusAtual);
    if (vaiConcluir) {
      await NotificacaoService().cancelarNotificacao(id.hashCode.abs()); 
    }
  }

  Future<bool> _deletarTarefa(String id) async {
    bool? confirmarExclusao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Apagar tarefa?'),
          content: const Text('Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Apagar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmarExclusao == true) {
      await _tarefaService.deletarTarefa(id);
      await NotificacaoService().cancelarNotificacao(id.hashCode.abs()); 
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tarefa apagada!'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20), // Flutua de forma mais elegante
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
      // --- NOVO CABEÇALHO MODERNO (Substitui a velha AppBar) ---
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Olá, Gabriel! 👋',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aqui estão as suas tarefas.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            
            // --- FILTROS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<FiltroTarefa>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: const Color(0xFF6366F1),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
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
            ),
            const SizedBox(height: 16),

            // --- LISTA DE TAREFAS ---
            Expanded(
              child: StreamBuilder(
                stream: _tarefaService.getTarefasStream(),
                builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                  if (streamSnapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                  }

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
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF6366F1)),
                            ),
                            const SizedBox(height: 24),
                            Text('Tudo limpo por aqui!', style: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Adicione novas tarefas para começar.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16), // Bordas casando com o item
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (direction) async {
                            return await _deletarTarefa(idDaTarefa);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0), // Espaçamento entre as tarefas
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
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('Ocorreu um erro ao carregar as tarefas.'));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirModalTarefa(),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Botão arredondado moderno
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}