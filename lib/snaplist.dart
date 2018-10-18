library snaplist;

import 'package:flutter/widgets.dart';

class SnapList extends StatefulWidget {
  final Size cardSize;
  final CardBuilder builder;
  final double separatorWidth;
  final int count;

  final EdgeInsets padding;

  SnapList({
    Key key,
    @required this.cardSize,
    @required this.builder,
    @required this.separatorWidth,
    @required this.count,
    this.padding,
  }) : super(key: key) {
    assert(this.cardSize != null);
    assert(this.builder != null);
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
            final progress = _progressTween.evaluate(_snipController);
            final snip = _snipTween.evaluate(_snipController);

            _controller.jumpTo(snip);
          })
          ..addStatusListener((status) {
            setState(() {
                _viewModel.centerItemPosition = _viewModel.nextItemPosition;
                _viewModel.nextItemPosition = -1;
                _viewModel.scrollProgress = 0.0;
              });
          });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isAnimating) {
      return _buildList();
    }

    return GestureDetector(
      onVerticalDragStart: _onVerticalStart,
      onVerticalDragUpdate: _onVerticalUpdate,
      onVerticalDragEnd: _onVerticalEnd,
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
              index,
              _viewModel.centerItemPosition,
              _viewModel.nextItemPosition,
            ),
          );
        },
        itemCount: widget.count);
  }

  void _onVerticalStart(DragStartDetails details) {}
  void _onVerticalUpdate(DragUpdateDetails details) {}
  void _onVerticalEnd(DragEndDetails details) {}

  void _onHorizontalStart(DragStartDetails details) {
    _viewModel.scrollOffset = _controller.offset;
    _viewModel.scrollProgress = 0.0;

    _viewModel.centerItemPosition = currentItemPosition;
    _viewModel.nextItemPosition = -1;

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
      final resultOffset = _viewModel.scrollOffset - details.delta.dx;
      _viewModel.scrollOffset = 0.0;
      if (resultOffset >= 0 && resultOffset <= widget.count * cardWidth) {
        _viewModel.scrollOffset = resultOffset;
      }
      _controller.jumpTo(_viewModel.scrollOffset);

      _viewModel.scrollProgress =
          _calculateScrollProgress(details.globalPosition.dx);
    });
  }

  _calculateScrollProgress(double currentPosition) {
    final distance = (_viewModel.dragStartPosition - currentPosition).abs();
    return ((distance * 100) / cardWidth).clamp(0.0, 100);
  }

  void _onHorizontalEnd(DragEndDetails details) {
    if (_viewModel.direction != null &&
        _viewModel.nextItemPosition >= 0 &&
        _viewModel.nextItemPosition < widget.count) {
      _snipTween = Tween(
          begin: _controller.offset,
          end: (_viewModel.nextItemPosition * cardWidth));

      _progressTween = Tween(begin: _viewModel.scrollProgress, end: 100.0);

      _snipController.forward(from: 0.0);
    }
  }

  bool get isAnimating => _snipController.isAnimating;
  int get currentItemPosition => (_controller.offset) ~/ cardWidth;
  double get cardWidth => widget.cardSize.width + widget.separatorWidth;
}

class _ViewModel {
  double dragStartPosition;
  double scrollOffset;

  int centerItemPosition;
  int nextItemPosition;

  double scrollProgress;

  ScrollDirection direction;
}

enum ScrollDirection { RIGHT, LEFT }

typedef Widget CardBuilder(
  BuildContext context,
  int position,
  int centerPosition,
  int nextPosition,
);
