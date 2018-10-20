import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:snaplist/snaplist_bloc.dart';
import 'package:snaplist/snaplist_events.dart';

import 'event_matchers.dart';

void main() {
  test("full scroll test", () {
    final bloc = SnapListBloc(
        itemsCount: 10,
        separatorProvider: (data) => Size(10.0, 10.0),
        sizeProvider: (data) => Size(50.0, 50.0));

    expect(bloc.offsetStream,
        emits(OffsetMatcher(OffsetEvent(-10.0, 40.0, 0, 1))));

    expect(bloc.snipStartStream,
        emits(SnipStartMatcher(SnipStartEvent(-10.0, 60.0, 40.0))));

    expect(bloc.positionStream,
        emits(PositionChangeMatcher(PositionChangeEvent(1))));

    bloc.swipeStartSink.add(StartEvent(0.0, 50.0));
    bloc.swipeUpdateSink.add(UpdateEvent(30.0, 10.0));
    bloc.swipeEndSink.add(EndEvent());

    bloc.snipFinishSink.add(SnipFinishEvent());
  });
}
