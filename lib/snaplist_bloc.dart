import 'dart:async';

import 'package:snaplist/size_providers.dart';
import 'package:snaplist/snaplist_events.dart';

class SnapListBloc {
  final CardSizeProvider sizeProvider;
  final SeparatorSizeProvider separatorProvider;
  int _itemsCount;

  int _centerItemPosition = 0;
  int _nextItemPosition = -1;

  double _scrollOffset;
  double _startPosition;

  double _scrollProgress;

  ScrollDirection _direction = ScrollDirection.NONE;

  StreamController<StartEvent> _swipeStartController = StreamController();
  Sink<StartEvent> get swipeStartSink => _swipeStartController.sink;

  StreamController<UpdateEvent> _swipeUpdateController = StreamController();
  Sink<UpdateEvent> get swipeUpdateSink => _swipeUpdateController.sink;

  StreamController<EndEvent> _swipeEndController = StreamController();
  Sink<EndEvent> get swipeEndSink => _swipeEndController.sink;

  StreamController<SnipStartEvent> _snipStartController = StreamController();
  Stream<SnipStartEvent> get snipStartStream => _snipStartController.stream;

  StreamController<SnipUpdateEvent> _snipUpdateController = StreamController();
  Sink<SnipUpdateEvent> get snipUpdateSink => _snipUpdateController.sink;

  StreamController<SnipFinishEvent> _snipFinishController = StreamController();
  Sink<SnipFinishEvent> get snipFinishSink => _snipFinishController.sink;

  StreamController<PositionChangeEvent> _positionChangeController =
      StreamController();
  Stream<PositionChangeEvent> get positionStream =>
      _positionChangeController.stream;

  StreamController<OffsetEvent> _offsetController = StreamController();
  Stream<OffsetEvent> get offsetStream => _offsetController.stream;

  StreamController<int> _itemCountController = StreamController();
  Sink<int> get itemCountSink => _itemCountController.sink;

  StreamController<UiEvent> _uiController = StreamController();
  Stream<UiEvent> get uiStream => _uiController.stream;

  SnapListBloc({int itemsCount, this.sizeProvider, this.separatorProvider}) {
    _itemsCount = itemsCount ?? 0;

    _swipeStartController.stream.listen((event) {
      _direction = ScrollDirection.NONE;

      _scrollOffset = event.offset;
      _startPosition = event.position;

      _scrollProgress = 0.0;
    });

    _swipeUpdateController.stream.listen((event) {
      if (event.position < _startPosition) {
        _direction = ScrollDirection.RIGHT;
        _nextItemPosition = _centerItemPosition + 1;
      } else {
        _direction = ScrollDirection.LEFT;
        _nextItemPosition = _centerItemPosition - 1;
      }

      if (_nextItemPosition < 0 || _nextItemPosition >= itemsCount) {
        return;
      }

      _scrollOffset = _scrollOffset - event.delta;
      _scrollProgress = _calculateScrollProgress(event.position);
      _offsetController.add(OffsetEvent(_scrollOffset, _scrollProgress,
          _centerItemPosition, _nextItemPosition));

      _uiController.add(
          UiEvent(_centerItemPosition, _nextItemPosition, _scrollProgress));
    });

    _swipeEndController.stream.listen((event) {
      if (event.vector.dx.abs() <= 300.0) {
        _scrollProgress = 100 - _scrollProgress;
        _swipeNextAndCenter();
        _direction = ScrollDirection.NONE;
      }

      if (_direction != null &&
          _nextItemPosition >= 0 &&
          _nextItemPosition < _itemsCount) {
        _snipStartController.add(SnipStartEvent(
            _scrollOffset, _calculateTargetOffset(), _scrollProgress));
      }
    });

    _snipUpdateController.stream.listen((event) {
      _scrollProgress = event.progress;
      _scrollOffset = event.snip;

      _offsetController.add(OffsetEvent(_scrollOffset, _scrollProgress,
          _centerItemPosition, _nextItemPosition));
      _uiController.add(
          UiEvent(_centerItemPosition, _nextItemPosition, _scrollProgress));
    });

    _snipFinishController.stream.listen((event) {
      _centerItemPosition = _nextItemPosition.clamp(0, _itemsCount - 1);
      _nextItemPosition = -1;
      _scrollProgress = 0.0;

      _positionChangeController.add(PositionChangeEvent(_centerItemPosition));
    });

    _itemCountController.stream.listen((itemCount) {
      _itemsCount = itemsCount;

      if (_centerItemPosition >= _itemsCount - 1) {
        _centerItemPosition = _itemsCount - 1;
        _positionChangeController.add(PositionChangeEvent(_centerItemPosition));
      }
    });
  }

  _swipeNextAndCenter() {
    final tmp = _centerItemPosition;
    _nextItemPosition = tmp;
    _centerItemPosition = _nextItemPosition;
  }

  _calculateScrollProgress(double currentPosition) {
    final distance = (_startPosition - currentPosition).abs();
    return ((distance * 100) /
            sizeProvider(_centerItemPosition, _createBuilderData()).width)
        .clamp(0.0, 100.0);
  }

  double _calculateTargetOffset() {
    double result = 0.0;

    for (var i = 1; i <= _nextItemPosition; ++i) {
      double cardWidth = sizeProvider(
          i - 1,
          BuilderData(
            _centerItemPosition,
            _nextItemPosition,
            100.0,
          )).width;

      result += cardWidth;

      result += separatorProvider(i - 1, _createBuilderData()).width;
    }
    return result;
  }

  _createBuilderData() {
    return BuilderData(_centerItemPosition, _nextItemPosition, _scrollProgress);
  }

  void onSwipingFinished() {
    _centerItemPosition = _nextItemPosition;
    _nextItemPosition = -1;
  }

  void dispose() {
    _itemCountController.close();

    _swipeStartController.close();
    _swipeUpdateController.close();
    _swipeEndController.close();

    _snipStartController.close();
    _snipUpdateController.close();
    _snipFinishController.close();

    _positionChangeController.close();
    _offsetController.close();

    _uiController.close();
  }
}

enum ScrollDirection { RIGHT, NONE, LEFT }
