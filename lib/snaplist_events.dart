
import 'dart:ui';

class StartEvent {
  final double offset;
  final double position;

  StartEvent(this.offset, this.position);
}
class UpdateEvent {
  final double position;
  final double delta;

  UpdateEvent(this.position, this.delta);
}
class EndEvent {
  final Offset vector;

  EndEvent(this.vector);
}

class SnipStartEvent {
  final double offset;
  final double targetOffset;
  final double progress;

  SnipStartEvent(this.offset, this.targetOffset, this.progress);
}
class SnipUpdateEvent {
  final double snip;
  final double progress;

  SnipUpdateEvent(this.snip, this.progress);
}
class SnipFinishEvent {}

class PositionChangeEvent {
  final newPosition;

  PositionChangeEvent(this.newPosition);
}

class OffsetEvent {
  final double offset;
  final double progress;
  final int centerPosition;
  final int nextPosition;

  OffsetEvent(
      this.offset, this.progress, this.centerPosition, this.nextPosition);
}

class UiEvent {
  final int center;
  final int next;
  final double progress;

  UiEvent(this.center, this.next, this.progress);
}