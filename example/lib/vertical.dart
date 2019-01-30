import 'package:flutter/material.dart';
import 'package:snaplist/snaplist.dart';

class VerticalTab extends StatelessWidget {
  final List<String> images;
  final VoidCallback loadMore;

  const VerticalTab({Key key, this.images, this.loadMore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size cardSize = Size(250.0, 250.0);
    return SnapList(
      padding: EdgeInsets.only(
          top: (MediaQuery.of(context).size.height - 180 - cardSize.height) / 2),
      sizeProvider: (index, data) => cardSize,
      separatorProvider: (index, data) => Size(50.0, 50.0),
      positionUpdate: (int index){
        if(index==images.length-1){
          loadMore();
        }
      },
      builder: (context, index, data) {
        return ClipOval(
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
          ),
        );
      },
      count: images.length,
      axis: Axis.vertical,
    );
  }
}
