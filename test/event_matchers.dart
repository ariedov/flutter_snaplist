import 'package:flutter_test/flutter_test.dart';
import 'package:snaplist/snaplist_events.dart';

class OffsetMatcher extends Matcher {
  final OffsetEvent expected;
  OffsetMatcher(this.expected);

  @override
  Description describe(Description description) =>
      description.add("did not match");

  @override
  bool matches(item, Map matchState) {
    OffsetEvent event = item;
    return expected.offset == event.offset &&
        expected.progress == event.progress &&
        expected.centerPosition == event.centerPosition &&
        expected.nextPosition == event.nextPosition;
  }
}

class SnipStartMatcher extends Matcher {
  final SnipStartEvent expected;
  SnipStartMatcher(this.expected);

  @override
  Description describe(Description description) =>
      description.add("did not match");

  @override
  bool matches(item, Map matchState) {
    SnipStartEvent event = item;
    return expected.offset == event.offset &&
        expected.progress == event.progress &&
        expected.targetOffset == event.targetOffset;
  }
}

class PositionChangeMatcher extends Matcher {
  final PositionChangeEvent expected;
  PositionChangeMatcher(this.expected);

  @override
  Description describe(Description description) => description.add("did not match");

  @override
  bool matches(item, Map matchState) {
    PositionChangeEvent event = item;
    return event.newPosition == expected.newPosition;
  }
}