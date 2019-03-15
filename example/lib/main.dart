import 'package:example/horizontal_explicit.dart';
import 'package:example/horziontal.dart';
import 'package:example/vertical.dart';
import 'package:flutter/material.dart';

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
  List<String> urls = [
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
    return DefaultTabController(
      child: Scaffold(
        appBar: AppBar(
            title: Text("Snaplist demo"),
            bottom: TabBar(tabs: <Widget>[
              Tab(
                text: "Horizontal",
              ),
              Tab(
                text: "Explicit",
              ),
              Tab(text: "Vertical")
            ])),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: <Widget>[            HorizontalTab(
              images: urls, loadMore: _loadMoreItems,
            ),
            HorizontalExplicitTab(
              images: urls, loadMore: _loadMoreItems,
            ),
            VerticalTab(images: urls, loadMore: _loadMoreItems)
          ],
        ),
      ),
      length: 3
    );
  }

  void _loadMoreItems() {
    setState(() {
      urls = new List.from(urls)..addAll(urls);
    });
  }
}
