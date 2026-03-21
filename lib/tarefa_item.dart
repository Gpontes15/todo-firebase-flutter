import 'package:flutter/material.dart';

class TarefaItem extends StatelessWidget {
  final String nome;
  final bool estaConcluida;
  final DateTime? dataVencimento;
  final Function(bool?) onChanged;
  final Function() onEdit;
  final Function() onDelete;

  const TarefaItem({
    super.key,
    required this.nome,
    required this.estaConcluida,
    required this.dataVencimento,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6366F1);
    const Color textCompletedColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: estaConcluida,
              onChanged: onChanged,
              activeColor: primaryColor,
              checkColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), 
            ),
          ),
          const SizedBox(width: 12), // Espaço entre checkbox e texto

          // --- ÁREA DE TEXTO E DATA ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço vertical
              children: [
                // Nome da Tarefa
                Text(
                  nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500, // Nem muito fino, nem muito grosso
                    color: estaConcluida ? textCompletedColor : Colors.black87,
                    // Riscado se concluída
                    decoration: estaConcluida ? TextDecoration.lineThrough : TextDecoration.none, 
                  ),
                ),
                
                // Mostra a data se ela existir
                if (dataVencimento != null) ...[
                  const SizedBox(height: 6), // Espaço entre nome e data
                  // Organização moderna da data
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        // Formatação manual simples DD/MM/AAAA (padrão Brasil)
                        '${dataVencimento!.day.toString().padLeft(2, '0')}/${dataVencimento!.month.toString().padLeft(2, '0')}/${dataVencimento!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),

          // --- BOTÕES DE AÇÃO (Ícones mais finos e sutis) ---
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.grey.shade500, size: 22),
            onPressed: onEdit,
            splashRadius: 22, // Área de clique redonda menor
          ),
          // Nota: O botão de deletar foi removido daqui porque nós usamos 
          // o Dismissible (arrastar para o lado) no main.dart para apagar,
          // o que deixa a interface do card mais limpa.
        ],
      ),
    );
  }
}