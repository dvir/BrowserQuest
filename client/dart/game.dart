library game;

import "base.dart";
import "../shared/dart/gametypes.dart";

class Game extends Base {

  static List<List<int>> pathingGrid;
  static List<List<List<Entity>>> entityGrid;

  static bool drawTarget = false;
  static bool debugPathing = false;
  static Camera camera;

  static Animation targetAnimation;

  static Position selected; // selected grid position

  static bool started = false;
}
