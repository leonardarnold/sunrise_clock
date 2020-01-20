/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunrise_clock/models/date_time_model.dart';
import 'package:flutter_clock_helper/model.dart';

/// SunriseWidget which includes a [CustomPainter]
///
/// It passes all relevant information to [SunrisePainter] to be able to draw
/// the background including semantics and the info.
/// It is also responsable of animating the [SunrisePainter] with the
/// [SunrisePainter.offsetAngle] property. The animation starts every new hour.
/// It listens to the [ClockModel] and [DateTimeModel] instance to get the
/// newest updates.
class SunriseWidget extends StatefulWidget {
  final ClockModel clockModel;
  final DateTimeModel dateTimeModel;

  SunriseWidget(
      {Key key, @required this.clockModel, @required this.dateTimeModel})
      : assert(clockModel != null),
        assert(dateTimeModel != null),
        super(key: key);

  @override
  _SunriseWidgetState createState() => _SunriseWidgetState();
}

class _SunriseWidgetState extends State<SunriseWidget>
    with SingleTickerProviderStateMixin {
  String _temperatureRange;
  String _location;
  String _dateString;
  String _hours;

  AnimationController _animationController;
  Animation<double> _piAnimation;

  /// initialize listeners, informations and animations.
  @override
  void initState() {
    super.initState();
    //init models
    widget.clockModel.addListener(_updateClockModel);
    widget.dateTimeModel.addListener(_updateDateTimeModel);
    //init info
    _updateClockModel();
    _updateDateTimeModel();

    //init animations
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 5));
    _piAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInOutQuint))
      ..addListener(() => setState(() {}));
  }

  /// remove listeners from models
  @override
  void dispose() {
    super.dispose();
    widget.clockModel.removeListener(_updateClockModel);
    widget.dateTimeModel.removeListener(_updateDateTimeModel);
  }

  /// If the widget got updated, this method checks if the model instances
  /// have changed to eventually resubscribe the listeners
  @override
  void didUpdateWidget(SunriseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    //resubscribe if model instance changes
    if (widget.dateTimeModel != oldWidget.dateTimeModel) {
      oldWidget.dateTimeModel.removeListener(_updateDateTimeModel);
      widget.dateTimeModel.addListener(_updateDateTimeModel);
    }
    //resubscribe if model instance changes
    if (widget.clockModel != oldWidget.clockModel) {
      oldWidget.clockModel.removeListener(_updateClockModel);
      widget.clockModel.addListener(_updateClockModel);
    }
  }

  /// This method gets called every time [widget.dateTimeModel] has changed.
  /// If the ticker to actualise the model is set to 1 second - it is called
  /// every second.
  /// If the hours have changed, it triggers the 'sunrise animation'
  /// It checks for relevant changes to trigger setState as every second
  /// setState is not necessary and definitely an overhead.
  void _updateDateTimeModel() {
    //animate if hours string changed
    if (_hours != widget.dateTimeModel.hours && _hours != null) {
      _animationController.forward(from: 0);
    }
    //if there was relevant changes call set state
    final bool shouldSetState = (_dateString != widget.dateTimeModel.date ||
        _hours != widget.dateTimeModel.hours);
    _dateString = widget.dateTimeModel.date;
    _hours = widget.dateTimeModel.hours;
    if (shouldSetState) setState(() {});
  }

  /// This method gets called if the [widget.clockModel] has changed.
  /// It checks if relevant information were affected and calls setState.
  /// If not - do nothing.
  void _updateClockModel() {
    bool shouldSetState = (_location != widget.clockModel.location ||
        _temperatureRange !=
            _getTemperatureRange(
                widget.clockModel.lowString, widget.clockModel.highString));
    _temperatureRange = _getTemperatureRange(
        widget.clockModel.lowString, widget.clockModel.highString);
    _location = widget.clockModel.location;
    if (shouldSetState) setState(() {});
  }

  /// temperature range formatter, since we won't touch ClockModel as it is
  /// given by google for the challenge and should not be modified
  String _getTemperatureRange(String low, String high) => "$low - $high";

  @override
  Widget build(BuildContext context) {
    print("_SunriseWidgetState build");
    return CustomPaint(
      foregroundPainter: SunrisePainter(
          color1: Colors.blue,
          color2: (Theme.of(context).brightness == Brightness.light)
              ? Colors.blue[200]
              : Colors.blue[900],
          sunriseCount: 7,
          infoText: "$_temperatureRange\n$_location",
          dateString: _dateString,
          infoTextStyle: GoogleFonts.share(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          offsetAngle: _piAnimation.value),
      child: SizedBox.expand(),
    );
  }
}

