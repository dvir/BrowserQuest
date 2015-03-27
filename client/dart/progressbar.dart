library progressbar;

import 'dart:html' hide Player;

import "base.dart";

abstract class ProgressBar extends Base {

  Element $container;
  Element $bar;
  Element $progress;

  ProgressBar(Element this.$container, Element this.$bar, Element this.$progress) {
    this.$container.style.display = 'none'; 
  }

  int getPercentage() {
    int total = this.getTotal();
    return total == 0 ? 0 : (this.getAmount() * 100 / total).floor();
  }

  bool shouldHide() {
    return false;
  }

  void update() {
    this.$container.style.display = this.shouldHide() ? 'none' : 'block';
    this.$progress.style.width = "${this.getPercentage()}%";
    this.$bar.innerHtml = "${this.getAmount()}/${this.getTotal()}";
  }

  int getAmount();
  int getTotal();
}
