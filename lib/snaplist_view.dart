import 'package:flutter/widgets.dart';
import 'package:snaplist/size_providers.dart';
import 'package:snaplist/snaplist_bloc.dart';
import 'package:snaplist/snaplist_controller.dart';
import 'package:snaplist/snaplist_events.dart';

class SnapList extends StatefulWidget {
  final SeparatorSizeProvider separatorProvider;
  final CardSizeProvider sizeProvider;
  final CardBuilder builder;
  final int count;

  final ScrollProgressUpdate progressUpdate;
  final PositionUpdate positionUpdate;
  final ScrollStart scrollStart;
  final Axis axis;

  final Duration snipDuration;
  final Curve snipCurve;

  final EdgeInsets padding;
  final Alignment alignment;
  final double swipeVelocity;

  final SnaplistController snaplistController;

  SnapList({
    Key key,
    @required this.sizeProvider,
    @required this.builder,
    @required this.separatorProvider,
    @required this.count,
    this.padding,
    this.progressUpdate,
    this.positionUpdate,
    this.scrollStart,
    this.axis = Axis.horizontal,
    this.snipDuration,
    this.snipCurve,
    this.alignment = Alignment.center,
    this.swipeVelocity = 0.0,
    this.snaplistController,
  }) : super(key: key) {
    assert(this.sizeProvider != null);
    assert(this.builder != null);
    assert(this.separatorProvider != null);
    assert(this.count != null);
  }

  @override
  State<StatefulWidget> createState() => _SnapListState();
}

class _SnapListState extends State<SnapList> with TickerProviderStateMixin {
  GlobalKey _listKey = GlobalKey();
  ScrollController _controller = ScrollController();

  SnapListBloc bloc;

  AnimationController _snipController;
  Tween<double> _progressTween = Tween<double>();
  Tween<double> _snipTween = Tween<double>();

  @override
  void initState() {
    bloc = SnapListBloc(
      itemsCount: widget.count,
      sizeProvider: widget.sizeProvider,
      axis: widget.axis,
      separatorProvider: widget.separatorProvider,
      swipeVelocity: widget.swipeVelocity
    );

    bloc.offsetStream.listen((event) {
      _controller.jumpTo(event.offset);
      _updateProgress(event.progress, event.centerPosition, event.nextPosition);
    });

    bloc.positionStream.listen((event) {
      _updatePosition(event.newPosition);
    });

    bloc.snipStartStream.listen((event) {
      _snipTween = Tween(begin: event.offset, end: event.targetOffset);
      _progressTween = Tween(begin: event.progress, end: 100.0);

      _snipController.forward(from: 0.0);
    });

    bloc.explicitPositionChangeStream.listen((offset) {
      print("new offset: $offset");
      _controller.jumpTo(offset);
    });

    _snipController = AnimationController(
        vsync: this,
        duration: widget.snipDuration ?? Duration(milliseconds: 300))
      ..addListener(() {
        Animation resultAnimation = _snipController;
        if (widget.snipCurve != null) {
          resultAnimation =              CurvedAnimation(parent: _snipController, curve: widget.snipCurve);
        }
        final scrollProgress = _progressTween.evaluate(resultAnimation);
        final snip = _snipTween.evaluate(resultAnimation);
        bloc.snipUpdateSink.add(SnipUpdateEvent(snip, scrollProgress));
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          bloc.snipFinishSink.add(SnipFinishEvent());
        }
      });

    widget.snaplistController?.positionChanged = (position) {
      bloc.explicitPositionChangeSink.add(position);
    };

    if (widget.snaplistController?.initialPosition != null) {
      bloc.explicitPositionChangeSink.add(widget.snaplistController.initialPosition);
    }

