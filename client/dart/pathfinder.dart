library pathfinder;

import "base.dart";
import "character.dart";
import "lib/astar.dart";

class Pathfinder extends Base {

  int width;
  int height;
  List<List<int>> grid = new List<List<int>>();
  List<List<int>> blankGrid = new List<List<int>>();
  List<Character> ignored = [];

  Pathfinder(int this.width, int this.height) {
    for (int i = 0; i < this.height; ++i) {
      this.blankGrid[i].fillRange(0, this.width, 0);
    }
  }

  List<List<int>> findPath(
    List<List<int>> grid, 
    Character character, 
    int x, 
    int y, 
    bool findIncomplete
  ) {
    List<int> start = [character.gridX, character.gridY];
    List<int> end = [x, y];
    List<List<int>> path;

    this.grid = grid;
    this.applyIgnoreList_(true);
    path = AStar.compute(this.grid, start, end);
    if (path.length == 0 && findIncomplete) {
      // If no path was found, try and find an incomplete one
      // to at least get closer to destination.
      path = this.findIncompletePath_(start, end);
    }

    return path;
  }

  /**
   * Finds a path which leads the closest possible to an unreachable x, y position.
   *
   * Whenever A* returns an empty path, it means that the destination tile is unreachable.
   * We would like the entities to move the closest possible to it though, instead of
   * staying where they are without moving at all. That's why we have this function which
   * returns an incomplete path to the chosen destination.
   *
   * @private
   * @returns {Array} The incomplete path towards the end position
   */
  List<List<int>> findIncompletePath_(List<int> start, List<int> end) {
    List<List<int>> perfect = [];
    List<List<int>> incomplete = [];
    int x;
    int y;

    perfect = AStar.compute(this.blankGrid, start, end);

    for (var i = perfect.length - 1; i > 0; i -= 1) {
      x = perfect[i][0];
      y = perfect[i][1];

      if (this.grid[y][x] == 0) {
        incomplete = AStar.compute(this.grid, start, [x, y]);
        break;
      }
    }

    return incomplete;
  }

  /**
   * Removes colliding tiles corresponding to the given entity's position in the pathing grid.
   */
  void ignoreEntity(Character character) {
    this.ignored.add(character);
  }

  void applyIgnoreList_(bool ignored) {
    var x, y, g;

    this.ignored.forEach((Character character) {
      int x = character.isMoving() ? character.nextGridX : character.gridX;
      int y = character.isMoving() ? character.nextGridY : character.gridY;

      if (x >= 0 && y >= 0) {
        this.grid[y][x] = ignored ? 0 : 1;
      }
    });
  }

  void clearIgnoreList() {
    this.applyIgnoreList_(false);
    this.ignored = [];
  }
}
