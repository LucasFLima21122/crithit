/// Representa uma crítica (review) feita por um usuário sobre um jogo.
class Review {
  const Review({
    required this.author,
    required this.rating,
    required this.comment,
  });

  /// Nome de quem escreveu a review.
  final String author;

  /// Nota de 1 a 5 estrelas.
  final int rating;

  /// Texto livre da crítica.
  final String comment;
}

/// Representa um jogo dentro do catálogo do CritHit.
class Game {
  Game({
    required this.id,
    required this.title,
    required this.platform,
    required this.genre,
    required this.emoji,
    required this.synopsis,
    List<Review>? reviews,
  }) : reviews = reviews ?? <Review>[];

  final String id;
  final String title;
  final String platform;
  final String genre;

  /// Emoji usado como "capa" ilustrativa do jogo (evita depender de imagens
  /// externas neste estágio inicial do projeto).
  final String emoji;

  final String synopsis;

  /// Reviews da comunidade para este jogo. Mutável de propósito: no CP4 o
  /// dado é mockado em memória, sem persistência real.
  final List<Review> reviews;

  /// Nota média da comunidade, calculada a partir das reviews existentes.
  /// Quando não há nenhuma review ainda, retorna 0.
  double get averageRating {
    if (reviews.isEmpty) return 0;
    final int total = reviews.fold(0, (sum, review) => sum + review.rating);
    return total / reviews.length;
  }
}
