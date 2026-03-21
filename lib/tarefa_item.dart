import 'package:flutter/material.dart';

class TarefaItem extends StatelessWidget {
  final String nome;
  final bool estaConcluida;
  final DateTime? dataVencimento;
  final String recorrencia;
  final Function(bool?) onChanged;
  final Function() onEdit;
  final Function() onDelete;

  const TarefaItem({
    super.key,
    required this.nome,
    required this.estaConcluida,
    required this.dataVencimento,
    required this.recorrencia,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Pegamos as cores dinâmicas do tema atual (Claro ou Escuro)
    final corPrimaria = Theme.of(context).colorScheme.primary;
    final corFundo = Theme.of(context).colorScheme.surface;
    final corTextoPrincipal = Theme.of(context).colorScheme.onSurface;
    final corTextoSecundario = Theme.of(context).colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: corFundo, // Fundo inteligente (Branco no claro, Cinza escuro no dark)
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null, // Borda sutil no dark mode
        boxShadow: isDark ? [] : [
          // Sombra só aparece no tema claro, no escuro a gente usa borda fina
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
              activeColor: corPrimaria,
              checkColor: corFundo, // O "V" do check pega a cor do fundo
              side: BorderSide(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)), 
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nome,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    // Cor do texto inteligente
                    color: estaConcluida ? corTextoSecundario.withOpacity(0.5) : corTextoPrincipal,
                    decoration: estaConcluida ? TextDecoration.lineThrough : TextDecoration.none, 
                  ),
                ),
                if (dataVencimento != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: corTextoSecundario),
                      const SizedBox(width: 4),
                      Text(
                        '${dataVencimento!.day.toString().padLeft(2, '0')}/${dataVencimento!.month.toString().padLeft(2, '0')}/${dataVencimento!.year}',
                        style: TextStyle(fontSize: 12, color: corTextoSecundario, fontWeight: FontWeight.w400),
                      ),
                      if (recorrencia != 'nenhuma') ...[
                        const SizedBox(width: 8),
                        Icon(Icons.repeat, size: 14, color: corPrimaria),
                        const SizedBox(width: 4),
                        Text(
                          recorrencia.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: corPrimaria, fontWeight: FontWeight.bold),
                        ),
                      ]
                    ],
                  ),
                ]
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: corTextoSecundario, size: 22),
            onPressed: onEdit,
            splashRadius: 22,
          ),
        ],
      ),
    );
  }
}