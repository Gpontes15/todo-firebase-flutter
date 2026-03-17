import 'package:flutter/material.dart';

class TarefaItem extends StatelessWidget {
 
  final String nome;
  final bool estaConcluida;
  
  final Function(bool?) onChanged; 
  
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          nome,
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
            onChanged: onChanged,
          ),
        ),
        trailing: SizedBox(
          width: 96,
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.indigo.shade400),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}