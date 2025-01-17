library infomanager;

import "dart:collection";

import "base.dart";
import "info.dart";

class InfoManager extends Base {

  HashSet<Info> infos = new HashSet.identity();

  void addInfo(Info info) {
    infos.add(info);
    info.on("Destroy", () {
      this.infos.remove(info);
    });
    info.init();
  }
  
  void forEachInfo(void callback(Info info)) {
    HashSet<Info> infos = new HashSet.from(this.infos);
    infos.forEach(callback);
  }

  void update(num time) {
    this.forEachInfo((Info info) {
      info.update(time);
    });
  }
}
