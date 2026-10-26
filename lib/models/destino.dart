
class Destino {
  final String id;
  final String viagemId;
  final String nome;
  final String cidade;
  final String pais;
  final String categoria;
  final String? descricao;
  final double? latitude;
  final double? longitude;
  final double? avaliacao;

  const Destino({
    required this.id,
    required this.viagemId,
    required this.nome,
    required this.cidade,
    required this.pais,
    required this.categoria,
    this.descricao,
    this.latitude,
    this.longitude,
    this.avaliacao,
  });

  // Identifica se o destino possui coordenadas.
  bool get possuiLocalizacao {
    return latitude != null && longitude != null;
  }

  // Retorna a cidade e o país formatados.
  String get localizacaoFormatada {
    if (cidade.isEmpty && pais.isEmpty) {
      return 'Localização não informada';
    }

    if (cidade.isEmpty) return pais;
    if (pais.isEmpty) return cidade;

    return '$cidade, $pais';
  }

  // Cria uma nova versão do destino,
  // preservando os campos não alterados.
  Destino copyWith({
    String? id,
    String? viagemId,
    String? nome,
    String? cidade,
    String? pais,
    String? categoria,
    String? descricao,
    double? latitude,
    double? longitude,
    double? avaliacao,
  }) {
    return Destino(
      id: id ?? this.id,
      viagemId: viagemId ?? this.viagemId,
      nome: nome ?? this.nome,
      cidade: cidade ?? this.cidade,
      pais: pais ?? this.pais,
      categoria: categoria ?? this.categoria,
      descricao: descricao ?? this.descricao,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      avaliacao: avaliacao ?? this.avaliacao,
    );
  }

  // Converte o destino em um mapa para
  // armazenamento no banco de dados.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'viagemId': viagemId,
      'nome': nome,
      'cidade': cidade,
      'pais': pais,
      'categoria': categoria,
      'descricao': descricao,
      'latitude': latitude,
      'longitude': longitude,
      'avaliacao': avaliacao,
    };
  }

  // Constrói o destino usando os dados
  // recebidos do Supabase.
  factory Destino.fromMap(Map<String, dynamic> map) {
    return Destino(
      id: map['id'].toString(),
      viagemId: map['viagemId'].toString(),
      nome: map['nome'] as String,
      cidade: map['cidade'] as String,
      pais: map['pais'] as String,
      categoria: map['categoria'] as String,
      descricao: map['descricao'] as String?,
      latitude:
      (map['latitude'] as num?)?.toDouble(),
      longitude:
      (map['longitude'] as num?)?.toDouble(),
      avaliacao:
      (map['avaliacao'] as num?)?.toDouble(),
    );
  }
}
