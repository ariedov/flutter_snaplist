library snaplist;

import 'package:flutter/widgets.dart';

class SnapList extends StatefulWidget {
  final CardSizeProvider sizeProvider;
  final CardBuilder builder;
  final double separatorWidth;
  final int count;

  final GestureDragStartCallback verticalStart;
  final GestureDragUpdateCallback verticalUpdate;
  final GestureDragEndCallback verticalEnd;

  final ScrollProgressUpdate progressUpdate;

  final EdgeInsets padding;

  SnapList({
    Key key,
    @required this.sizeProvider,
    @required this.builder,
    @required this.separatorWidth,
    @required this.count,
    this.padding,
    this.verticalStart,
    this.verticalUpdate,
    this.verticalEnd,
    this.progressUpdate,
  }) : super(key: key) {
    assert(this.sizeProvider != null);
    assert(this.builder != null);
    assert(this.separatorWidth != null);
    assert(this.count != null);
  }

  @override
  State<StatefulWidget> createState() => _SnapListState();
}

class _SnapListState extends State<SnapList> with TickerProviderStateMixin {
  GlobalKey _listKey = GlobalKey();
  ScrollController _controller = ScrollController();

  _ViewModel _viewModel = _ViewModel();

  AnimationController _snipController;
  Tween<double> _progressTween = Tween<double>();
  Tween<double> _snipTween = Tween<double>();

  @override
  void initState() {
    _snipController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300))
          ..addListener(() {
            setState(() {
              _viewModel.scrollProgress =
                  _progressTween.evaluate(_snipController);
              final snip = _snipTween.evaluate(_snipController);

              _controller.jumpTo(snip);

              _updateProgress();
            });
          })
          ..addStatusListener((status) {
            setState(() {
              if (status == AnimationStatus.completed) {
                _viewModel.centerItemPosition =
                    _viewModel.nextItemPosition.clamp(0, widget.count - 1);
                _viewModel.nextItemPosition = -1;
                _viewModel.scrollProgress = 0.0;

                _updateProgress();
              }
            });
          });

    super.initState();
  }

  @override
  void didUpdateWidget(SnapList oldWidget) {
    if (_viewModel.centerItemPosition >= widget.count - 1) {
      _viewModel.centerItemPosition = widget.count - 1;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (isAnimating) {
      return _buildList();
    }

    return GestureDetector(
      onVerticalDragStart: widget.verticalStart,
      onVerticalDragUpdate: widget.verticalUpdate,
      onVerticalDragEnd: widget.verticalEnd,
      onHorizontalDragStart: _onHorizontalStart,
      onHorizontalDragUpdate: _onHorizontalUpdate,
      onHorizontalDragEnd: _onHorizontalEnd,
      child: _buildList(),
    );
  }

  _buildList() {
    return ListView.separated(
        key: _listKey,
        padding: widget.padding,
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        controller: _controller,
        separatorBuilder: (context, index) {
          return SizedBox(
            width: widget.separatorWidth,
          );
        },
        itemBuilder: (context, index) {
          return Align(
            alignment: Alignment.center,
            child: widget.builder(
              context,
              _createBuilderData(index),
            ),
          );
        },
        itemCount: widget.count);
  }

  void _onHorizontalStart(DragStartDetails details) {
    _viewModel.scrollOffset = _controller.offset;
    _viewModel.scrollProgress = 0.0;

    _viewModel.dragStartPosition = details.globalPosition.dx;
  }

  void _onHorizontalUpdate(DragUpdateDetails details) {
    if (details.globalPosition.dx < _viewModel.dragStartPosition) {
      _viewModel.nextItemPosition = _viewModel.centerItemPosition + 1;
      _viewModel.direction = ScrollDirection.RIGHT;
    } else {
      _viewModel.nextItemPosition = _viewModel.centerItemPosition - 1;
      _viewModel.direction = ScrollDirection.LEFT;
    }

    if (_viewModel.nextItemPosition < 0 ||
        _viewModel.nextItemPosition >= widget.count) {
      return;
    }

    setState(() {
      _viewModel.scrollOffset = _viewModel.scrollOffset - details.delta.dx;
      _controller.jumpTo(_viewModel.scrollOffset);

      _viewModel.scrollProgress =
          _calculateScrollProgress(details.globalPosition.dx);

      _updateProgress();
    });
  }

  _calculateScrollProgress(double currentPosition) {
    final distance = (_viewModel.dragStartPosition - currentPosition).abs();
    return ((distance * 100) /
            widget
                .sizeProvider(_createBuilderData(_viewModel.centerItemPosition))
                .width)
        .clamp(0.0, 100);
  }

  _createBuilderData(int position) {
    return BuilderData(position, _viewModel.centerItemPosition,
        _viewModel.nextItemPosition, _viewModel.scrollProgress);
  }

  _updateProgress() {
    if (widget.progressUpdate != null) {
      widget.progressUpdate(_viewModel.scrollProgress,
          _viewModel.centerItemPosition, _viewModel.nextItemPosition);
    }
  }

  void _onHorizontalEnd(DragEndDetails details) {
    if (_viewModel.direction != null &&
        _viewModel.nextItemPosition >= 0 &&
        _viewModel.nextItemPosition < widget.count) {
      _snipTween =
          Tween(begin: _controller.offset, end: _calculateTargetOffset());

      _progressTween = Tween(begin: _viewModel.scrollProgress, end: 100.0);

      _snipController.forward(from: 0.0);
    }
  }

  double _calculateTargetOffset() {
    double result = 0.0;
    for (var i = 1; i <= _viewModel.nextItemPosition; ++i) {
      double cardWidth = widget
          .sizeProvider(BuilderData(
            i - 1,
            _viewModel.centerItemPosition,
            _viewModel.nextItemPosition,
            100.0,
          ))
          .width;

      result += cardWidth;

      result += widget.separatorWidth;
    }
    return result;
  }

  bool get isAnimating => _snipController.isAnimating;
}

class _ViewModel {
  double dragStartPosition;
  double scrollOffset;

  int centerItemPosition = 0;
  int nextItemPosition = -1;

  double scrollProgress = 0.0;

  ScrollDirection direction;
}

enum ScrollDirection { RIGHT, LEFT }

typedef Widget CardBuilder(
  BuildContext context,
  BuilderData data,
);

typedef Size CardSizeProvider(BuilderData data);

class BuilderData {
  final int current;
  final int center;
  final int next;
  final double progress;

  BuilderData(this.current, this.center, this.next, this.progress);
}

typedef double ScrollProgressUpdate(double progress, int center, int next);
