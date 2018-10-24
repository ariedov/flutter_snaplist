import 'package:flutter/widgets.dart';

typedef Size CardSizeProvider(int position, BuilderData data);
typedef Size SeparatorSizeProvider(int position, BuilderData data);

class BuilderData {
  final int center;
  final int next;
  final double progress;

  BuilderData(this.center, this.next, this.progress);
}
