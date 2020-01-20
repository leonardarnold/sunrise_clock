/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunrise_clock/utils/weather_utils.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:sunrise_clock/models/date_time_model.dart';

/// displays the temperature, weather icon
/// and eventually AM/PM label if [ClockModel.is24HourFormat] is set to false
/// animates changes
class TemperatureWidget extends StatefulWidget {
  final DateTimeModel dateTimeModel;
  final ClockModel clockModel;

  TemperatureWidget(
      {@required this.dateTimeModel, @required this.clockModel, Key key})
      : assert(dateTimeModel != null),
        assert(clockModel != null),
        super(key: key);

  @override
  _TemperatureWidgetState createState() => _TemperatureWidgetState();
}

class _TemperatureWidgetState extends State<TemperatureWidget>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _animationController;
  String _temperature;
  String _condition;
  String _amPmMarker;
  bool _is24HourFormat;
  Widget _child;
  double _fontSize = 16;

  /// subscribe to models, initialize values and animations
  @override
  void initState() {
    super.initState();
    widget.clockModel.addListener(_updateModel);
    widget.dateTimeModel.addListener(_updateModel);
    _updateInfo();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    _animation = Tween<double>(begin: 0, end: pi / 2).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInQuad))
      ..addListener(() => setState(() {}));
    //update info if it is not visible [_animation.value] == pi/2
    _animationController.addListener(() {
      if (_animation.value == pi / 2) _updateInfo();
    });
  }

  /// unsubscribe models
  @override
  void dispose() {
    super.dispose();
    widget.clockModel.removeListener(_updateModel);
    widget.dateTimeModel.removeListener(_updateModel);
  }

  /// resubscribe if there are new model instances
  @override
  void didUpdateWidget(TemperatureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateTimeModel != oldWidget.dateTimeModel) {
      oldWidget.dateTimeModel.removeListener(_updateModel);
      widget.dateTimeModel.addListener(_updateModel);
    }
    if (widget.clockModel != oldWidget.clockModel) {
      oldWidget.clockModel.removeListener(_updateModel);
      widget.clockModel.addListener(_updateModel);
    }
  }

  /// calculate FontSize depending on layout width
  double _calculateFontSize(double width) => width / 12;

  /// if relevant changes happened in [ClockModel] animate them and update
  /// the changes in the ui via the added AnimationController listener
  void _updateModel() {
    if (_condition != widget.clockModel.weatherString ||
        _temperature != widget.clockModel.temperatureString ||
        _amPmMarker != widget.dateTimeModel.amPm ||
        _is24HourFormat != widget.clockModel.is24HourFormat) {
      if (!_animationController.isAnimating)
        _animationController.forward(from: 0).then((_) {
          _animationController.animateBack(0);
        });
    }
  }

  /// update info on ui and update the cached [_child]
  void _updateInfo() => setState(() {
        _temperature = widget.clockModel.temperatureString;
        _condition = widget.clockModel.weatherString;
        _amPmMarker = widget.dateTimeModel.amPm;
        _is24HourFormat = widget.clockModel.is24HourFormat;
        _child = _getChild(update: true);
      });

  /// Creates the child widget
  /// if [update] == false it returns the already cached child
  /// if [update] == true it recreates the child with eventually new information
  ///
  ///
  /// This technique avoid recreating the child all the time the build function
  /// runs. It's running often due to the animation.
  ///
  /// has to run at least once with [update] == true
  Widget _getChild({bool update = false}) {
    if (!update) return _child;

    return _child = Row(
      children: <Widget>[
        Expanded(
          child: Container(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Semantics(
              label: _condition,
              child: ExcludeSemantics(
                child: WeatherUtils.getIcon(
                  WeatherUtils.getWeatherConditionFromString(_condition),
                  size: _fontSize - 4,
                ),
              ),
            ),
            SizedBox(
              width: 4.0,
            ),
            Text(
              _temperature,
              style: GoogleFonts.share(
                textStyle: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: (!_is24HourFormat && _amPmMarker != null)
              ? Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    _amPmMarker,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.share(
                      textStyle: TextStyle(
                        fontSize: _fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Container(),
        ),
      ],
    );
  }

  /// builds the ui with the cached child and dynamic FontSize
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      bool updateChild = false;
      var newFontSize = _calculateFontSize(constraints.maxWidth);
      if (_fontSize != newFontSize) {
        _fontSize = newFontSize;
        updateChild = true;
      }

      return Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0001)
          ..rotateY(0)
          ..rotateX(_animation.value),
        alignment: FractionalOffset.center,
        child: _getChild(update: updateChild),
      );
    });
  }
}
