library astar;

import 'dart:math' as math;

/**
 * A* (A-Star) algorithm for a path finder
 * @author  Andrea Giammarchi
 * @license Mit Style License
 */
diagonalSuccessors($N, $S, $E, $W, N, S, E, W, grid, rows, cols, result, i) {
    if($N) {
        if ($E && !grid[N][E]) {
          result.add({'x':E, 'y':N});
          i++;
        }
        if ($W && !grid[N][W]) {
          result.add({'x':W, 'y':N});
          i++;
        }
    }
    if($S){
        if ($E && !grid[S][E]) {
          result.add({'x':E, 'y':S});
          i++;
        }
        if ($W && !grid[S][W]) {
          result.add({'x':W, 'y':S});
          i++;
        }
    }
    return result;
}

diagonalSuccessorsFree($N, $S, $E, $W, N, S, E, W, grid, rows, cols, result, i) {
    $N = N > -1;
    $S = S < rows;
    $E = E < cols;
    $W = W > -1;
    if($E) {
        if ($N && !grid[N][E]) {
          result.add({'x':E, 'y':N});
          i++;
        }
        if ($S && !grid[S][E]) {
          result.add({'x':E, 'y':S});
          i++;
        }
    }
    if($W) {
        if ($N && !grid[N][W]) {
          result.add({'x':W, 'y':N});
          i++;
        }
        if ($S && !grid[S][W]) {
          result.add({'x':W, 'y':S});
          i++;
        }
    }

    return result;
}

nothingToDo($N, $S, $E, $W, N, S, E, W, grid, rows, cols, result, i) {
    return result;
}

successors(find, x, y, grid, rows, cols){
    var
        N = y - 1,
        S = y + 1,
        E = x + 1,
        W = x - 1,
        $N = N > -1 && !grid[N][x],
        $S = S < rows && !grid[S][x],
        $E = E < cols && !grid[y][E],
        $W = W > -1 && !grid[y][W],
        result = [],
        i = 0
    ;
    if ($N) {
      result.add({'x':x, 'y':N});
      i++;
    }
    if ($E) {
      result.add({'x':E, 'y':y});
      i++;
    }
    if ($S) {
      result.add({'x':x, 'y':S});
      i++;
    }
    if ($W) {
      result.add({'x':W, 'y':y});
      i++;
    }
    return find($N, $S, $E, $W, N, S, E, W, grid, rows, cols, result, i);
}

diagonal(start, end, f1, f2) {
    return f2(f1(start['x'] - end['x']), f1(start['y'] - end['y']));
}

euclidean(start, end, f1, f2) {
    var
        x = start['x'] - end['x'],
        y = start['y'] - end['y']
    ;
    return f2(x * x + y * y);
}

manhattan(start, end, f1, f2) {
    return f1(start['x'] - end['x']) + f1(start['y'] - end['y']);
}

int abs(int number) {
  return number > 0 ? number : -number;
}

class AStar {

  static compute(List<List<int>> grid, List<int> start, List<int> endLoc, [String f = null]) {
      var cols = grid[0].length;
      var rows = grid.length;
      var limit = cols * rows;
      var f1 = abs;
      var f2 = math.max;
      var list = {};
      var result = [];
      var open = [{'x':start[0], 'y':start[1], 'f':0, 'g':0, 'v':start[0]+start[1]*cols}];
      var length = 1;
      var adj, distance, find, i, j, max, min, current, next;
      var end = {'x':endLoc[0], 'y':endLoc[1], 'v':endLoc[0]+endLoc[1]*cols};
      switch (f) {
          case "Diagonal":
              find = diagonalSuccessors;
              distance = diagonal;
              break;
          case "DiagonalFree":
              distance = diagonal;
              break;
          case "Euclidean":
              find = diagonalSuccessors;
              f2 = math.sqrt;
              distance = euclidean;
              break;
          case "EuclideanFree":
              f2 = math.sqrt;
              distance = euclidean;
              break;
          default:
              distance = manhattan;
              find = nothingToDo;
              break;
      }
      if (find == null) {
        find = diagonalSuccessorsFree;
      }
      do {
          max = limit;
          min = 0;
          for(i = 0; i < length; ++i) {
              if((f = open[i]['f']) < max) {
                  max = f;
                  min = i;
              }
          };

          current = open.getRange(min, min+1).first;
          open.removeRange(min, min+1);
          if (current['v'] != end['v']) {
              --length;
              next = successors(find, current['x'], current['y'], grid, rows, cols);
              j = next.length;
              for(i = 0; i < j; ++i){
                  (adj = next[i])['p'] = current;
                  adj['f'] = adj['g'] = 0;
                  adj['v'] = adj['x'] + adj['y'] * cols;
                  if(!list.containsKey(adj['v'])){
                      adj['f'] = (adj['g'] = current['g'] + distance(adj, current, f1, f2)) + distance(adj, end, f1, f2);
                      open.add(adj);
                      length++;
                      list[adj['v']] = 1;
                  }
              }
          } else {
              i = length = 0;
              do {
                  result.add([current['x'], current['y']]);
                  i++;
              } while (current = current['p']);
              result = result.reversed.toList();
          }
      } while (length);
      return result;
      }
}