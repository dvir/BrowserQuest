library position;

class Position {

  final int x;
  final int y;

  const Position(int this.x, int this.y);
  const Position.zero() : x = 0, y = 0;

  bool operator ==(Position other) => (this.x == other.x && this.y == other.y);

  String toString() => "($x, $y)";

  int get hashCode => (17 * this.x) + (37 * this.y); 
  
  Position incX() => new Position(this.x + 1, this.y);
  Position decX() => new Position(this.x - 1, this.y);
  Position incY() => new Position(this.x, this.y + 1);
  Position decY() => new Position(this.x, this.y - 1);
}

