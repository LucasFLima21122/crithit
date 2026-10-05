import "package:flutter_test/flutter_test.dart";

import "package:crithit/utils/formatters.dart";

void main() {
  test("formatPlaytime", () {
    expect(formatPlaytime(0), "nunca jogado");
    expect(formatPlaytime(45), "45 min");
    expect(formatPlaytime(60), "1 h");
    expect(formatPlaytime(750), "12,5 h");
    expect(formatPlaytime(31250), "521 h");
  });

  test("formatHoursTotal usa separador de milhar", () {
    expect(formatHoursTotal(30), "1");
    expect(formatHoursTotal(72240), "1.204");
  });

  test("formatRelativeDate", () {
    final DateTime now = DateTime(2026, 10, 5, 12);
    expect(formatRelativeDate(DateTime(2026, 10, 5, 8), now: now), "hoje");
    expect(formatRelativeDate(DateTime(2026, 10, 4, 23), now: now), "ontem");
    expect(formatRelativeDate(DateTime(2026, 10, 1), now: now), "há 4 dias");
    expect(formatRelativeDate(DateTime(2026, 9, 20), now: now), "há 2 semanas");
    expect(formatRelativeDate(DateTime(2026, 5, 2), now: now), "02/05/2026");
  });

  test("ratingLabel e formatAverage", () {
    expect(ratingLabel(5), "Obra-prima");
    expect(ratingLabel(1), "Ruim");
    expect(formatAverage(4.333), "4,3");
  });
}
