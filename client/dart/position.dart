library position;

class Position {

  final int x;
  final int y;

  const Position(int this.x, int this.y);

  bool operator ==(Position other) {
    return (this.x == other.x && this.y == other.y);
 }
}

