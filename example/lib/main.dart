import 'package:flutter/material.dart';
import 'package:snaplist/snaplist.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Snaplist Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> urls = [
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/2uNW4WbgBXL25BAbXGLnLqX71Sw.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/lNkDYKmrVem1J0aAfCnQlJOCKnT.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/wrFpXMNBRj2PBiN4Z5kix51XaIZ.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/r6pPUVUKU5eIpYj4oEzidk5ZibB.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/x1txcDXkcM65gl7w20PwYSxAYah.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/ptSrT1JwZFWGhjSpYUtJaasQrh.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/wMq9kQXTeQCHUZOG4fAe5cAxyUA.jpg",
    "https://image.tmdb.org/t/p/w370_and_h556_bestv2/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg",
  ];

  @override
  Widget build(BuildContext context) {
    final Size cardSize = Size(300.0, 460.0);
    return Scaffold(
      body: SnapList(
        padding: EdgeInsets.only(
            left: (MediaQuery.of(context).size.width - cardSize.width) / 2),
        sizeProvider: (index, data) => cardSize,
        separatorProvider: (index, data) => Size(10.0, 10.0),
        builder: (context, index, data) {
          return ClipRRect(
            borderRadius: new BorderRadius.circular(16.0),
            child: Image.network(urls[index], fit: BoxFit.fill,),
          );
        },
        count: urls.length,
      ),
    );
  }
}
