
class Gasto {
  final String id;
  final String viagemId;
  final String descricao;
  final double valor;
  final String categoria;
  final DateTime data;
  final String? observacao;

  const Gasto({
    required this.id,
    required this.viagemId,
    required this.descricao,
    required this.valor,
    required this.categoria,
    required this.data,
    this.observacao,
  });

  // Retorna a data formatada no padrão brasileiro.
  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  // Retorna o valor com duas casas decimais.
  String get valorFormatado {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // Verifica se o gasto possui uma observação.
  bool get possuiObservacao {
    return observacao != null &&
        observacao!.trim().isNotEmpty;
  }

  // Cria uma nova versão do gasto,
  // mantendo os campos não alterados.
  Gasto copyWith({
    String? id,
    String? viagemId,
    String? descricao,
    double? valor,
    String? categoria,
    DateTime? data,
    String? observacao,
  }) {
    return Gasto(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      descricao: descricao ?? this.descricao,
      valor: valor ?? this.valor,
      categoria: categoria ?? this.categoria,
      data: data ?? this.data,
      observacao: observacao ?? this.observacao,
    );
  }

  // Converte o gasto em um mapa
  // para armazenamento no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagemId': viagemId,
      'descricao': descricao,
      'valor': valor,
      'categoria': categoria,
      'data': data.toIso8601String(),
      'observacao': observacao,
    };
  }

  // Cria um gasto a partir dos dados
  // recebidos do Supabase.
  factory Gasto.fromMap(Map<String, dynamic> map) {
    return Gasto(
      id: map['id'].toString(),
      viagemId: map['viagemId'].toString(),
      descricao: map['descricao'] as String,
      valor: (map['valor'] as num).toDouble(),
      categoria: map['categoria'] as String,
      data: DateTime.parse(
        map['data'] as String,
      ),
      observacao: map['observacao'] as String?,
    );
  }
}
