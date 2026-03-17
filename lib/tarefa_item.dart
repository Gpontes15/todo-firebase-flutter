import 'package:flutter/material.dart';

class TarefaItem extends StatelessWidget {
  final String nome;
  final bool estaConcluida;
  // Nova variável: pode ser nula porque nem toda tarefa tem data
  final DateTime? dataVencimento; 
  
  final Function(bool?) onChanged; 
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TarefaItem({
    super.key,
    required this.nome,
    required this.estaConcluida,
    this.dataVencimento, // Adicionado aqui (sem o required, pois é opcional)
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
        
        // --- A MÁGICA ACONTECE AQUI NO SUBTITLE ---
        // Só mostramos o subtítulo se a data não for nula
        subtitle: dataVencimento != null 
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Icon(Icons.event, size: 14, color: estaConcluida ? Colors.grey : Colors.indigo.shade300),
                  const SizedBox(width: 4),
                  Text(
                    '${dataVencimento!.day}/${dataVencimento!.month}/${dataVencimento!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: estaConcluida ? Colors.grey : Colors.indigo.shade400,
                      decoration: estaConcluida ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            )
          : null, // Se for nula, o Flutter ignora e não desenha nada
          
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