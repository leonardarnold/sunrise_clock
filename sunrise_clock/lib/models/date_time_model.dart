/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// DateTimeModel notifies changes regarding the time
/// Time formatting belongs here
class DateTimeModel extends ChangeNotifier {
  DateTime _now;

  DateTimeModel() : _now = DateTime.now();

  get now => _now;

  /// New DateTime which actualises all properties with its setters
  /// note: notifyListeners() will not be called here
  set now(DateTime now) {
    _now = now;
    minutes = _addLeadingZero(_now.minute);
    hours = _change24HourFormat(_now.hour);
    date = DateFormat("MMMMEEEEd").format(_now);
    amPm = DateFormat("a").format(_now);
  }

  String _addLeadingZero(dynamic shortNumber) =>
      (shortNumber.toString().length == 1) ? "0$shortNumber" : "$shortNumber";

  bool _is24HourFormat = true;

  get is24HourFormat => _is24HourFormat;

  set is24HourFormat(bool is24HourFormat) {
    if (is24HourFormat != _is24HourFormat) {
      _is24HourFormat = is24HourFormat;
      hours = _change24HourFormat(_now.hour);
      notifyListeners();
    }
  }

  String _change24HourFormat(int h) {
    if (!is24HourFormat && (h > 12)) h = h - 12;
    return _addLeadingZero(h);
  }

  String _amPm;

  get amPm => _amPm;

  set amPm(String amPm) {
    if (amPm != _amPm) {
      _amPm = amPm;
      notifyListeners();
    }
  }

  String _minutes;

  get minutes => _minutes;

  set minutes(String minutes) {
    if (minutes != _minutes) {
      _minutes = minutes;
      notifyListeners();
    }
  }

  String _hours;

  get hours => _hours;

  set hours(String hours) {
    if (hours != _hours) {
      _hours = hours;
      notifyListeners();
    }
  }

  String _date;

  get date => _date;

  set date(String dateString) {
    if (dateString != _date) {
      _date = dateString;
      notifyListeners();
    }
  }
}
