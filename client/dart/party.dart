library party;

import "base.dart";
import "game.dart";
import "player.dart";

class Party extends Base {

  Player leader;
  Map<int, Player> members = new Map<int, Player>();
  int size = 0;
  int capacity = 3;

  Party(Player this.leader, List<Player> members) {
    members.forEach((Player member) {
      this.joined(member);
    });
  }

  void _add(Player player) {
    if (this.isMember(player)) {
      throw "${player.id} is already in the party.";
    }

    this.members.putIfAbsent(player.id, () => player);
    player.party = this;
    this.size++;
  }

  void _remove(Player player) {
    if (!this.isMember(player)) {
      throw "${player.id} is not in the party.";
    }

    this.members.remove(player.id);
    player.party = null;
    this.size--;
  }

  void joined(Player player) {
    this._add(player);

    if (player != Game.player) {
      Game.client.notice("${player.name} has joined the party.");
    }
  }

  void left(Player player) {
    this._remove(player);

    if (player == Game.player) {
      Game.client.notice("You have left the party.");
    } else {
      Game.client.notice("${player.name} has left the party.");
    }
  }

  void kicked(Player kicker, Player kicked) {
    this._remove(kicked);

    if (kicked == Game.player) {
      Game.client.notice("You were kicked from the party by ${kicker.name}.");
      return;
    }

    Game.client.notice("${kicker.name} kicked ${kicked.name} from the party.");
  }

  void setLeader(Player player) {
    this.leader = player;
    if (player == Game.player) {
      Game.client.notice("You are now the group leader.");
    } else {
      Game.client.notice("${player.name} is now the group leader.");
    }
  }

  Player getLeader() => this.leader;

  Map<int, Player> getMembers() => this.members;

  bool isFull() => (this.size == this.capacity); 

  bool isLeader(Player player) => (this.leader == player);

  bool isMember(Player player) => this.members.containsKey(player.id);
}