    super.initState();
  }

  _updateProgress(
      double progress, int centerItemPosition, int nextItemPosition) {
    if (widget.progressUpdate != null) {
      widget.progressUpdate(progress, centerItemPosition, nextItemPosition);
    }
  }

  _updatePosition(int newPosition) {
    if (widget.positionUpdate != null) {
      widget.positionUpdate(newPosition);
    }
  }

  @override
  void didUpdateWidget(SnapList oldWidget) {
    bloc.itemCountSink.add(widget.count);

    super.didUpdateWidget(oldWidget);
    bloc.initializeField(
      itemsCount: widget.count,
      sizeProvider: widget.sizeProvider,
      axis: widget.axis,
      separatorProvider: widget.separatorProvider,
      swipeVelocity: widget.swipeVelocity,
    );

    widget.snaplistController?.positionChanged = (position) {
      bloc.explicitPositionChangeSink.add(position);
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UiEvent>(
      initialData: UiEvent(0, -1, 0.0),
      stream: bloc.uiStream,
      builder: (context, snapshot) {
        UiEvent event = snapshot.data;

        if (isAnimating) {
          return _buildList(event.center, event.next, event.progress);
        }
        if (widget.axis == Axis.vertical) {
          return GestureDetector(
            onVerticalDragStart: _onVerticalStart,
            onVerticalDragUpdate: _onVerticalUpdate,
            onVerticalDragEnd: _onVerticalEnd,
            child: _buildList(event.center, event.next, event.progress),
          );
        } else {
          return GestureDetector(
            onHorizontalDragStart: _onHorizontalStart,
            onHorizontalDragUpdate: _onHorizontalUpdate,
            onHorizontalDragEnd: _onHorizontalEnd,
            child: _buildList(event.center, event.next, event.progress),
          );
        }
      },
    );
  }

  _buildList(int center, int next, double progress) {
    return ListView.separated(
        key: _listKey,
        padding: widget.padding,
        scrollDirection: widget.axis,
        physics: NeverScrollableScrollPhysics(),
        controller: _controller,
        separatorBuilder: (context, index) {
          if (widget.axis == Axis.vertical) {
            return SizedBox(
              height: widget
                  .separatorProvider(index, BuilderData(center, next, progress))
                  .height,
            );
          } else {
            return SizedBox(
              width: widget
                  .separatorProvider(index, BuilderData(center, next, progress))
                  .width,
            );
          }
        },
        itemBuilder: (context, index) {
          final builderData = BuilderData(center, next, progress);
          final size = widget.sizeProvider(index, builderData);
          return Align(
            alignment: widget.alignment,
            child: SizedBox.fromSize(
              size: size,
              child: widget.builder(
                context,
                index,
                builderData,
              ),
            ),
          );
        },
        itemCount: widget.count);
  }

  @override
  void dispose() {
    bloc.dispose();
    _controller.dispose();
    _snipController.dispose();
    super.dispose();
  }

  void _onHorizontalStart(DragStartDetails details) {
    bloc.swipeStartSink
        .add(StartEvent(_controller.offset, details.globalPosition.dx));

    if (widget.scrollStart != null) {
      widget.scrollStart();
    }
  }

  void _onHorizontalUpdate(DragUpdateDetails details) {
    bloc.swipeUpdateSink
        .add(UpdateEvent(details.globalPosition.dx, details.delta.dx));
  }

  void _onHorizontalEnd(DragEndDetails details) {
    bloc.swipeEndSink.add(EndEvent(details.velocity.pixelsPerSecond));
  }

  void _onVerticalStart(DragStartDetails details) {
    bloc.swipeStartSink
        .add(StartEvent(_controller.offset, details.globalPosition.dy));

    if (widget.scrollStart != null) {
      widget.scrollStart();
    }
  }

  void _onVerticalUpdate(DragUpdateDetails details) {
    bloc.swipeUpdateSink
        .add(UpdateEvent(details.globalPosition.dy, details.delta.dy));
  }

  void _onVerticalEnd(DragEndDetails details) {
    bloc.swipeEndSink.add(EndEvent(details.velocity.pixelsPerSecond));
  }

  bool get isAnimating => _snipController.isAnimating;
}

typedef Widget CardBuilder(
  BuildContext context,
  int position,
  BuilderData data,
);

typedef ScrollStart();
typedef void ScrollProgressUpdate(double progress, int center, int next);
typedef void PositionUpdate(int center);
