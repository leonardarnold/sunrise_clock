/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sunrise_clock/sunrise_clock.dart';
import 'package:sunrise_clock/models/date_time_model.dart';
import 'package:flutter_clock_helper/model.dart';

/// displays the time and animate changes
class TimeNumbersWidget extends StatefulWidget {
  final DateTimeModel dateTimeModel;
  final ClockModel clockModel;

  final double borderWidth;

  const TimeNumbersWidget(
      {Key key,
      @required this.dateTimeModel,
      @required this.clockModel,
      @required this.borderWidth})
      : assert(dateTimeModel != null),
        assert(clockModel != null),
        assert(borderWidth != null),
        super(key: key);

  @override
  _TimeNumbersWidgetState createState() => _TimeNumbersWidgetState();
}

class _TimeNumbersWidgetState extends State<TimeNumbersWidget> {
  String _hours;
  String _minutes;
  bool _is24HourFormat;

  /// subscribe to models
  @override
  void initState() {
    super.initState();
    widget.dateTimeModel.addListener(_updateTimeModel);
    widget.clockModel.addListener(_updateClockModel);
    _updateTimeModel();
    _updateClockModel();
  }

  /// resubscribe if models have changed
  @override
  void didUpdateWidget(TimeNumbersWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateTimeModel != oldWidget.dateTimeModel) {
      oldWidget.dateTimeModel.removeListener(_updateTimeModel);
      widget.dateTimeModel.addListener(_updateTimeModel);
    }
    if (widget.clockModel != oldWidget.clockModel) {
      oldWidget.clockModel.removeListener(_updateClockModel);
      widget.clockModel.addListener(_updateClockModel);
    }
  }

  /// unsubscribe to models
  @override
  void dispose() {
    widget.dateTimeModel.removeListener(_updateClockModel);
    widget.clockModel.removeListener(_updateClockModel);
    super.dispose();
  }

  /// update is24HourFormat in [DateTimeModel] it has changed in
  /// [ClockModel]
  /// call only setState if necessary
  _updateClockModel() {
    final bool shouldSetState =
        (_is24HourFormat != widget.clockModel.is24HourFormat);
    _is24HourFormat = widget.clockModel.is24HourFormat;
    //hooking here ClockModel to DateTimeModel
    widget.dateTimeModel.is24HourFormat = _is24HourFormat;
    if (shouldSetState) setState(() {});
  }

  /// update time but call setState only if it's relevant for the ui
  /// (remember ticker is ticking every second)
  _updateTimeModel() {
    final bool shouldSetState = (_hours != widget.dateTimeModel.hours ||
        _minutes != widget.dateTimeModel.minutes);
    _hours = widget.dateTimeModel.hours;
    _minutes = widget.dateTimeModel.minutes;
    if (shouldSetState) setState(() {});
  }

  /// building the ui and overriding the auto created semantics for better
  /// accessibility
  @override
  Widget build(BuildContext context) {
    return Semantics(
      //it is formatted to be read like a clock
      label: "${widget.dateTimeModel.hours}:${widget.dateTimeModel.minutes}",
      //exclude all auto generated semantics for the children
      child: ExcludeSemantics(
        child: Stack(
          children: <Widget>[
            Row(children: <Widget>[
              Expanded(
                child: TimeNumberWidget(_hours),
              ),
              Expanded(
                child: TimeNumberWidget(_minutes),
              ),
            ]),
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    width: widget.borderWidth - 2,
                    color: (Theme.of(context).brightness == Brightness.light)
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// single widget for hour or minute
/// animate if change has happened
class TimeNumberWidget extends StatefulWidget {
  final String timeString;

  TimeNumberWidget(
    this.timeString, {
    Key key,
  })  : assert(timeString != null),
        super(key: key);

  @override
  _TimeNumberWidgetState createState() => _TimeNumberWidgetState();
}

class _TimeNumberWidgetState extends State<TimeNumberWidget>
    with SingleTickerProviderStateMixin {
  Animation<double> _animation;
  AnimationController _animationController;
  String _timeString;
  double _fontSize = 24;
  Widget _child;

  /// initialize the animations
  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    _animation = Tween<double>(begin: 0, end: pi / 2).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInQuad))
      ..addListener(() => setState(() {}));
    //update the string when animation value is pi/2 (not visible)
    _animationController.addListener(() {
      if (_animation.value == pi / 2) _updateTimeString();
    });
    _updateTimeString();
  }

  /// animate the change
  @override
  void didUpdateWidget(TimeNumberWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeString != widget.timeString) {
      if (!_animationController.isAnimating) {
        _animationController.forward(from: 0).then((_) {
          _animationController.animateBack(0);
        });
      }
    }
  }

  /// update the local [_timeString] with the widget ones [widget.timeString]
  void _updateTimeString() => setState(() {
        _timeString = widget.timeString;
        //update child here
        _child = _getChild(update: true);
      });

  /// gets the child without having it to recreate all the time
  /// the transform widget gets rerendered quite often so only
  /// recreate the child if the fontSize has changed
  /// if update is set to false return the cached child
  Widget _getChild({bool update = false}) {
    if (!update) return _child;
    return _child = Text(
      _timeString,
      textAlign: TextAlign.center,
      style: SunriseClock.sunriseTextStyle.merge(
        TextStyle(fontSize: _fontSize),
      ),
    );
  }

  /// calculates the FontSize depending on the layout width
  double _calculateFontSize(double width) => width / 2;

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
          child: _getChild(update: updateChild));
    });
  }
}
