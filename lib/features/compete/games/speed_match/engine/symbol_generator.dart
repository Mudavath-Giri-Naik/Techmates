import 'dart:math';

/// Game phases that determine the symbol pool.
enum GamePhase {
  basicShapes,
  rotatedShapes,
  csSymbols,
  confusables,
  colourShape,
  ruleFlip,
}

/// A generated symbol with optional colour (phase 5+).
class GeneratedSymbol {
  final String symbol;
  final int colorIndex; // index into symbolColors, -1 = no colour

  const GeneratedSymbol(this.symbol, [this.colorIndex = -1]);

  bool matches(GeneratedSymbol other) {
    if (colorIndex >= 0 && other.colorIndex >= 0) {
      return symbol == other.symbol && colorIndex == other.colorIndex;
    }
    return symbol == other.symbol;
  }
}

/// Seeded symbol generation for Speed Match.
///
/// Accepts a [gameSeed] so both duel players see the identical sequence.
class SymbolGenerator {
  final int gameSeed;
  final GamePhase phase;
  late final Random _rng;

  /// Symbol pools per phase.
  static const Map<GamePhase, List<String>> symbolPools = {
    GamePhase.basicShapes: ['○', '△', '□', '◇', '⬟'],
    GamePhase.rotatedShapes: ['△', '▽', '◁', '▷', '□', '◇'],
    GamePhase.csSymbols: [
      '{}', '[]', '()', '<>', '=>', '->', '::', '//', '&&', '||', '!=', '==',
      '++', '--',
    ],
    GamePhase.confusables: [
      'O', '0', '|', 'l', 'I', 'rn', 'm', '[]', '[|', ',', '.', '1',
    ],
    GamePhase.colourShape: ['○', '△', '□', '◇', '⬟'],
    GamePhase.ruleFlip: ['○', '△', '□', '◇', '⬟', '{}', '[]', '!=', '=='],
  };

  static const int colorCount = 5; // red, blue, green, yellow, purple

  SymbolGenerator({required this.gameSeed, required this.phase})
      : _rng = Random(gameSeed);

  /// Generates the next symbol.
  ///
  /// - 40 % chance of matching [previous], 60 % non-match.
  /// - Never shows the same non-match symbol twice in a row.
  GeneratedSymbol next(GeneratedSymbol? previous) {
    final pool = symbolPools[phase]!;
    final useColour =
        phase == GamePhase.colourShape || phase == GamePhase.ruleFlip;

    if (previous == null) {
      // First card — pick random.
      final sym = pool[_rng.nextInt(pool.length)];
      final col = useColour ? _rng.nextInt(colorCount) : -1;
      return GeneratedSymbol(sym, col);
    }

    final shouldMatch = _rng.nextDouble() < 0.40;

    if (shouldMatch) {
      // Return same symbol (and colour if applicable).
      return GeneratedSymbol(
        previous.symbol,
        useColour ? previous.colorIndex : -1,
      );
    }

    // Pick a different symbol.
    String sym;
    do {
      sym = pool[_rng.nextInt(pool.length)];
    } while (sym == previous.symbol);

    int col = -1;
    if (useColour) {
      // Also randomise colour, but ensure at least one dimension differs.
      col = _rng.nextInt(colorCount);
      // If symbol ended up same by re-roll, guarantee colour differs.
      if (sym == previous.symbol && col == previous.colorIndex) {
        col = (col + 1) % colorCount;
      }
    }

    return GeneratedSymbol(sym, col);
  }

  /// Returns the [GamePhase] for a given level.
  static GamePhase phaseFor(int level) {
    if (level <= 5) return GamePhase.basicShapes;
    if (level <= 15) return GamePhase.rotatedShapes;
    if (level <= 30) return GamePhase.csSymbols;
    if (level <= 50) return GamePhase.confusables;
    if (level <= 75) return GamePhase.colourShape;
    return GamePhase.ruleFlip;
  }
}
