// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String getPlatformOutDir() {
  var os = new Platform().operatingSystem();
  if (os == 'linux') return 'out/';
  if (os == 'macos') return 'xcodebuild/';
  return '';  // Windows.
}

String getPlatformExecutableExtension() {
  var os = new Platform().operatingSystem();
  if (os == 'windows') return '.exe';
  return '';  // Linux and Mac OS.
}

String getProcessTestFileName() {
  var outDir = getPlatformOutDir();
  var extension = getPlatformExecutableExtension();
  var names = ['${outDir}Release_ia32/process_test$extension',
               '${outDir}Debug_ia32/process_test$extension'];

  for (var name in names) {
    if (new File(name).existsSync()) {
      return name;
    }
  }
  Expect.fail('Could not find the process_test executable.');
}

String getDartFileName() {
  var outDir = getPlatformOutDir();
  var extension = getPlatformExecutableExtension();
  var names = ['${outDir}Release_ia32/dart$extension',
               '${outDir}Debug_ia32/dart$extension'];

  for (var name in names) {
    if (new File(name).existsSync()) {
      return name;
    }
  }
  Expect.fail('Could not find the dart executable.');
}
