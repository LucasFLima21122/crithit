import "package:supabase_flutter/supabase_flutter.dart";

import "../data/mock_reviews.dart";
import "../models/review.dart";

/// Acesso às reviews. Cada usuário tem no máximo uma review por jogo:
/// salvar de novo atualiza a existente (como no Letterboxd).
abstract class ReviewRepository {
  /// Todas as reviews, da mais recente para a mais antiga.
  Future<List<Review>> fetchAll();

  /// Cria ou atualiza a review do usuário para o jogo.
  Future<Review> save({
    required String userId,
    required String authorName,
    required String gameId,
    required String gameTitle,
    required int rating,
    required String comment,
  });

  Future<void> delete(String reviewId);
}

/// Reviews em memória (modo offline), já com as reviews de exemplo.
class LocalReviewRepository implements ReviewRepository {
  final List<Review> _reviews = buildMockReviews();
  int _nextId = 1;

  @override
  Future<List<Review>> fetchAll() async {
    return List<Review>.of(_reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Review> save({
    required String userId,
    required String authorName,
    required String gameId,
    required String gameTitle,
    required int rating,
    required String comment,
  }) async {
    final int index = _reviews.indexWhere(
      (r) => r.userId == userId && r.gameId == gameId,
    );
    final Review review = index >= 0
        ? _reviews[index].copyWith(
            rating: rating,
            comment: comment,
            createdAt: DateTime.now(),
          )
        : Review(
            id: "local-${_nextId++}",
            gameId: gameId,
            gameTitle: gameTitle,
            userId: userId,
            authorName: authorName,
            rating: rating,
            comment: comment,
            createdAt: DateTime.now(),
          );
    if (index >= 0) {
      _reviews[index] = review;
    } else {
      _reviews.add(review);
    }
    return review;
  }

  @override
  Future<void> delete(String reviewId) async {
    _reviews.removeWhere((r) => r.id == reviewId);
  }
}

/// Reviews persistidas na tabela `public.reviews` do Supabase. As policies
/// de RLS garantem que cada usuário só altera as próprias reviews.
class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Review>> fetchAll() async {
    final List<Map<String, dynamic>> rows = await _client
        .from("reviews")
        .select()
        .order("created_at", ascending: false)
        .limit(1000);
    return rows.map(Review.fromMap).toList();
  }

  @override
  Future<Review> save({
    required String userId,
    required String authorName,
    required String gameId,
    required String gameTitle,
    required int rating,
    required String comment,
  }) async {
    final Map<String, dynamic> row = await _client
        .from("reviews")
        .upsert(<String, dynamic>{
          "user_id": userId,
          "author_name": authorName,
          "game_id": gameId,
          "game_title": gameTitle,
          "rating": rating,
          "comment": comment,
          "created_at": DateTime.now().toUtc().toIso8601String(),
        }, onConflict: "user_id,game_id")
        .select()
        .single();
    return Review.fromMap(row);
  }

  @override
  Future<void> delete(String reviewId) async {
    await _client.from("reviews").delete().eq("id", reviewId);
  }
}
