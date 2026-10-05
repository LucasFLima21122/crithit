/// Uma crítica (review) de um usuário sobre um jogo: nota de 1 a 5 estrelas
/// e um texto livre. Espelha a tabela `public.reviews` do Supabase.
class Review {
  const Review({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userId,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map["id"] as String,
      gameId: map["game_id"] as String,
      gameTitle: map["game_title"] as String,
      userId: map["user_id"] as String?,
      authorName: map["author_name"] as String,
      rating: (map["rating"] as num).toInt(),
      comment: (map["comment"] as String?) ?? "",
      createdAt: DateTime.parse(map["created_at"] as String).toLocal(),
    );
  }

  final String id;
  final String gameId;

  /// Guardado junto da review para o histórico do perfil conseguir mostrar
  /// o nome do jogo mesmo que ele não esteja mais na biblioteca/catálogo.
  final String gameTitle;

  /// Dono da review. `null` nas reviews de exemplo (seed) da comunidade.
  final String? userId;
  final String authorName;

  /// Nota de 1 a 5 estrelas.
  final int rating;

  /// Texto livre da crítica (pode ser vazio: só a nota já vale).
  final String comment;
  final DateTime createdAt;

  bool get hasComment => comment.trim().isNotEmpty;

  Map<String, dynamic> toInsertMap() {
    return <String, dynamic>{
      "game_id": gameId,
      "game_title": gameTitle,
      "user_id": userId,
      "author_name": authorName,
      "rating": rating,
      "comment": comment,
    };
  }

  Review copyWith({int? rating, String? comment, DateTime? createdAt}) {
    return Review(
      id: id,
      gameId: gameId,
      gameTitle: gameTitle,
      userId: userId,
      authorName: authorName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
