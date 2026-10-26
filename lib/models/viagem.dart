
class Viagem {
  final String id;
  final String nome;
  final String destino;
  final DateTime dataInicio;
  final DateTime dataFim;
  final int numeroViajantes;
  final double orcamento;
  final String? imagemUrl;

  const Viagem({
    required this.id,
    required this.nome,
    required this.destino,
    required this.dataInicio,
    required this.dataFim,
    required this.numeroViajantes,
    required this.orcamento,
    this.imagemUrl,
  });

  // Quantidade de dias da viagem, incluindo
  // o primeiro e o último dia.
  int get duracaoEmDias {
    final inicio = DateTime(
      dataInicio.year,
      dataInicio.month,
      dataInicio.day,
    );

    final fim = DateTime(
      dataFim.year,
      dataFim.month,
      dataFim.day,
    );

    return fim.difference(inicio).inDays + 1;
  }

  // Retorna uma nova viagem com os campos alterados.
  Viagem copyWith({
    String? id,
    String? nome,
    String? destino,
    DateTime? dataInicio,
    DateTime? dataFim,
    int? numeroViajantes,
    double? orcamento,
    String? imagemUrl,
  }) {
    return Viagem(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      destino: destino ?? this.destino,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      numeroViajantes:
      numeroViajantes ?? this.numeroViajantes,
      orcamento: orcamento ?? this.orcamento,
      imagemUrl: imagemUrl ?? this.imagemUrl,
    );
  }

  // Converte o objeto para um mapa.
  // Os nomes das chaves devem corresponder
  // às colunas configuradas no Supabase.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'destino': destino,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'numeroViajantes': numeroViajantes,
      'orcamento': orcamento,
      'imagemUrl': imagemUrl,
    };
  }

  // Cria uma viagem a partir de dados
  // recebidos do banco de dados.
  factory Viagem.fromMap(Map<String, dynamic> map) {
    return Viagem(
      id: map['id'].toString(),
      nome: map['nome'] as String,
      destino: map['destino'] as String,
      dataInicio: DateTime.parse(
        map['dataInicio'] as String,
      ),
      dataFim: DateTime.parse(
        map['dataFim'] as String,
      ),
      numeroViajantes:
      (map['numeroViajantes'] as num).toInt(),
      orcamento:
      (map['orcamento'] as num).toDouble(),
      imagemUrl: map['imagemUrl'] as String?,
    );
  }
}
