import 'package:flutter/widgets.dart';

typedef Size CardSizeProvider(BuilderData data);
typedef Size SeparatorSizeProvider(BuilderData data);

class BuilderData {
  final int current;
  final int center;
  final int next;
  final double progress;

  BuilderData(this.current, this.center, this.next, this.progress);
}