/// [SunrisePainter] paints the actual sunrise background.
/// It has several parameters which can modify the appearance.
/// [sunriseCount] describes the actual count of painted 'sunrays'.
/// [color1] is the color of every second ray.
/// [color2] is the color of every other ray.
/// [offsetAngle] is the angle of this painting. Used for animations.
/// [dateString] Current date displayed as String on the left bottom corner
/// [infoText] Info as (multiline) string displayed on the right bottom corner
/// [infoTextStyle] TextStyle of the displayed text.
/// [_textPadding] is by default 8.0 and is the padding between display border
/// and text
class SunrisePainter extends CustomPainter {
  final int sunriseCount;
  final Color color1;
  final Color color2;
  final num offsetAngle;
  final String dateString;
  final String infoText;
  final TextStyle infoTextStyle;
  final _textPadding = 8.0;

  SunrisePainter({
    sunriseCount = 8,
    this.color1 = Colors.red,
    this.color2 = Colors.white,
    this.offsetAngle = 0,
    this.infoText = "",
    this.dateString,
    this.infoTextStyle,
  })  : this.sunriseCount = sunriseCount * 2,
        assert(sunriseCount != null),
        assert(sunriseCount >= 2),
        assert(color1 != null),
        assert(color2 != null),
        assert(offsetAngle != null);

  @override
  void paint(Canvas canvas, Size size) {
    //paints sunrise background here
    _paintSunrise(canvas, size,
        color1: this.color1, color2: this.color2, blendMode: BlendMode.srcOver);
    //saving the layer here
    //actually this is why it won't work on flutter web right now:
    //https://github.com/flutter/flutter/issues/48417
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..blendMode = BlendMode.srcOver);
    //painting the info text
    _paintInfoText(canvas, size);
    //painting the date text
    _paintDateText(canvas, size);
    //painting the sunrise again but with inverted colors and BlendMode set to
    //BlendMode.srcIn which cuts the text out of the second sunrise
    _paintSunrise(canvas, size,
        color1: this.color2, color2: this.color1, blendMode: BlendMode.srcIn);

