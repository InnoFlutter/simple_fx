library simple_fx;

import 'dart:math';
import 'package:flutter/material.dart';

const double DEFAULT_HUE = 0;
const double DEFAULT_BRIGHTNESS = 0;
const double DEFAULT_SATURATION = 100;
const double DEFAULT_OPACITY = 100;
const List<double> DEFAULT_FILTER = SFXFilters.none;
const List<double> DEFAULT_CHANNELS = SFXChannels.all;

class SimpleFX extends StatelessWidget {
  Image imageSource;
  double hueRotation;
  double brightness;
  double saturation;
  double opacity;
  List<double> filter;
  List<double> channels;

  SimpleFX({
    required this.imageSource,
    this.hueRotation = DEFAULT_HUE,
    this.brightness = DEFAULT_BRIGHTNESS,
    this.saturation = DEFAULT_SATURATION,
    this.opacity = DEFAULT_OPACITY,
    this.filter = DEFAULT_FILTER,
    this.channels = DEFAULT_CHANNELS,
  });

  TransformMatrix matrix = TransformMatrix();

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix.channelIsolateMatrix(channels)),
      child: ColorFiltered(
        colorFilter: ColorFilter.matrix(filter),
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(matrix.saturationMatrix(saturation)),
          child: ColorFiltered(
              colorFilter: ColorFilter.matrix(matrix.HBOMatrix(hueRotation, brightness, opacity)),
              child: imageSource),
        ),
      ),
    );
  }
}

class TransformMatrix {
  static const List<double> identity = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  List<double> hueRotationMatrix(double rotation) {
    double angle = rotation % 360;

    if (angle == 0) return identity; //0 degree rotation does not modify the matrix
    List<double> sub = [0, 0, 0];
    //Each 120 degree rotation represents one shift to right
    int index = angle ~/ 120;
    sub[index] = 1;
    //First 60 degrees of rotation increase next value, but no more than to 1
    sub[(index + 1) % 3] = min((angle % 120)/60, 1);
    //Next 60 degrees of rotation decrease current value, but no less than 0
    if (angle % 120 > 60) {
      sub[index] -= (angle % 120 - 60)/60;
    }

    return [
      sub[0], sub[2], sub[1], 0, 0,
      sub[1], sub[0], sub[2], 0, 0,
      sub[2], sub[1], sub[0], 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> brightnessMatrix(double brightness) {
    double normalizedBrightness = ((brightness.abs() % 101) / 100) * 255 * brightness.sign;
    return [
      1, 0, 0, 0, normalizedBrightness,
      0, 1, 0, 0, normalizedBrightness,
      0, 0, 1, 0, normalizedBrightness,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> saturationMatrix(double saturation) {
    double s = (saturation.abs() % 101)/100 * saturation.sign;
    //l values are coefficients from relative luminance formula
    double lr = 0.2126;
    double lg = 0.7152;
    double lb = 0.0722;
    return [
      (lr * (1-s)) + s, lg*(1-s),       lb*(1-s),       0, 0,
      lr * (1-s),       (lg*(1-s)) + s, lb*(1-s),       0, 0,
      lr * (1-s),       lg*(1-s),       (lb*(1-s)) + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  List<double> HBOMatrix(double rotation, double brightness, double opacity) {
    double normalizedOpacity = (max(opacity, 0) % 101) / 100;
    double normalizedBrightness = ((brightness.abs() % 101) / 100) * 255 * brightness.sign;
    List<double> hue = hueRotationMatrix(rotation);
    return [
      hue[0], hue[1], hue[2], 0, normalizedBrightness,
      hue[5], hue[6], hue[7], 0, normalizedBrightness,
      hue[10], hue[11], hue[12], 0, normalizedBrightness,
      0, 0, 0, normalizedOpacity, 0,
    ];
  }

  List<double> opacityMatrix(double opacity) {
    double normalizedOpacity = (max(opacity, 0) % 101) / 100;
    return [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, normalizedOpacity, 0,
    ];
  }

  List<double> channelIsolateMatrix(List<double> c) {
    return [
      c[0], 0,    0,    0, 0,
      0,    c[1], 0,    0, 0,
      0,    0,    c[2], 0, 0,
      0,    0,    0,    1, 0,
    ];
  }
}

class SFXFilters {
  static const List<double> none = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> grayscale = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> sepia = [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static const List<double> negative = [
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ];
}

class SFXChannels {
  static const List<double> all = [1, 1, 1];
  static const List<double> none = [0, 0, 0];
  static const List<double> red = [1, 0, 0];
  static const List<double> green = [0, 1, 0];
  static const List<double> blue = [0, 0, 1];
  static const List<double> cyan = [0, 1, 1];
  static const List<double> magenta = [1, 0, 1];
  static const List<double> yellow = [1, 1, 0];
}