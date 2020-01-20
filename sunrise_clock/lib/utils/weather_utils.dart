/*
 * Copyright 2020 Leonard Arnold. All rights reserved.
 * Licensed under the MIT License that can be
 * found in the LICENSE file of this project.
 */

import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';

/// helper class with static functions for weather icons
class WeatherUtils {
  static const weatherIconMap = {
    WeatherCondition.sunny: 0xf00d,
    WeatherCondition.foggy: 0xf014,
    WeatherCondition.rainy: 0xf019,
    WeatherCondition.snowy: 0xf01b,
    WeatherCondition.thunderstorm: 0xf01e,
    WeatherCondition.windy: 0xf050,
    WeatherCondition.cloudy: 0xf013,
  };

  static WeatherCondition getWeatherConditionFromString(String condition) =>
      WeatherCondition.values.firstWhere(
          (e) => e.toString().split(".").last == condition,
          orElse: () => null);

  //using text here and not Icon, because Icon does not center the font
  //correctly https://github.com/flutter/flutter/issues/24054
  static Widget getIcon(WeatherCondition weatherCondition,
      {Color color, double size}) {
    return Semantics(
      label: weatherCondition.toString().split(".").last,
      child: Text(
        String.fromCharCode(weatherIconMap[weatherCondition]),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.bold,
          fontFamily: "weathericons",
        ),
      ),
    );
  }
}
