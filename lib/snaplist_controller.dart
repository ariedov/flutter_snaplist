class SnaplistController {

  final int initialPosition;

  PositionChanged positionChanged;

  SnaplistController({
    this.initialPosition = 0
    });

  setPosition(int position) {
    if (positionChanged != null) {
      positionChanged(position);
    }
  }
}

typedef PositionChanged(int position);