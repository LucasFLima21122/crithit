import "package:flutter_test/flutter_test.dart";

import "package:crithit/utils/player_level.dart";

void main() {
  test("conta XP de críticas, notas, platinas e horas", () {
    final PlayerLevel level = PlayerLevel.from(
      reviewsWithText: 2,
      ratingsOnly: 1,
      platinums: 3,
      playtimeMinutes: 10 * 60 + 59,
    );
    expect(level.xp, 200 + 50 + 750 + 10);
  });

  test("sem nada é nível 1, Novato, com barra zerada", () {
    final PlayerLevel level = PlayerLevel.from(
      reviewsWithText: 0,
      ratingsOnly: 0,
      platinums: 0,
      playtimeMinutes: 0,
    );
    expect(level.level, 1);
    expect(level.rank, "Novato");
    expect(level.progress, 0);
    expect(level.xpToNext, 60);
  });

  test("os níveis sobem nas fronteiras de 60 × (N − 1)²", () {
    PlayerLevel at(int xp) => PlayerLevel.from(
      reviewsWithText: 0,
      ratingsOnly: 0,
      platinums: 0,
      playtimeMinutes: xp * 60,
    );
    expect(at(59).level, 1);
    expect(at(60).level, 2);
    expect(at(240).level, 3);
    expect(at(239).level, 2);
    expect(at(960).level, 5);
    expect(at(960).rank, "Crítico");
    expect(at(2940).rank, "Veterano");
    expect(at(7260).rank, "Lenda");
    expect(at(150).progress, closeTo((150 - 60) / (240 - 60), 1e-9));
  });
}
