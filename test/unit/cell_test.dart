import 'package:flutter_test/flutter_test.dart';
import 'package:python_flutter_embed_demo/domain/entities/cell.dart';

void main() {
  group('Cell Tests', () {
    group('Constructor and Properties', () {
      test('should create cell with default values', () {
        final cell = Cell(
          hasBomb: false,
          row: 0,
          col: 0,
        );

        expect(cell.hasBomb, false);
        expect(cell.bombsAround, 0);
        expect(cell.state, CellState.unrevealed);
        expect(cell.row, 0);
        expect(cell.col, 0);
      });

      test('should create cell with custom values', () {
        final cell = Cell(
          hasBomb: true,
          bombsAround: 3,
          state: CellState.revealed,
          row: 5,
          col: 7,
        );

        expect(cell.hasBomb, true);
        expect(cell.bombsAround, 3);
        expect(cell.state, CellState.revealed);
        expect(cell.row, 5);
        expect(cell.col, 7);
      });
    });

    group('Getter Properties', () {
      test('should return correct isRevealed value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final revealedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);
        final flaggedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

        expect(unrevealedCell.isRevealed, false);
        expect(revealedCell.isRevealed, true);
        expect(flaggedCell.isRevealed, false);
      });

      test('should return correct isFlagged value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final flaggedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);
        final revealedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        expect(unrevealedCell.isFlagged, false);
        expect(flaggedCell.isFlagged, true);
        expect(revealedCell.isFlagged, false);
      });

      test('should return correct isExploded value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final explodedCell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.exploded);
        final revealedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        expect(unrevealedCell.isExploded, false);
        expect(explodedCell.isExploded, true);
        expect(revealedCell.isExploded, false);
      });

      test('should return correct isUnrevealed value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final revealedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);
        final flaggedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

        expect(unrevealedCell.isUnrevealed, true);
        expect(revealedCell.isUnrevealed, false);
        expect(flaggedCell.isUnrevealed, false);
      });

      test('should return correct isIncorrectlyFlagged value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final incorrectlyFlaggedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.incorrectlyFlagged);
        final correctlyFlaggedCell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.flagged);

        expect(unrevealedCell.isIncorrectlyFlagged, false);
        expect(incorrectlyFlaggedCell.isIncorrectlyFlagged, true);
        expect(correctlyFlaggedCell.isIncorrectlyFlagged, false);
      });

      test('should return correct isHitBomb value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final hitBombCell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.hitBomb);
        final explodedCell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.exploded);

        expect(unrevealedCell.isHitBomb, false);
        expect(hitBombCell.isHitBomb, true);
        expect(explodedCell.isHitBomb, false);
      });

      test('should return correct isFiftyFifty value', () {
        final unrevealedCell = Cell(hasBomb: false, row: 0, col: 0);
        final fiftyFiftyCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.fiftyFifty);
        final revealedCell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        expect(unrevealedCell.isFiftyFifty, false);
        expect(fiftyFiftyCell.isFiftyFifty, true);
        expect(revealedCell.isFiftyFifty, false);
      });

      test('should return correct isEmpty value', () {
        final emptyCell = Cell(hasBomb: false, bombsAround: 0, row: 0, col: 0);
        final numberCell = Cell(hasBomb: false, bombsAround: 3, row: 0, col: 0);
        final bombCell = Cell(hasBomb: true, bombsAround: 0, row: 0, col: 0);

        expect(emptyCell.isEmpty, true);
        expect(numberCell.isEmpty, false);
        expect(bombCell.isEmpty, false);
      });
    });

    group('reveal() method', () {
      test('should reveal unrevealed cell without bomb', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0);
        expect(cell.state, CellState.unrevealed);

        cell.reveal();

        expect(cell.state, CellState.revealed);
      });

      test('should explode unrevealed cell with bomb', () {
        final cell = Cell(hasBomb: true, row: 0, col: 0);
        expect(cell.state, CellState.unrevealed);

        cell.reveal();

        expect(cell.state, CellState.exploded);
      });

      test('should reveal fifty-fifty cell without bomb', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.fiftyFifty);

        cell.reveal();

        expect(cell.state, CellState.revealed);
      });

      test('should explode fifty-fifty cell with bomb', () {
        final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.fiftyFifty);

        cell.reveal();

        expect(cell.state, CellState.exploded);
      });

      test('should not change already revealed cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        cell.reveal();

        expect(cell.state, CellState.revealed);
      });

      test('should not change flagged cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

        cell.reveal();

        expect(cell.state, CellState.flagged);
      });

      test('should not change exploded cell', () {
        final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.exploded);

        cell.reveal();

        expect(cell.state, CellState.exploded);
      });
    });

    group('toggleFlag() method', () {
      test('should flag unrevealed cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0);
        expect(cell.state, CellState.unrevealed);

        cell.toggleFlag();

        expect(cell.state, CellState.flagged);
      });

      test('should flag fifty-fifty cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.fiftyFifty);

        cell.toggleFlag();

        expect(cell.state, CellState.flagged);
      });

      test('should unflag flagged cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

        cell.toggleFlag();

        expect(cell.state, CellState.unrevealed);
      });

      test('should not change revealed cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        cell.toggleFlag();

        expect(cell.state, CellState.revealed);
      });

      test('should not change exploded cell', () {
        final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.exploded);

        cell.toggleFlag();

        expect(cell.state, CellState.exploded);
      });
    });

    group('markAsFiftyFifty() method', () {
      test('should mark unrevealed cell as fifty-fifty', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0);
        expect(cell.state, CellState.unrevealed);

        cell.markAsFiftyFifty();

        expect(cell.state, CellState.fiftyFifty);
      });

      test('should not change already fifty-fifty cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.fiftyFifty);

        cell.markAsFiftyFifty();

        expect(cell.state, CellState.fiftyFifty);
      });

      test('should not change revealed cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        cell.markAsFiftyFifty();

        expect(cell.state, CellState.revealed);
      });

      test('should not change flagged cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

        cell.markAsFiftyFifty();

        expect(cell.state, CellState.flagged);
      });
    });

    group('unmarkFiftyFifty() method', () {
      test('should unmark fifty-fifty cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.fiftyFifty);

        cell.unmarkFiftyFifty();

        expect(cell.state, CellState.unrevealed);
      });

      test('should not change unrevealed cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.unrevealed);

        cell.unmarkFiftyFifty();

        expect(cell.state, CellState.unrevealed);
      });

      test('should not change revealed cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        cell.unmarkFiftyFifty();

        expect(cell.state, CellState.revealed);
      });

      test('should not change flagged cell', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

        cell.unmarkFiftyFifty();

        expect(cell.state, CellState.flagged);
      });
    });

    group('forceReveal() method', () {
      group('hitBomb parameter', () {
        test('should mark as hitBomb when isHitBomb is true and has bomb', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.unrevealed);

          cell.forceReveal(isHitBomb: true);

          expect(cell.state, CellState.hitBomb);
        });

        test('should not mark as hitBomb when isHitBomb is true but no bomb', () {
          final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.unrevealed);

          cell.forceReveal(isHitBomb: true);

          expect(cell.state, CellState.revealed);
        });

        test('should not mark as hitBomb when isHitBomb is false', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.unrevealed);

          cell.forceReveal(isHitBomb: false);

          expect(cell.state, CellState.exploded);
        });
      });

      group('flagged cells', () {
        test('should mark as incorrectlyFlagged when showIncorrectFlag is true and no bomb', () {
          final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

          cell.forceReveal(showIncorrectFlag: true);

          expect(cell.state, CellState.incorrectlyFlagged);
        });

        test('should keep flagged when has bomb and not exploded', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.flagged);

          cell.forceReveal(exploded: false);

          expect(cell.state, CellState.flagged);
        });

        test('should explode when has bomb and exploded', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.flagged);

          cell.forceReveal(exploded: true);

          expect(cell.state, CellState.exploded);
        });

        test('should reveal when no bomb and not showIncorrectFlag', () {
          final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.flagged);

          cell.forceReveal();

          expect(cell.state, CellState.revealed);
        });
      });

      group('unrevealed and fifty-fifty cells', () {
        test('should explode unrevealed cell with bomb when exploded is true', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.unrevealed);

          cell.forceReveal(exploded: true);

          expect(cell.state, CellState.exploded);
        });

        test('should reveal unrevealed cell with bomb when exploded is false', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.unrevealed);

          cell.forceReveal(exploded: false);

          expect(cell.state, CellState.revealed);
        });

        test('should reveal unrevealed cell without bomb', () {
          final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.unrevealed);

          cell.forceReveal();

          expect(cell.state, CellState.revealed);
        });

        test('should explode fifty-fifty cell with bomb when exploded is true', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.fiftyFifty);

          cell.forceReveal(exploded: true);

          expect(cell.state, CellState.exploded);
        });

        test('should reveal fifty-fifty cell with bomb when exploded is false', () {
          final cell = Cell(hasBomb: true, row: 0, col: 0, state: CellState.fiftyFifty);

          cell.forceReveal(exploded: false);

          expect(cell.state, CellState.revealed);
        });

        test('should reveal fifty-fifty cell without bomb', () {
          final cell = Cell(hasBomb: false, row: 0, col: 0, state: CellState.fiftyFifty);

          cell.forceReveal();

          expect(cell.state, CellState.revealed);
        });
      });
    });

    group('copyWith() method', () {
      test('should create copy with same values when no parameters provided', () {
        final original = Cell(
          hasBomb: true,
          bombsAround: 3,
          state: CellState.revealed,
          row: 5,
          col: 7,
        );

        final copy = original.copyWith();

        expect(copy.hasBomb, original.hasBomb);
        expect(copy.bombsAround, original.bombsAround);
        expect(copy.state, original.state);
        expect(copy.row, original.row);
        expect(copy.col, original.col);
        expect(copy, isNot(same(original))); // Different instance
      });

      test('should create copy with updated hasBomb', () {
        final original = Cell(hasBomb: false, row: 0, col: 0);
        final copy = original.copyWith(hasBomb: true);

        expect(copy.hasBomb, true);
        expect(copy.bombsAround, original.bombsAround);
        expect(copy.state, original.state);
        expect(copy.row, original.row);
        expect(copy.col, original.col);
      });

      test('should create copy with updated bombsAround', () {
        final original = Cell(hasBomb: false, row: 0, col: 0);
        final copy = original.copyWith(bombsAround: 5);

        expect(copy.hasBomb, original.hasBomb);
        expect(copy.bombsAround, 5);
        expect(copy.state, original.state);
        expect(copy.row, original.row);
        expect(copy.col, original.col);
      });

      test('should create copy with updated state', () {
        final original = Cell(hasBomb: false, row: 0, col: 0);
        final copy = original.copyWith(state: CellState.flagged);

        expect(copy.hasBomb, original.hasBomb);
        expect(copy.bombsAround, original.bombsAround);
        expect(copy.state, CellState.flagged);
        expect(copy.row, original.row);
        expect(copy.col, original.col);
      });

      test('should create copy with updated row', () {
        final original = Cell(hasBomb: false, row: 0, col: 0);
        final copy = original.copyWith(row: 10);

        expect(copy.hasBomb, original.hasBomb);
        expect(copy.bombsAround, original.bombsAround);
        expect(copy.state, original.state);
        expect(copy.row, 10);
        expect(copy.col, original.col);
      });

      test('should create copy with updated col', () {
        final original = Cell(hasBomb: false, row: 0, col: 0);
        final copy = original.copyWith(col: 15);

        expect(copy.hasBomb, original.hasBomb);
        expect(copy.bombsAround, original.bombsAround);
        expect(copy.state, original.state);
        expect(copy.row, original.row);
        expect(copy.col, 15);
      });

      test('should create copy with multiple updated values', () {
        final original = Cell(hasBomb: false, row: 0, col: 0);
        final copy = original.copyWith(
          hasBomb: true,
          bombsAround: 8,
          state: CellState.exploded,
          row: 20,
          col: 25,
        );

        expect(copy.hasBomb, true);
        expect(copy.bombsAround, 8);
        expect(copy.state, CellState.exploded);
        expect(copy.row, 20);
        expect(copy.col, 25);
      });
    });

    group('Equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        final cell1 = Cell(
          hasBomb: true,
          bombsAround: 3,
          state: CellState.revealed,
          row: 5,
          col: 7,
        );
        final cell2 = Cell(
          hasBomb: true,
          bombsAround: 3,
          state: CellState.revealed,
          row: 5,
          col: 7,
        );

        expect(cell1, equals(cell2));
        expect(cell1.hashCode, equals(cell2.hashCode));
      });

      test('should not be equal when hasBomb differs', () {
        final cell1 = Cell(hasBomb: true, row: 0, col: 0);
        final cell2 = Cell(hasBomb: false, row: 0, col: 0);

        expect(cell1, isNot(equals(cell2)));
      });

      test('should not be equal when bombsAround differs', () {
        final cell1 = Cell(hasBomb: false, bombsAround: 3, row: 0, col: 0);
        final cell2 = Cell(hasBomb: false, bombsAround: 5, row: 0, col: 0);

        expect(cell1, isNot(equals(cell2)));
      });

      test('should not be equal when state differs', () {
        final cell1 = Cell(hasBomb: false, row: 0, col: 0, state: CellState.unrevealed);
        final cell2 = Cell(hasBomb: false, row: 0, col: 0, state: CellState.revealed);

        expect(cell1, isNot(equals(cell2)));
      });

      test('should not be equal when row differs', () {
        final cell1 = Cell(hasBomb: false, row: 0, col: 0);
        final cell2 = Cell(hasBomb: false, row: 1, col: 0);

        expect(cell1, isNot(equals(cell2)));
      });

      test('should not be equal when col differs', () {
        final cell1 = Cell(hasBomb: false, row: 0, col: 0);
        final cell2 = Cell(hasBomb: false, row: 0, col: 1);

        expect(cell1, isNot(equals(cell2)));
      });

      test('should be equal to itself', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0);

        expect(cell, equals(cell));
      });

      test('should not be equal to null', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0);

        expect(cell, isNot(equals(null)));
      });

      test('should not be equal to different type', () {
        final cell = Cell(hasBomb: false, row: 0, col: 0);

        expect(cell, isNot(equals('not a cell')));
      });
    });

    group('toString() method', () {
      test('should return correct string representation', () {
        final cell = Cell(
          hasBomb: true,
          bombsAround: 3,
          state: CellState.revealed,
          row: 5,
          col: 7,
        );

        final result = cell.toString();

        expect(result, 'Cell(row: 5, col: 7, hasBomb: true, bombsAround: 3, state: CellState.revealed)');
      });

      test('should include all properties in string representation', () {
        final cell = Cell(
          hasBomb: false,
          bombsAround: 0,
          state: CellState.unrevealed,
          row: 0,
          col: 0,
        );

        final result = cell.toString();

        expect(result, contains('row: 0'));
        expect(result, contains('col: 0'));
        expect(result, contains('hasBomb: false'));
        expect(result, contains('bombsAround: 0'));
        expect(result, contains('state: CellState.unrevealed'));
      });
    });

    group('CellState enum', () {
      test('should have all expected values', () {
        expect(CellState.values, contains(CellState.unrevealed));
        expect(CellState.values, contains(CellState.revealed));
        expect(CellState.values, contains(CellState.flagged));
        expect(CellState.values, contains(CellState.exploded));
        expect(CellState.values, contains(CellState.incorrectlyFlagged));
        expect(CellState.values, contains(CellState.hitBomb));
        expect(CellState.values, contains(CellState.fiftyFifty));
      });

      test('should have correct number of values', () {
        expect(CellState.values.length, 7);
      });
    });
  });
}