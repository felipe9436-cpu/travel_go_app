
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/avaliacao.dart';
import '../models/checklist_item.dart';
import '../models/destino.dart';
import '../models/gasto.dart';
import '../models/hospedagem.dart';
import '../models/roteiro.dart';
import '../models/viagem.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ==================== SEGURANÇA ====================

  // As operações exigem uma sessão autenticada.
  // A proteção definitiva dos dados será feita
  // pelas políticas RLS no Supabase.
  void _verificarAutenticacao() {
    if (_client.auth.currentUser == null) {
      throw StateError(
        'Você precisa estar conectado para acessar os dados.',
      );
    }
  }

  // ==================== VIAGENS ====================

  Future<List<Viagem>> getViagens() async {
    _verificarAutenticacao();

    final response = await _client
        .from('viagens')
        .select()
        .order('dataInicio', ascending: true);

    return response
        .map((map) => Viagem.fromMap(map))
        .toList();
  }

  Future<void> salvarViagem(Viagem viagem) async {
    _verificarAutenticacao();

    await _client
        .from('viagens')
        .upsert(viagem.toMap());
  }

  Future<void> deletarViagem(String id) async {
    _verificarAutenticacao();

    await _client
        .from('viagens')
        .delete()
        .eq('id', id);
  }

  // ==================== DESTINOS ====================

  Future<List<Destino>> getDestinos(
      String viagemId,
      ) async {
    _verificarAutenticacao();

    final response = await _client
        .from('destinos')
        .select()
        .eq('viagemId', viagemId)
        .order('nome');

    return response
        .map((map) => Destino.fromMap(map))
        .toList();
  }

  Future<void> salvarDestino(Destino destino) async {
    _verificarAutenticacao();

    await _client
        .from('destinos')
        .upsert(destino.toMap());
  }

  Future<void> deletarDestino(String id) async {
    _verificarAutenticacao();

    await _client
        .from('destinos')
        .delete()
        .eq('id', id);
  }

  // ==================== ROTEIRO ====================

  Future<List<Roteiro>> getRoteiro(
      String viagemId,
      ) async {
    _verificarAutenticacao();

    final response = await _client
        .from('roteiro')
        .select()
        .eq('viagemId', viagemId)
        .order('data', ascending: true);

    return response
        .map((map) => Roteiro.fromMap(map))
        .toList();
  }

  Future<void> salvarRoteiro(Roteiro item) async {
    _verificarAutenticacao();

    await _client
        .from('roteiro')
        .upsert(item.toMap());
  }

  Future<void> deletarRoteiro(String id) async {
    _verificarAutenticacao();

    await _client
        .from('roteiro')
        .delete()
        .eq('id', id);
  }

  // ==================== HOSPEDAGENS ====================

  Future<List<Hospedagem>> getHospedagens(
      String viagemId,
      ) async {
    _verificarAutenticacao();

    final response = await _client
        .from('hospedagens')
        .select()
        .eq('viagemId', viagemId)
        .order('checkIn', ascending: true);

    return response
        .map((map) => Hospedagem.fromMap(map))
        .toList();
  }

  Future<void> salvarHospedagem(
      Hospedagem hospedagem,
      ) async {
    _verificarAutenticacao();

    await _client
        .from('hospedagens')
        .upsert(hospedagem.toMap());
  }

  Future<void> deletarHospedagem(String id) async {
    _verificarAutenticacao();

    await _client
        .from('hospedagens')
        .delete()
        .eq('id', id);
  }

  // ==================== GASTOS ====================

  Future<List<Gasto>> getGastos(
      String viagemId,
      ) async {
    _verificarAutenticacao();

    final response = await _client
        .from('gastos')
        .select()
        .eq('viagemId', viagemId)
        .order('data', ascending: false);

    return response
        .map((map) => Gasto.fromMap(map))
        .toList();
  }

  Future<void> salvarGasto(Gasto gasto) async {
    _verificarAutenticacao();

    await _client
        .from('gastos')
        .upsert(gasto.toMap());
  }

  Future<void> deletarGasto(String id) async {
    _verificarAutenticacao();

    await _client
        .from('gastos')
        .delete()
        .eq('id', id);
  }

  // ==================== CHECKLIST ====================

  Future<List<ChecklistItem>> getChecklist(
      String viagemId,
      ) async {
    _verificarAutenticacao();

    final response = await _client
        .from('checklist')
        .select()
        .eq('viagemId', viagemId)
        .order('categoria')
        .order('titulo');

    return response
        .map((map) => ChecklistItem.fromMap(map))
        .toList();
  }

  Future<void> salvarChecklistItem(
      ChecklistItem item,
      ) async {
    _verificarAutenticacao();

    await _client
        .from('checklist')
        .upsert(item.toMap());
  }

  Future<void> deletarChecklistItem(String id) async {
    _verificarAutenticacao();

    await _client
        .from('checklist')
        .delete()
        .eq('id', id);
  }

  // ==================== AVALIAÇÕES ====================

  Future<List<Avaliacao>> getAvaliacoes(
      String viagemId,
      ) async {
    _verificarAutenticacao();

    final response = await _client
        .from('avaliacoes')
        .select()
        .eq('viagemId', viagemId)
        .order('data', ascending: false);

    return response
        .map((map) => Avaliacao.fromMap(map))
        .toList();
  }

  Future<void> salvarAvaliacao(
      Avaliacao avaliacao,
      ) async {
    _verificarAutenticacao();

    await _client
        .from('avaliacoes')
        .upsert(avaliacao.toMap());
  }

  Future<void> deletarAvaliacao(String id) async {
    _verificarAutenticacao();

    await _client
        .from('avaliacoes')
        .delete()
        .eq('id', id);
  }
}
