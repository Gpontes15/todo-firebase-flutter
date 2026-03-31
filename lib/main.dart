import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORT NECESSÁRIO PARA VERIFICAR O LOGIN
import 'tarefa_item.dart';
import 'tarefa_service.dart';
import 'notificacao_service.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificacaoService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'To-Do Premium',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, 
          
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1), 
              primary: const Color(0xFF6366F1),
              surface: const Color(0xFFF8FAFC), 
              onSurface: Colors.black87,
              surfaceContainerHighest: Colors.grey.shade100,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            useMaterial3: true,
            fontFamily: 'Roboto', 
          ),

          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              brightness: Brightness.dark,
              seedColor: const Color(0xFF6366F1), 
              primary: const Color(0xFF818CF8), 
              surface: const Color(0xFF1E1E2C), 
              onSurface: Colors.white,
              surfaceContainerHighest: const Color(0xFF2A2A3C),
            ),
            scaffoldBackgroundColor: const Color(0xFF12121A), 
            useMaterial3: true,
            fontFamily: 'Roboto', 
          ),
          
          // --- O PORTÃO DE ENTRADA DO APLICATIVO ---
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              // Se tiver dados (usuário logado), vai para a tela de tarefas
              if (snapshot.hasData) {
                return const TodoListScreen();
              }
              // Se não, vai para o login
              return const LoginScreen();
            },
          ),
        );
      }
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
    String recorrencia = 'nenhuma'; 

    if (documentoAtual != null) {
      _controladorTexto.text = documentoAtual['nome'];
      if (documentoAtual.data().toString().contains('dataVencimento') && documentoAtual['dataVencimento'] != null) {
        dataSelecionada = (documentoAtual['dataVencimento'] as Timestamp).toDate();
        horaSelecionada = TimeOfDay(hour: dataSelecionada!.hour, minute: dataSelecionada!.minute);
      }
      if (documentoAtual.data().toString().contains('diaTodo')) {
        diaTodo = documentoAtual['diaTodo'] ?? false;
      }
      if (documentoAtual.data().toString().contains('recorrencia')) {
        recorrencia = documentoAtual['recorrencia'] ?? 'nenhuma';
      }
    } else {
      _controladorTexto.text = '';
    }

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface, 
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.0)), 
        ),
        builder: (BuildContext ctx) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 12, 
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
                child: SingleChildScrollView( 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Text(
                        documentoAtual != null ? 'Editar Tarefa' : 'Nova Tarefa',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        textAlign: TextAlign.left, 
                      ),
                      const SizedBox(height: 24),
                      
                      TextField(
                        controller: _controladorTexto,
                        autofocus: true,
                        textCapitalization: TextCapitalization.sentences, 
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'O que você precisa fazer?',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest, 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none, 
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), 
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                  
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Dia todo', style: TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: const Text('Avisa no dia anterior às 09:00', style: TextStyle(fontSize: 12)),
                              value: diaTodo,
                              activeColor: Theme.of(context).colorScheme.primary,
                              onChanged: (bool valor) {
                                setModalState(() {
                                  diaTodo = valor;
                                  if (diaTodo) horaSelecionada = null; 
                                });
                              },
                            ),
                            Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(dataSelecionada == null ? 'Escolher Data' : 'Data: ${dataSelecionada!.day}/${dataSelecionada!.month}/${dataSelecionada!.year}'),
                              trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              onTap: () async {
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
                            if (!diaTodo) ...[
                              Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                                ),
                                title: Text(horaSelecionada == null ? 'Escolher Hora' : 'Hora: ${horaSelecionada!.format(context)}'),
                                trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                onTap: () async {
                                  final TimeOfDay? horaEscolhida = await showTimePicker(
                                    context: context,
                                    initialTime: horaSelecionada ?? TimeOfDay.now(),
                                  );
                                  if (horaEscolhida != null) {
                                    setModalState(() {
                                      horaSelecionada = horaEscolhida;
                                      dataSelecionada ??= DateTime.now();
                                      dataSelecionada = DateTime(
                                        dataSelecionada!.year, dataSelecionada!.month, dataSelecionada!.day,
                                        horaEscolhida.hour, horaEscolhida.minute
                                      );
                                    });
                                  }
                                },
                              ),
                            ],
                            
                            Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: DropdownButtonFormField<String>(
                                value: recorrencia,
                                dropdownColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                icon: Icon(Icons.expand_more, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.repeat, color: Theme.of(context).colorScheme.primary),
                                  border: InputBorder.none, 
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'nenhuma', child: Text('Não repetir')),
                                  DropdownMenuItem(value: 'diária', child: Text('Todos os dias')),
                                  DropdownMenuItem(value: 'semanal', child: Text('Toda a semana')),
                                  DropdownMenuItem(value: 'mensal', child: Text('Todo o mês')),
                                ],
                                onChanged: (String? novaRecorrencia) {
                                  setModalState(() {
                                    recorrencia = novaRecorrencia!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                        
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary, 
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          documentoAtual != null ? 'Atualizar Tarefa' : 'Adicionar Tarefa',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final String nomeTarefa = _controladorTexto.text.trim(); 
                          
                          if (nomeTarefa.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Por favor, dê um nome para a tarefa.'),
                                  ],
                                ),
                                backgroundColor: Colors.orange.shade800,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                              ),
                            );
                            return; 
                          }
                  
                          if (documentoAtual != null) {
                            await _tarefaService.atualizarNomeTarefa(documentoAtual.id, nomeTarefa);
                          } else {
                            final idGerado = await _tarefaService.adicionarTarefa(
                              nomeTarefa, 
                              dataVencimento: dataSelecionada,
                              diaTodo: diaTodo,
                              recorrencia: recorrencia 
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
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Aviso: A tarefa foi salva, mas o horário escolhido já passou. O alarme não tocará.'),
                                      backgroundColor: Colors.orange.shade800,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            }
                          }
                          _controladorTexto.text = '';
                          
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Text(documentoAtual != null ? 'Tarefa atualizada!' : 'Tarefa criada com sucesso!'),
                                  ],
                                ),
                                backgroundColor: Colors.green.shade600, 
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      )
                    ],
                  ),
                ),
              );
            }
          );
        });
  }

  Future<void> _atualizarTarefa(DocumentSnapshot documento) async {
    final String id = documento.id;
    final bool statusAtual = documento['concluida'];
    bool vaiConcluir = !statusAtual;
    
    await _tarefaService.alternarStatusTarefa(id, statusAtual);
    
    if (vaiConcluir) {
      await NotificacaoService().cancelarNotificacao(id.hashCode.abs()); 

      String recorrencia = 'nenhuma';
      if (documento.data().toString().contains('recorrencia')) {
        recorrencia = documento['recorrencia'] ?? 'nenhuma';
      }

      if (recorrencia != 'nenhuma' && documento.data().toString().contains('dataVencimento') && documento['dataVencimento'] != null) {
        DateTime dataAntiga = (documento['dataVencimento'] as Timestamp).toDate();
        DateTime novaData = dataAntiga;
        
        if (recorrencia == 'diária') {
          novaData = dataAntiga.add(const Duration(days: 1));
        } else if (recorrencia == 'semanal') {
          novaData = dataAntiga.add(const Duration(days: 7));
        } else if (recorrencia == 'mensal') {
          novaData = DateTime(dataAntiga.year, dataAntiga.month + 1, dataAntiga.day, dataAntiga.hour, dataAntiga.minute);
        }

        bool diaTodo = false;
        if (documento.data().toString().contains('diaTodo')) diaTodo = documento['diaTodo'] ?? false;

        final novoId = await _tarefaService.adicionarTarefa(
          documento['nome'],
          dataVencimento: novaData,
          diaTodo: diaTodo,
          recorrencia: recorrencia
        );

        if (novoId != null) {
          DateTime dataAlarme = novaData;
          if (diaTodo) {
            dataAlarme = DateTime(novaData.year, novaData.month, novaData.day - 1, 9, 0); 
          }
          
          if (dataAlarme.isAfter(DateTime.now())) {
            await NotificacaoService().agendarNotificacao(
              id: novoId.hashCode.abs(),
              titulo: diaTodo ? 'Amanhã: ${documento['nome']}' : 'Lembrete de Tarefa',
              corpo: diaTodo ? 'Você tem uma tarefa pendente para amanhã!' : 'Sua tarefa está próxima do prazo.',
              dataAgendada: dataAlarme,
            );
          }
        }
      }
    }
  }

  Future<bool> _deletarTarefa(String id) async {
    bool? confirmarExclusao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Apagar tarefa?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text('Esta ação não pode ser desfeita.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
            margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20), 
          ),
        );
      }
      return true;
    }
    return false;
  }

  // --- Função para deslogar do app ---
  Future<void> _fazerLogout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, Gabriel! 👋',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aqui estão as suas tarefas.',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Theme.of(context).brightness == Brightness.dark 
                                ? Icons.light_mode 
                                : Icons.dark_mode_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            if (MyApp.themeNotifier.value == ThemeMode.system) {
                              final isSystemDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
                              MyApp.themeNotifier.value = isSystemDark ? ThemeMode.light : ThemeMode.dark;
                            } else {
                              MyApp.themeNotifier.value = MyApp.themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão de Logout adicionado ao lado do botão de tema
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.logout, color: Colors.red.shade400),
                          onPressed: _fazerLogout,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<FiltroTarefa>(
                  showSelectedIcon: false, 
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                    selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
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

            Expanded(
              child: StreamBuilder(
                stream: _tarefaService.getTarefasStream(),
                builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
                  if (streamSnapshot.connectionState == ConnectionState.waiting) {
                     return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
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
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_circle_outline, size: 80, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 24),
                            Text('Tudo limpo por aqui!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Adicione novas tarefas para começar.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
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

                        String recorrenciaExtraida = 'nenhuma';
                        if (documento.data().toString().contains('recorrencia')) {
                          recorrenciaExtraida = documento['recorrencia'] ?? 'nenhuma';
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
                              borderRadius: BorderRadius.circular(16), 
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (direction) async {
                            return await _deletarTarefa(idDaTarefa);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0), 
                            child: TarefaItem(
                              nome: documento['nome'],
                              estaConcluida: estaConcluida,
                              dataVencimento: dataExtraida,
                              recorrencia: recorrenciaExtraida, 
                              onChanged: (bool? novoValor) {
                                _atualizarTarefa(documento); 
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), 
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}