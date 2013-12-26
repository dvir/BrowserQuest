var cls = require("./lib/class"),
  Messages = require('./message'),
  Utils = require('./utils'),
  Formulas = require("./formulas"),
  Types = require("../../shared/js/gametypes");

module.exports = Party = Class.extend({
  init: function (leader, member) {
    this._leader = leader;
    this._members = {};
    this._membersCount = 0;
    this._capacity = 5;
    this._add(leader);
    this._add(member);
    leader.send(new Messages.PartyInitialJoin(this).serialize());
    member.send(new Messages.PartyInitialJoin(this).serialize());
  },

  get leader() {
    return this._leader;
  },

  set leader(newLeader) {
    this._leader = newLeader;
    this.broadcast(new Messages.PartyLeaderChange(newLeader).serialize());
  },

  get members() {
    return this._members;
  },

  /**
   * A silent party join
   */
  _add: function (entity) {
    if (this.isFull()) {
      return;
    }

    this._members[entity.id] = entity;
    entity.party = this;
    this._membersCount++;
  },

  /**
   * A silent party quit
   */
  _remove: function (entity) {
    delete this._members[entity.id];
    entity.party = null;
    this._membersCount--;

    if (this._membersCount == 0) {
      // group is empty and will be garbage collected sooner or later
      return;
    }

    // if the group has only one member left, disband it.
    if (this._membersCount == 1) {
      for (var x in this._members) {
        this.leave(this._members[x]);
        return;
      }
      return;
    }

    // else, we still have >= 2 members. we should check if the leader left
    // and if so grant it to the next member.
    if (this.leader == entity) {
      for (var x in this._members) {
        this.leader = this._members[x];
        return;
      }
    }
  },

  join: function (entity) {
    this._add(entity);

    this.broadcast(
      new Messages.PartyJoin(entity).serialize(),
      /* skip self */
      entity
    );
    entity.send(new Messages.PartyInitialJoin(this).serialize());
  },

  leave: function (entity) {
    this.broadcast(new Messages.PartyLeave(entity).serialize());
    this._remove(entity);
  },

  kick: function (entity) {
    this.broadcast(new Messages.PartyKick(this.leader, entity).serialize());
    this._remove(entity);
  },

  changeLeader: function (entity) {
    this.leader = entity;
  },

  broadcast: function (message, skipEntity) {
    for (var i in this._members) {
      if (skipEntity && skipEntity == this._members[i]) {
        continue;
      }
      this._members[i].send(message);
    }
  },

  getMembersIDs: function () {
    return Object.keys(this._members);
  },

  getMembers: function () {
    return this._members;
  },

  isFull: function () {
    return this._membersCount == this._capacity;
  },

  isLeader: function (player) {
    return player == this.leader;
  },

  isMember: function (player) {
    return (player.id in this._members);
  }
});
