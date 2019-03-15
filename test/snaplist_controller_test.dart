import 'package:snaplist/snaplist_controller.dart';
import 'package:test_api/test_api.dart';

void main() {
  test("position change test", () {
    var position;

    final controller = SnaplistController();
    controller.positionChanged = (newPosition) => {
      position = newPosition
    };

    controller.setPosition(1);

    expect(position, 1);
  });

  test("position change test multiple times", () {
    var position = [];

    final controller = SnaplistController();
    controller.positionChanged = (newPosition) => {
      position.add(newPosition)
    };

    controller.setPosition(1);
    controller.setPosition(2);

    expect(position.length, 2);
    expect(position[0], 1);
    expect(position[1], 2);
  });
}
