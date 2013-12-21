define([], function () {

  var Party = Class.extend({
    init: function (leaderID, membersIDs) {
      this._leader = globalGame.getPlayerByID(leaderID);
      this._members = {};
      this._membersCount = 0;
      this._capacity = 3;
      var players = globalGame.getPlayersByIDs(membersIDs);
      for (var x in players) {
        this.joined(players[x]);
      }
    },

    _add: function (player) {
      this._members[player.id] = player;
      player.party = this;
      this._membersCount++;
    },

    _remove: function (player) {
      delete this._members[player.id];
      player.party = null;
      this._membersCount--;
    },

    joined: function (player) {
      this._add(player);

      if (player != globalGame.player) {
        globalGame.client.notice("%s has joined the party.", player.name);
      }
    },

    left: function (player) {
      this._remove(player);

      if (player == globalGame.player) {
        globalGame.client.notice("You have left the party.");
      } else {
        globalGame.client.notice("%s has left the party.", player.name);
      }
    },

    kicked: function (kicker, kicked) {
      this._remove(kicked);

      if (kicked == globalGame.player) {
        globalGame.client.notice("You were kicked from the party by %s.", kicker.name);
        return;
      }

      globalGame.client.notice(
        "%s kicked %s from the party.",
        kicker.name,
        kicked.name
      );
    },

    setLeader: function (player) {
      this._leader = player;
      if (player == globalGame.player) {
        globalGame.client.notice("You are now the group leader.");
      } else {
        globalGame.client.notice("%s is now the group leader.", player.name);
      }
    },

    getLeader: function () {
      return this._leader;
    },

    getMembers: function () {
      return this._members;
    },

    isFull: function () {
      return this._membersCount == this._capacity;
    },

    isLeader: function (player) {
      return this._leader == player;
    },

    isMember: function (player) {
      return (player.id in this._members);
    }
  });

  return Party;
});
