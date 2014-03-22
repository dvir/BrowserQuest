library npcs;

import "npc.dart";
import "../shared/dart/gametypes.dart";

class Guard extends Npc {

  Guard(int id): super(id, Entities.GUARD, "<Guard />");
}

class King extends Npc {

  King(int id): super(id, Entities.KING, "King");
}

class Agent extends Npc {

  Agent(int id): super(id, Entities.AGENT, "Agent Smith");
}

class Rick extends Npc {

  Rick(int id): super(id, Entities.RICK, "Rick");
}

class VillageGirl extends Npc {

  VillageGirl(int id): super(id, Entities.VILLAGEGIRL, "Village Girl");
}

class Villager extends Npc {

  Villager(int id): super(id, Entities.VILLAGER, "Villager");
}

class Coder extends Npc {

  Coder(int id): super(id, Entities.CODER, "Coder");
}

class Scientist extends Npc {

  Scientist(int id): super(id, Entities.SCIENTIST, "Scientist");
}

class Nyan extends Npc {

  Nyan(int id): super(id, Entities.NYAN, "Nyan Cat");
}

class Sorcerer extends Npc {

  Sorcerer(int id): super(id, Entities.SORCERER, "Sorcerer");
}

class Priest extends Npc {

  Priest(int id): super(id, Entities.PRIEST, "Priest");
}

class Surfer extends Npc {

  Surfer(int id): super(id, Entities.BEACHNPC, "Surfer");
}

class ForestKeeper extends Npc {

  ForestKeeper(int id): super(id, Entities.FORESTNPC, "Forest Keeper");
}

class Traveler extends Npc {

  Traveler(int id): super(id, Entities.DESERTNPC, "Traveler");
}

class Geologist extends Npc {

  Geologist(int id): super(id, Entities.LAVANPC, "Geologist");
}

class Octocat extends Npc {

  Octocat(int id): super(id, Entities.OCTOCAT, "Octocat");
}
