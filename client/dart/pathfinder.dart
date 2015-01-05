library pathfinder;

import 'dart:html';

import 'package:pathfinding/core/grid.dart';
import 'package:pathfinding/finders/astar.dart';

import "base.dart";
import "character.dart";
import 'position.dart';

class Pathfinder extends Base {

  int width;
  int height;
  List<List<int>> grid;
  List<List<int>> blankGrid;
  List<Character> ignored = [];

  Pathfinder(int this.width, int this.height) {
    this.blankGrid = new List<List<int>>(this.height);
    for (int i = 0; i < this.height; ++i) {
      this.blankGrid[i] = new List<int>(this.width); 
      this.blankGrid[i].fillRange(0, this.width, 0);
    }
  }

  dynamic _AStarCompute(List<List<int>> rawGrid, List<int> start, List<int> end) {
    Grid grid = new Grid(rawGrid.first.length, rawGrid.length, rawGrid);
    AStarFinder astarf = new AStarFinder();
    return astarf.findPath(start[0], start[1], end[0], end[1], grid);
  }

  List<List<int>> findPath(
    List<List<int>> grid,
    Character character,
    Position position,
    bool findIncomplete
  ) {
    List<int> start = [character.gridPosition.x, character.gridPosition.y];
    List<int> end = [position.x, position.y];
    List<List<int>> path;

    this.grid = grid;
    this.applyIgnoreList_(true);
    path = this._AStarCompute(this.grid, start, end);
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

    perfect = this._AStarCompute(this.blankGrid, start, end);

    for (var i = perfect.length - 1; i > 0; i -= 1) {
      x = perfect[i][0];
      y = perfect[i][1];

      if (this.grid[y][x] == 0) {
        incomplete = this._AStarCompute(this.grid, start, [x, y]);
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
      int x = character.isMoving() ? character.nextGridX : character.gridPosition.x;
      int y = character.isMoving() ? character.nextGridY : character.gridPosition.y;

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
