import 'package:flutter/material.dart';
import 'package:snaplist/snaplist.dart';

class HorizontalTab extends StatelessWidget {
  final List<String> images;
  final VoidCallback loadMore;

  const HorizontalTab({Key key, this.images, this.loadMore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size cardSize = Size(300.0, 460.0);
    return SnapList(
      padding: EdgeInsets.only(
          left: (MediaQuery.of(context).size.width - cardSize.width) / 2),
      sizeProvider: (index, data) => cardSize,
      separatorProvider: (index, data) => Size(10.0, 10.0),
      positionUpdate: (int index) {
        if (index == images.length - 1) {
          loadMore();
        }
      },
      builder: (context, index, data) {
        return ClipRRect(
          borderRadius: new BorderRadius.circular(16.0),
          child: Image.network(
            images[index],
            fit: BoxFit.fill,
          ),
        );
      },
      count: images.length,
    );
  }
}