    canvas.restore();
  }

  /// Creates semantics for the painted text as they wouldn't have none
  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      final infoTxtLayout = _getTextPainter(infoText);
      final dateTxtLayout = _getTextPainter(dateString);

      return [
        CustomPainterSemantics(
          rect: Rect.fromLTWH(
              _infoTextOffset(size, infoTxtLayout).dx - _textPadding,
              _infoTextOffset(size, infoTxtLayout).dy - _textPadding,
              infoTxtLayout.width + _textPadding * 2,
              infoTxtLayout.height + _textPadding * 2),
          properties: SemanticsProperties(
            label: infoText,
            textDirection: TextDirection.ltr,
          ),
        ),
        CustomPainterSemantics(
          rect: Rect.fromLTWH(
              _dateTextOffset(size, dateTxtLayout).dx - _textPadding,
              _dateTextOffset(size, dateTxtLayout).dy - _textPadding,
              dateTxtLayout.width + _textPadding * 2,
              dateTxtLayout.height + _textPadding * 2),
          properties: SemanticsProperties(
            label: dateString,
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    };
  }

  /// calculates the offset of info text
  Offset _infoTextOffset(Size size, TextPainter textPainter) => Offset(
      size.width - textPainter.width - 16,
      size.height - textPainter.height - _textPadding);

  /// paints info text on canvas
  _paintInfoText(Canvas canvas, Size size) {
    var infoText = _getTextPainter(this.infoText);
    infoText.paint(canvas, _infoTextOffset(size, infoText));
  }

  /// calculates the offset of date text
  Offset _dateTextOffset(Size size, TextPainter textPainter) =>
      Offset(16, size.height - textPainter.height - _textPadding);

  /// paints date text on canvas
  _paintDateText(Canvas canvas, Size size) {
    var dateText = _getTextPainter(dateString);
    dateText.paint(canvas, _dateTextOffset(size, dateText));
  }

  /// returns a [TextPainter] with the correct [TextStyle] and creates it's
  /// layout
  TextPainter _getTextPainter(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: infoTextStyle,
      ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter;
  }

  /// Actual painting of the sunrise painting
  /// It's calculated on circle geometry starting from the middle.
  /// It only draws inside it's borders, not an actual circle.
  void _paintSunrise(Canvas canvas, Size size,
      {Color color1, Color color2, BlendMode blendMode = BlendMode.srcOver}) {
    Offset center = Offset(size.width / 2, size.height / 2);
    Size sizeFromCenter = Size(size.width - center.dx, size.height - center.dy);
    canvas.save();
    canvas.translate(center.dx, center.dy);

    //hypotenuse of width/2 and height/2 is the (minimum) radius
    final circleRadius = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2));

    final betweenAngle = 2 * pi / sunriseCount;
    var paint = Paint();
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;
    paint.blendMode = blendMode;

    //addVisualHelper(canvas, circleRadius);

    for (var i = 0; i < sunriseCount; i++) {
      var alpha = offsetAngle.toDouble() + betweenAngle * i;
      var color = (i % 2 == 0) ? color1 ?? this.color1 : color2 ?? this.color2;
      paint.color = color;
      var path = Path();
      var point1 = _limitLineToSize(
        sizeFromCenter,
        _circleFuncAlphaX(circleRadius, alpha),
        _circleFuncAlphaY(circleRadius, alpha),
      );

      var point2 = _limitLineToSize(
        sizeFromCenter,
        _circleFuncAlphaX(circleRadius, alpha + betweenAngle),
        _circleFuncAlphaY(circleRadius, alpha + betweenAngle),
      );

      path.lineTo(point1.dx, point1.dy);
      // fill the edge if online collides with the x line
      // and one with the y line, there is a space missing we must fill here
      if (point1.dx != point2.dx && point1.dy != point2.dy) {
        var dx;
        var dy;
        if (point1.dx.abs() == sizeFromCenter.width) {
          dx = point1.dx;
        } else {
          dx = point2.dx;
        }
        if (point1.dy.abs() == sizeFromCenter.height) {
          dy = point1.dy;
        } else {
          dy = point2.dy;
        }
        path.lineTo(dx, dy);
      }
      path.lineTo(point2.dx, point2.dy);

      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  ///
  ///   This method creates a line function for the point (outside the canvas
  ///   but on the circle)
  ///   checks for collision with the size borders
  ///   has to collide with one of them since
  ///   the radius was calculated that way
  ///    x1 : input x
  ///    y1 : input y
  ///    x2 : offset.x
  ///    y2 : offset.y
  ///    line:
  ///    f1(x) = ax + b
  ///    a = (x1-x2)/(y1-y2);
  ///    b = y2
  ///    size:
  ///    x3 = (-)(size.width - x2)
  ///    y3 = (-)(size.width - y2)
  ///    Collision func:
  ///    x = (x3|y3 - b) / a
  ///
  Offset _limitLineToSize(Size size, num x, num y,
      {Offset offset = Offset.zero}) {
    final a = (y - offset.dy) / (x - offset.dx);
    final b = offset.dy;
    //canvas border:
    var canvasBorderX1 = size.height - offset.dy;
    var canvasBorderY1 = size.width - offset.dx;

    var dx;
    var dy;

    if (x < 0) {
      canvasBorderY1 = -canvasBorderY1;
    }
    if (y < 0) canvasBorderX1 = -canvasBorderX1;

    var collisionBorderY = Offset(canvasBorderY1, a * canvasBorderY1 + b);
    var collisionBorderX = Offset((canvasBorderX1 - b) / a, canvasBorderX1);

    dx = collisionBorderY.dx;
    dy = collisionBorderY.dy;

    //euclid distance
    var distY = sqrt(pow(collisionBorderY.dx - offset.dx, 2) +
        pow(collisionBorderY.dy - offset.dy, 2));
    var distX = sqrt(pow(collisionBorderX.dx - offset.dx, 2) +
        pow(collisionBorderX.dy - offset.dy, 2));

    if (distX < distY) {
      dx = collisionBorderX.dx;
      dy = collisionBorderX.dy;
    } else {
      dx = collisionBorderY.dx;
      dy = collisionBorderY.dy;
    }
    return Offset(dx, dy);
  }

  /// helper function for the visual helper
  double _circleFuncY(num y, num r) {
    var result = sqrt(pow(r, 2) - pow(y, 2));
    //if(result.isNaN)
    //  result = sqrt(pow(r,2) - pow(x, 2));
    if (result.isNaN) result = 0;
    return result;
  }

  /// y1 and x1 are the center which is here always 0
  /// so we don't use it here
  /// y = y1 + radius * cos(alpha)
  /// x = x1 + radius * sin(alpha)
  /// [r] is the radius
  /// [a] is alpha
  double _circleFuncAlphaY(num r, num a) {
    var result = r * sin(a);
    return result;
  }

  /// same as [_circleFuncAlphaY] but with cos
  double _circleFuncAlphaX(num r, num a) {
    var result = r * cos(a);
    return result;
  }

  /// This method was used only for development purpose.
  /// It added a circle to help to visualize the calculations.
  /// Not used for production.
  _addVisualHelper(Canvas canvas, num radius) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    var p = Path();

    p.addOval(Rect.fromCircle(radius: radius, center: Offset.zero));
    canvas.drawPath(p, paint);

    paint..style = PaintingStyle.fill;
    paint..strokeWidth = 4.0;
    final List<Offset> points = [];
    for (var i = 0; i < 1000; i++) {
      points.add(Offset(i.toDouble(), _circleFuncY(i, radius)));
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  /// only repaint semantics if necessary
  @override
  bool shouldRebuildSemantics(SunrisePainter oldDelegate) {
    return (this.infoText != oldDelegate.infoText) ||
        (this.dateString != oldDelegate.dateString);
  }

  /// only repaint if sth has changed
  @override
  bool shouldRepaint(SunrisePainter oldDelegate) {
    return (this.offsetAngle != oldDelegate.offsetAngle) ||
        (this.infoText != oldDelegate.infoText) ||
        (this.dateString != oldDelegate.dateString) ||
        (this.color2 != oldDelegate.color2) ||
        (this.color1 != oldDelegate.color1);
  }
}
