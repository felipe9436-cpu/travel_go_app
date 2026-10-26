
class Avaliacao {
  final String id;
  final String viagemId;
  final String nome;
  final String categoria;
  final double nota;
  final String? comentario;
  final DateTime data;

  const Avaliacao({
    required this.id,
    required this.viagemId,
    required this.nome,
    required this.categoria,
    required this.nota,
    this.comentario,
    required this.data,
  });

  // Verifica se existe um comentário preenchido.
  bool get possuiComentario {
    return comentario != null &&
        comentario!.trim().isNotEmpty;
  }

  // Retorna a data no formato brasileiro.
  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // Retorna a nota com uma casa decimal.
  String get notaFormatada {
    return nota.toStringAsFixed(1).replaceAll('.', ',');
  }

  // Verifica se a nota está entre 1 e 5.
  bool get notaValida {
    return nota >= 1 && nota <= 5;
  }

  // Cria uma nova avaliação com os campos alterados.
  Avaliacao copyWith({
    String? id,
    String? viagemId,
    String? nome,
    String? categoria,
    double? nota,
    String? comentario,
    DateTime? data,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      nota: nota ?? this.nota,
      comentario: comentario ?? this.comentario,
      data: data ?? this.data,
    );
  }

  // Converte a avaliação em um mapa
  // para armazenamento no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagemId': viagemId,
      'nome': nome,
      'categoria': categoria,
      'nota': nota,
      'comentario': comentario,
      'data': data.toIso8601String(),
    };
  }

  // Cria uma avaliação usando os dados
  // recebidos do Supabase.
  factory Avaliacao.fromMap(
      Map<String, dynamic> map,
      ) {
    return Avaliacao(
      id: map['id'].toString(),
      viagemId: map['viagemId'].toString(),
      nome: map['nome'] as String,
      categoria: map['categoria'] as String,
      nota: (map['nota'] as num).toDouble(),
      comentario: map['comentario'] as String?,
      data: DateTime.parse(
        map['data'] as String,
      ),
    );
  }
}
