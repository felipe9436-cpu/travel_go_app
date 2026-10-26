
class Roteiro {
  final String id;
  final String viagemId;
  final DateTime data;
  final String titulo;
  final String? descricao;
  final String? horario;
  final String categoria;
  final String? local;
  final bool concluido;

  const Roteiro({
    required this.id,
    required this.viagemId,
    required this.data,
    required this.titulo,
    this.descricao,
    this.horario,
    required this.categoria,
    this.local,
    this.concluido = false,
  });

  // Verifica se a atividade possui horário.
  bool get possuiHorario {
    return horario != null && horario!.trim().isNotEmpty;
  }

  // Verifica se a atividade possui um local.
  bool get possuiLocal {
    return local != null && local!.trim().isNotEmpty;
  }

  // Formata a data para exibição na interface.
  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // Retorna uma nova atividade com os campos alterados.
  Roteiro copyWith({
    String? id,
    String? viagemId,
    DateTime? data,
    String? titulo,
    String? descricao,
    String? horario,
    String? categoria,
    String? local,
    bool? concluido,
  }) {
    return Roteiro(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      data: data ?? this.data,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      horario: horario ?? this.horario,
      categoria: categoria ?? this.categoria,
      local: local ?? this.local,
      concluido: concluido ?? this.concluido,
    );
  }

  // Converte o roteiro para um mapa,
  // mantendo os nomes dos campos do projeto.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagemId': viagemId,
      'data': data.toIso8601String(),
      'titulo': titulo,
      'descricao': descricao,
      'horario': horario,
      'categoria': categoria,
      'local': local,
      'concluido': concluido,
    };
  }

  // Cria uma atividade a partir dos dados
  // recebidos do banco de dados.
  factory Roteiro.fromMap(Map<String, dynamic> map) {
    return Roteiro(
      id: map['id'].toString(),
      viagemId: map['viagemId'].toString(),
      data: DateTime.parse(
        map['data'] as String,
      ),
      titulo: map['titulo'] as String,
      descricao: map['descricao'] as String?,
      horario: map['horario'] as String?,
      categoria: map['categoria'] as String,
      local: map['local'] as String?,
      concluido: map['concluido'] as bool? ?? false,
    );
  }
}
