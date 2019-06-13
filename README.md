[![awesome flutter](https://img.shields.io/badge/Awesome-Flutter-blue.svg?longCache=true&style=flat-square)](https://stackoverflow.com/questions/tagged/flutter?sort=votes)
[![pub package](https://img.shields.io/pub/v/snaplist.svg)](https://pub.dartlang.org/packages/snaplist)

# snaplist

A small cozy library that allows you to make snappable list views.

**Issues and Pull Requests are really appreciated!**

Snaplist supports different and even dynamically sized children to be listed and correctly snapped.

## Showcase

![Showscase gif](https://media.giphy.com/media/27bTHalyweVoc2psS2/giphy.gif)

## Include to your project

In your `pubspec.yaml` root add:

```yaml
dependencies:
  snaplist: ^0.1.8
```

## Include

The library does provide `StatefulWidget` which is called `SnapList`.

Include the widget like this:
`import 'package:snaplist/snaplist.dart';`

## Usage

Use it as you'd use any widget:

```dart
Widget build(BuildContext context) {
  return SnapList(
    sizeProvider: (index, data) => Size(100.0, 100.0),
    separatorProvider: (index, data) => Size(10.0, 10.0),
    builder: (context, index, data) => SizedBox(),
    count: 1,
  );
}
```

Snaplist uses gesture detection for swiping the list, so, please, be sure that the gestures you apply to the widgets inside are not overlapping for best user experience.

## Properties

There are 4 required fields:

- `sizeProvider` is a provider of each widget size. The library will wrap each built widget to a sized box of specified size. This is required so snapping calculations will work correctly.
- `separatorProvider` is similar to `sizeProvider`, but this size will be used to build the list separators.
- `builder` works like a regular `Flutter` builder all of us are familiar with. It will pass you the context, current item index and some additional data.
- `count` - Children count as in a `ListView`.

The `data` which is provided to each provider and the builder is a combination of three fields:

- `center` - is the position which is now displayed and referenced as the center widget.
- `next` - is the position which the user is scrolling to. It is `-1` if idle.
- `progress` - is the scroll and snip progress. The values are from `0` to `100`.

Snaplist defaults to horizontal scrolling. You can set `axis` to Axis.vertical for vertical scrolling.
