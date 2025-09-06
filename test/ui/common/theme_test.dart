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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zxbase_app/ui/common/theme.dart';

void main() {
  test('Build light theme', () {
    ThemeData theme = LocalTheme.build(LocalTheme.light);
    expect(theme.colorScheme.surface, const Color(0xFFFFFFFF));
  });

  test('Build dark theme', () {
    ThemeData theme = LocalTheme.build(LocalTheme.dark);
    expect(theme.colorScheme.surface, const Color(0xFF424242));
  });

  test('Set overlay style', () {
    WidgetsFlutterBinding.ensureInitialized();
    LocalTheme.setOverlayStyle(LocalTheme.dark);
    expect(SystemChrome.latestStyle, null);
  });
}
