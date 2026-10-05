// Gera `supabase/seed.sql` a partir das reviews mockadas do app, para o
// banco online começar com a mesma comunidade de exemplo do modo offline.
//
// Uso: dart run tool/generate_seed.dart > supabase/seed.sql
import "package:crithit/data/mock_reviews.dart";
import "package:crithit/models/review.dart";

String _sql(String value) => "'${value.replaceAll("'", "''")}'";

String _timestamp(DateTime date) {
  String two(int v) => v.toString().padLeft(2, "0");
  // As datas mockadas estão no horário de Brasília.
  return "${date.year}-${two(date.month)}-${two(date.day)} "
      "${two(date.hour)}:${two(date.minute)}:00-03";
}

void main() {
  final List<Review> reviews = buildMockReviews();
  final StringBuffer out = StringBuffer()
    ..writeln("-- Gerado por tool/generate_seed.dart — não edite à mão.")
    ..writeln("-- Reviews de exemplo da comunidade (user_id nulo = seed).")
    ..writeln("delete from public.reviews where user_id is null;")
    ..writeln()
    ..writeln(
      "insert into public.reviews "
      "(game_id, game_title, author_name, rating, comment, created_at) values",
    );

  for (int i = 0; i < reviews.length; i++) {
    final Review r = reviews[i];
    final String end = i == reviews.length - 1 ? ";" : ",";
    out.writeln(
      "  (${_sql(r.gameId)}, ${_sql(r.gameTitle)}, ${_sql(r.authorName)}, "
      "${r.rating}, ${_sql(r.comment)}, '${_timestamp(r.createdAt)}')$end",
    );
  }

  // ignore: avoid_print
  print(out.toString().trimRight());
}
