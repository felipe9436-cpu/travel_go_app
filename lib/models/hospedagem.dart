
class Hospedagem {
  final String id;
  final String viagemId;
  final String nome;
  final String endereco;
  final DateTime checkIn;
  final DateTime checkOut;
  final double valorTotal;
  final double? avaliacao;
  final String? observacao;
  final String? urlReserva;

  const Hospedagem({
    required this.id,
    required this.viagemId,
    required this.nome,
    required this.endereco,
    required this.checkIn,
    required this.checkOut,
    required this.valorTotal,
    this.avaliacao,
    this.observacao,
    this.urlReserva,
  });

  // Calcula a quantidade de noites da hospedagem.
  int get numeroNoites {
    final entrada = DateTime.utc(
      checkIn.year,
      checkIn.month,
      checkIn.day,
    );

    final saida = DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    );

    return saida.difference(entrada).inDays;
  }

  // Calcula o valor médio por noite.
  // Retorna zero caso as datas sejam inválidas.
  double get valorPorNoite {
    if (numeroNoites <= 0) return 0;

    return valorTotal / numeroNoites;
  }

  // Verifica se existe um endereço de reserva.
  bool get possuiUrlReserva {
    return urlReserva != null &&
        urlReserva!.trim().isNotEmpty;
  }

  // Retorna uma nova hospedagem com os dados alterados.
  Hospedagem copyWith({
    String? id,
    String? viagemId,
    String? nome,
    String? endereco,
    DateTime? checkIn,
    DateTime? checkOut,
    double? valorTotal,
    double? avaliacao,
    String? observacao,
    String? urlReserva,
  }) {
    return Hospedagem(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      valorTotal: valorTotal ?? this.valorTotal,
      avaliacao: avaliacao ?? this.avaliacao,
      observacao: observacao ?? this.observacao,
      urlReserva: urlReserva ?? this.urlReserva,
    );
  }

  // Converte a hospedagem em um mapa
  // para armazenamento no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagemId': viagemId,
      'nome': nome,
      'endereco': endereco,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'valorTotal': valorTotal,
      'avaliacao': avaliacao,
      'observacao': observacao,
      'urlReserva': urlReserva,
    };
  }

  // Constrói uma hospedagem usando
  // os dados recebidos do Supabase.
  factory Hospedagem.fromMap(
      Map<String, dynamic> map,
      ) {
    return Hospedagem(
      id: map['id'].toString(),
      viagemId: map['viagemId'].toString(),
      nome: map['nome'] as String,
      endereco: map['endereco'] as String,
      checkIn: DateTime.parse(
        map['checkIn'] as String,
      ),
      checkOut: DateTime.parse(
        map['checkOut'] as String,
      ),
      valorTotal:
      (map['valorTotal'] as num).toDouble(),
      avaliacao:
      (map['avaliacao'] as num?)?.toDouble(),
      observacao: map['observacao'] as String?,
      urlReserva: map['urlReserva'] as String?,
    );
  }
}
