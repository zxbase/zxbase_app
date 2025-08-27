// Copyright (C) 2022 Zxbase, LLC. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Application themes: light and dark.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zxbase_flutter_ui/zxbase_flutter_ui.dart';

class LocalTheme {
  static const light = 'light';
  static const dark = 'dark';

  static ThemeData _buildDarkTheme() {
    final ThemeData base = ThemeData.dark(useMaterial3: false);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.grey.shade400),
      ),
      // independent icon buttons, like in password generation widget
      iconTheme: IconThemeData(color: Colors.grey.shade400),
      // suffix icon buttons
      inputDecorationTheme: InputDecorationTheme(
        suffixIconColor: Colors.grey.shade400,
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    final ThemeData base = ThemeData.light(useMaterial3: false);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: UI.isMobile
            ? Colors.grey.shade100
            : Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.grey.shade600),
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: UI.isMobile
            ? Colors.grey.shade100
            : Colors.transparent,
      ),
      // independent icon buttons, like in password generation widget
      iconTheme: IconThemeData(color: Colors.grey.shade600),
      // suffix icon buttons
      inputDecorationTheme: InputDecorationTheme(
        suffixIconColor: Colors.grey.shade600,
      ),
    );
  }

  static void setOverlayStyle(String themeName) {
    var style = (themeName == dark)
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;
    SystemChrome.setSystemUIOverlayStyle(style);
  }

  static ThemeData build(String themeName) {
    return (themeName == dark) ? _buildDarkTheme() : _buildLightTheme();
  }
}
