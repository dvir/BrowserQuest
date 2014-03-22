library checkpoint;

import "area.dart";

class Checkpoint extends Area {

  int id;

  Checkpoint(
    int this.id, 
    int x, 
    int y, 
    int width, 
    int height, 
    [String musicName]
  ): super(x, y, width, height, musicName);
}

