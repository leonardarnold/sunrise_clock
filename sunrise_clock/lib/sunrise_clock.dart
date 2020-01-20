/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sunrise_clock/models/date_time_model.dart';
import 'package:sunrise_clock/widgets/sunrise_widget.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:sunrise_clock/widgets/time_card_widget.dart';

class SunriseClock extends StatefulWidget {
  static final TextStyle sunriseTextStyle = GoogleFonts.share(
    textStyle: const TextStyle(fontWeight: FontWeight.bold),
  );

  const SunriseClock(this.model);

  final ClockModel model;

  @override
  _SunriseClockState createState() => _SunriseClockState();
}

class _SunriseClockState extends State<SunriseClock>
    with SingleTickerProviderStateMixin {
  Timer _timer;
  DateTimeModel _dateTimeModel = DateTimeModel();

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// called every second due to [_timer]
  void _updateTime() {
    _dateTimeModel.now = DateTime.now();
    // Update once per second. Make sure to do it at the beginning of each
    // new second, so that the clock is accurate.
    _timer = Timer(
      Duration(seconds: 1) -
          Duration(milliseconds: _dateTimeModel.now.millisecond),
      _updateTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Container(
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SunriseWidget(
                clockModel: widget.model,
                dateTimeModel: _dateTimeModel,
              ),
            ),
            Center(
              child: SizedBox(
                  height: constraints.maxHeight / 2,
                  width: constraints.maxWidth / 2,
                  child: TimeCard(
                    dateTimeModel: _dateTimeModel,
                    clockModel: widget.model,
                  )),
            ),
          ],
        ),
      );
    });
  }
}
