library position;

class Position {

  final int x;
  final int y;

  const Position(int this.x, int this.y);
  const Position.zero() : x = 0, y = 0;

  bool operator ==(Position other) => (this.x == other.x && this.y == other.y);

  String toString() => "($x, $y)";
}

