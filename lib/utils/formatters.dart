/// Formatações em pt-BR usadas na interface (sem depender do pacote intl).
library;

String _two(int value) => value.toString().padLeft(2, "0");

/// `05/10/2026`
String formatDate(DateTime date) =>
    "${_two(date.day)}/${_two(date.month)}/${date.year}";

/// "hoje", "ontem", "há 3 dias", "há 2 semanas" ou a data completa.
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final DateTime today = now ?? DateTime.now();
  final int days = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(date.year, date.month, date.day)).inDays;
  if (days <= 0) return "hoje";
  if (days == 1) return "ontem";
  if (days < 7) return "há $days dias";
  if (days < 30) {
    final int weeks = days ~/ 7;
    return weeks == 1 ? "há 1 semana" : "há $weeks semanas";
  }
  return formatDate(date);
}

/// "45 min", "12,5 h", "521 h".
String formatPlaytime(int minutes) {
  if (minutes <= 0) return "nunca jogado";
  if (minutes < 60) return "$minutes min";
  final double hours = minutes / 60;
  if (hours < 100) {
    final String text = hours.toStringAsFixed(1).replaceAll(".", ",");
    return "${text.endsWith(",0") ? text.substring(0, text.length - 2) : text} h";
  }
  return "${hours.round()} h";
}

/// Total de horas, sem casas decimais, com separador de milhar: "1.204".
String formatHoursTotal(int minutes) {
  final String digits = (minutes / 60).round().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(".");
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Média com uma casa decimal e vírgula: "4,3".
String formatAverage(double value) =>
    value.toStringAsFixed(1).replaceAll(".", ",");

/// Rótulo de cada nota, mostrado ao escolher as estrelas.
String ratingLabel(int rating) {
  switch (rating) {
    case 1:
      return "Ruim";
    case 2:
      return "Fraco";
    case 3:
      return "Bom";
    case 4:
      return "Ótimo";
    case 5:
      return "Obra-prima";
    default:
      return "Toque nas estrelas para dar sua nota";
  }
}

/// "1 review" / "3 reviews".
String pluralReviews(int count) => count == 1 ? "1 review" : "$count reviews";
