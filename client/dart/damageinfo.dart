library damageinfo;

import "info.dart";
import "../shared/dart/gametypes.dart";

class DamageInfo extends Info {

  int duration = 1000;

  DamageInfo(String value, int x, int y): super(value, x, y);
}

class ReceivedDamageInfo extends DamageInfo {

  String fillColor = "rgb(255, 50, 50)";
  String strokeColor = "rgb(255, 180, 180)";
  Orientation orientation = Orientation.LEFT;

  ReceivedDamageInfo(String value, int x, int y): super(value, x, y);
}

class InflictedDamageInfo extends DamageInfo {

  String fillColor = "white";
  String strokeColor = "#373737";
  Orientation orientation = Orientation.DOWN;

  InflictedDamageInfo(String value, int x, int y): super(value, x, y);
}

class HealedDamageInfo extends DamageInfo {

  String fillColor = "rgb(80, 255, 80)";
  String strokeColor = "rgb(50, 120, 50)";
  Orientation orientation = Orientation.RIGHT;

  HealedDamageInfo(String value, int x, int y): super(value, x, y);
}
