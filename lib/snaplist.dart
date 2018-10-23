library snaplist;

import 'package:flutter/widgets.dart';
import 'package:snaplist/size_providers.dart';
import 'package:snaplist/snaplist_bloc.dart';
import 'package:snaplist/snaplist_events.dart';

class SnapList extends StatefulWidget {
  final SeparatorSizeProvider separatorProvider;
  final CardSizeProvider sizeProvider;
  final CardBuilder builder;
  final int count;

  final ScrollProgressUpdate progressUpdate;
  final PositionUpdate positionUpdate;
  final ScrollStart scrollStart;

  final AnimationController snipAnimation;

  final EdgeInsets padding;
  final Alignment alignment;

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
    this.snipAnimation,
    this.alignment = Alignment.center,
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
      separatorProvider: widget.separatorProvider,
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

    _snipController = (widget.snipAnimation ??
        AnimationController(vsync: this, duration: Duration(milliseconds: 300)))
      ..addListener(() {
        setState(() {
          final scrollProgress = _progressTween.evaluate(_snipController);
          final snip = _snipTween.evaluate(_snipController);
          bloc.snipUpdateSink.add(SnipUpdateEvent(snip, scrollProgress));
        });
      })
      ..addStatusListener((status) {
        setState(() {
          if (status == AnimationStatus.completed) {
            bloc.snipFinishSink.add(SnipFinishEvent());
          }
        });
      });

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

        return GestureDetector(
          onHorizontalDragStart: _onHorizontalStart,
          onHorizontalDragUpdate: _onHorizontalUpdate,
          onHorizontalDragEnd: _onHorizontalEnd,
          child: _buildList(event.center, event.next, event.progress),
        );
      },
    );
  }

  _buildList(int center, int next, double progress) {
    return ListView.separated(
        key: _listKey,
        padding: widget.padding,
        scrollDirection: Axis.horizontal,
        physics: NeverScrollableScrollPhysics(),
        controller: _controller,
        separatorBuilder: (context, index) {
          return SizedBox(
            width: widget
                .separatorProvider(BuilderData(index, center, next, progress))
                .width,
          );
        },
        itemBuilder: (context, index) {
          final builderData = BuilderData(index, center, next, progress);
          final size = widget.sizeProvider(builderData);
          return Align(
            alignment: widget.alignment,
            child: SizedBox.fromSize(
              size: size,
              child: widget.builder(
                context,
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
    bloc.swipeEndSink.add(EndEvent());
  }

  bool get isAnimating => _snipController.isAnimating;
}

typedef Widget CardBuilder(
  BuildContext context,
  BuilderData data,
);

typedef ScrollStart();
typedef void ScrollProgressUpdate(double progress, int center, int next);
typedef void PositionUpdate(int center);
