import 'package:flutter/material.dart';

// Como o nosso card não altera o próprio estado (ele apenas repassa as ações 
// para o main.dart através das funções), ele é um StatelessWidget.
class TarefaItem extends StatelessWidget {
  // 1. Definimos as "props" (variáveis) que a classe vai receber
  final String nome;
  final bool estaConcluida;
  
  // No Flutter, funções também são passadas como variáveis!
  // Function(bool?) é uma função que espera receber um true ou false.
  final Function(bool?) onChanged; 
  // VoidCallback é o mesmo que uma "Function()", ou seja, não recebe nem retorna nada.
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // 2. O Construtor: Aqui exigimos (required) que quem for usar este 
  // componente passe todas as informações acima.
  const TarefaItem({
    super.key,
    required this.nome,
    required this.estaConcluida,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 3. A Interface: Colei exatamente o mesmo Card que estava no main.dart, 
    // mas agora ele usa as variáveis genéricas da nossa classe!
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          nome, // Usando a variável da classe
          style: TextStyle(
            fontSize: 16,
            fontWeight: estaConcluida ? FontWeight.normal : FontWeight.w500,
            color: estaConcluida ? Colors.grey : Colors.black87,
            decoration: estaConcluida ? TextDecoration.lineThrough : null,
          ),
        ),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            value: estaConcluida,
            onChanged: onChanged, // Repassando a ação do clique para cima
          ),
        ),
        trailing: SizedBox(
          width: 96,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.indigo.shade400),
                onPressed: onEdit, // Repassando o clique no lápis
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: onDelete, // Repassando o clique na lixeira
              ),
            ],
          ),
        ),
      ),
    );
  }
}