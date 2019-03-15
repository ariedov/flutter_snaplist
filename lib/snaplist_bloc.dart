import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:snaplist/size_providers.dart';
import 'package:snaplist/snaplist_events.dart';

class SnapListBloc {
  int _itemsCount;
  CardSizeProvider _sizeProvider;
  SeparatorSizeProvider _separatorProvider;
  double _swipeVelocity;
  Axis _axis;

  int _centerItemPosition = 0;
  int _nextItemPosition = -1;

  double _scrollOffset;
  double _startPosition;

  double _scrollProgress;

  ScrollDirection _direction = ScrollDirection.NONE;
  bool get _isVertical => _axis == Axis.vertical;

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

  StreamController<int> _explicitPositionChangeController = StreamController();
  Sink<int> get explicitPositionChangeSink =>
      _explicitPositionChangeController.sink;

  StreamController<double> _explicitPositionChangeStream = StreamController();
  Stream<double> get explicitPositionChangeStream =>
      _explicitPositionChangeStream.stream;

  StreamController<OffsetEvent> _offsetController = StreamController();
  Stream<OffsetEvent> get offsetStream => _offsetController.stream;

  StreamController<int> _itemCountController = StreamController();
  Sink<int> get itemCountSink => _itemCountController.sink;

  StreamController<UiEvent> _uiController = StreamController();
  Stream<UiEvent> get uiStream => _uiController.stream;

  SnapListBloc(
      {int itemsCount, sizeProvider, separatorProvider, axis, swipeVelocity}) {
    initializeField(
      itemsCount: itemsCount,
      sizeProvider: sizeProvider,
      axis: axis,
      separatorProvider: separatorProvider,
      swipeVelocity: swipeVelocity,
    );

    _swipeStartController.stream.listen((event) {
      _direction = ScrollDirection.NONE;

      _scrollOffset = event.offset;
      _startPosition = event.position;

      _scrollProgress = 0.0;
    });

    _swipeUpdateController.stream.listen((event) {
      if (event.position < _startPosition) {
        _direction = _isVertical ? ScrollDirection.DOWN : ScrollDirection.RIGHT;
        _nextItemPosition = _centerItemPosition + 1;
      } else {
        _direction = _isVertical ? ScrollDirection.UP : ScrollDirection.LEFT;
        _nextItemPosition = _centerItemPosition - 1;
      }

      if (_nextItemPosition < 0 || _nextItemPosition >= _itemsCount) {
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
      if (_swipeVelocity != 0.0 &&
          _swipeVelocity >=
              (_isVertical ? event.vector.dy.abs() : event.vector.dx.abs()) &&
          _scrollProgress < 50) {
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

    _explicitPositionChangeController.stream.listen((position) {
      _nextItemPosition = position.clamp(0, _itemsCount - 1);
      _scrollProgress = 0.0;

      _explicitPositionChangeStream.add(_calculateTargetOffset());

      _centerItemPosition = _nextItemPosition;
      _nextItemPosition = -1;
    });

    _itemCountController.stream.listen((itemCount) {
      _itemsCount = itemCount;

      if (_centerItemPosition >= _itemsCount - 1) {
        _centerItemPosition = _itemsCount - 1;
        _positionChangeController.add(PositionChangeEvent(_centerItemPosition));
      }
    });
  }

  initializeField(
      {itemsCount, sizeProvider, separatorProvider, axis, swipeVelocity}) {
    _itemsCount = itemsCount ?? 0;
    _sizeProvider = sizeProvider;
    _separatorProvider = separatorProvider;
    _axis = axis;
    _swipeVelocity = swipeVelocity;
  }

  _swipeNextAndCenter() {
    final tmp = _centerItemPosition;
    _centerItemPosition = _nextItemPosition;
    _nextItemPosition = tmp;
  }

  _calculateScrollProgress(double currentPosition) {
    final distance = (_startPosition - currentPosition).abs();
    Size cardSize = _sizeProvider(_centerItemPosition, _createBuilderData());
    return ((distance * 100) / (_isVertical ? cardSize.height : cardSize.width))
        .clamp(0.0, 100.0);
  }

  double _calculateTargetOffset() {
    return calculateTargetOffset(
      _centerItemPosition, _nextItemPosition, _isVertical, _sizeProvider, _separatorProvider, _createBuilderData());
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

    _explicitPositionChangeController.close();
    _explicitPositionChangeStream.close();

    _uiController.close();
  }
}

double calculateTargetOffset(
    int currentItem,
    int calculateTo,
    bool isVertical,
    CardSizeProvider sizeProvider,
    SeparatorSizeProvider separatorSizeProvider,
    BuilderData builderData) {
  double result = 0.0;

  for (var i = 1; i <= calculateTo; ++i) {
    Size cardSize = sizeProvider(
        i - 1,
        BuilderData(
          currentItem,
          calculateTo,
          100.0,
        ));
    Size separatorSize = separatorSizeProvider(i - 1, builderData);

    if (isVertical) {
      result += cardSize.height;
      result += separatorSize.height;
    } else {
      result += cardSize.width;
      result += separatorSize.width;
    }
  }
  return result;
}

enum ScrollDirection { RIGHT, NONE, LEFT, UP, DOWN }
