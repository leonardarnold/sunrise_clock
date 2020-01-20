/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:sunrise_clock/models/date_time_model.dart';
import 'package:sunrise_clock/widgets/time_numbers_widget.dart';
import 'package:sunrise_clock/widgets/time_weather_widget.dart';

/// Displays the time, weather and temperature
class TimeCard extends StatelessWidget {
  final ClockModel clockModel;
  final DateTimeModel dateTimeModel;

  TimeCard({Key key, @required this.clockModel, @required this.dateTimeModel})
      : assert(clockModel != null),
        assert(dateTimeModel != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext buildContext, BoxConstraints constraints) {
      final borderWidth = 6.0;
      final backgroundColor = (Theme.of(context).brightness == Brightness.light)
          ? Colors.white
          : Colors.grey[900];
      return SizedBox(
        height: constraints.maxHeight / 5,
        width: constraints.maxWidth / 3 * 2,
        child: Container(
          child: Card(
            elevation: 16,
            margin: EdgeInsets.all(0),
            shape: RoundedRectangleBorder(
                side: BorderSide(
                    color: backgroundColor,
                    width: borderWidth,
                    style: BorderStyle.solid)),
            color: backgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TimeNumbersWidget(
                  dateTimeModel: dateTimeModel,
                  clockModel: clockModel,
                  borderWidth: borderWidth,
                ),
                TemperatureWidget(
                  clockModel: clockModel,
                  dateTimeModel: dateTimeModel,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
