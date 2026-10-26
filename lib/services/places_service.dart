import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  // Substitua pela sua chave da Google Places API se for utilizar
  static const String _googleApiKey = 'SUA_CHAVE_API_GOOGLE';

  /// 1. Busca de países e cidades via REST Countries API (100% Gratuita / Sem Chave)
  Future<List<Map<String, dynamic>>> buscarPaises(String query) async {
    if (query.trim().length < 2) return [];

    final url = Uri.parse('https://restcountries.com/v3.1/name/$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) {
          return {
            'nome': item['translations']?['por']?['common'] ?? item['name']['common'],
            'capital': (item['capital'] as List?)?.first ?? '',
            'bandeira': item['flag'] ?? '',
            'moeda': (item['currencies'] as Map?)?.keys.first ?? 'USD',
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar países: $e');
      return [];
    }
  }

  /// 2. Autocomplete de pontos turísticos e locais via Google Places API
  Future<List<Map<String, dynamic>>> buscarLocaisGoogle(String query) async {
    if (query.trim().length < 3) return [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&language=pt-BR&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['predictions']);
      }
      return [];
    } catch (e) {
      print('Erro ao buscar autocomplete Google: $e');
      return [];
    }
  }

  /// 3. Obter detalhes completos de um local (Latitude, Longitude e Avaliação)
  Future<Map<String, dynamic>?> obterDetalhesDoLocal(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,geometry,rating&language=pt-BR&key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['result'];
      }
      return null;
    } catch (e) {
      print('Erro ao obter detalhes do local: $e');
      return null;
    }
  }
}