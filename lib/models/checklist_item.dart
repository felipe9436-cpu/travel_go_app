
class ChecklistItem {
  final String id;
  final String viagemId;
  final String titulo;
  final String categoria;
  final bool concluido;
  final String? observacao;

  const ChecklistItem({
    required this.id,
    required this.viagemId,
    required this.titulo,
    required this.categoria,
    this.concluido = false,
    this.observacao,
  });

  // Verifica se o item ainda está pendente.
  bool get pendente {
    return !concluido;
  }

  // Verifica se existe uma observação preenchida.
  bool get possuiObservacao {
    return observacao != null &&
        observacao!.trim().isNotEmpty;
  }

  // Retorna uma nova versão do item,
  // mantendo os campos que não foram alterados.
  ChecklistItem copyWith({
    String? id,
    String? viagemId,
    String? titulo,
    String? categoria,
    bool? concluido,
    String? observacao,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      titulo: titulo ?? this.titulo,
      categoria: categoria ?? this.categoria,
      concluido: concluido ?? this.concluido,
      observacao: observacao ?? this.observacao,
    );
  }

  // Cria uma nova versão do item com
  // o status de conclusão invertido.
  ChecklistItem alternarConclusao() {
    return copyWith(
      concluido: !concluido,
    );
  }

  // Converte o item para um mapa,
  // mantendo os nomes dos campos do projeto.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagemId': viagemId,
      'titulo': titulo,
      'categoria': categoria,
      'concluido': concluido,
      'observacao': observacao,
    };
  }

  // Cria um item usando os dados
  // recebidos do banco de dados.
  factory ChecklistItem.fromMap(
      Map<String, dynamic> map,
      ) {
    return ChecklistItem(
      id: map['id'].toString(),
      viagemId: map['viagemId'].toString(),
      titulo: map['titulo'] as String,
      categoria: map['categoria'] as String,
      concluido: map['concluido'] as bool? ?? false,
      observacao: map['observacao'] as String?,
    );
  }
}
