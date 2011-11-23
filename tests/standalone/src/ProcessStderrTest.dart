// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

#source("ProcessTestUtil.dart");

void test(Process process) {
  List<int> data = "ABCDEFGHI\n".charCodes();
  final int dataSize = data.length;

  InputStream input = process.stderr;
  OutputStream output = process.stdin;

  process.start();

  int received = 0;
  List<int> buffer = [];

  void readData() {
    buffer.addAll(input.read());
    for (int i = received; i < Math.min(data.length, buffer.length) - 1; i++) {
      Expect.equals(data[i], buffer[i]);
    }
    received = buffer.length;
    if (received >= dataSize) {
      // We expect an extra character on windows due to carriage return.
      if (13 === buffer[dataSize - 1] && dataSize + 1 === received) {
        Expect.equals(13, buffer[dataSize - 1]);
        Expect.equals(10, buffer[dataSize]);
        buffer.removeLast();
        process.close();
      } else if (received === dataSize) {
        process.close();
      }
    }
  }

  output.write(data);
  output.close();
  input.dataHandler = readData;
}

main() {
  // Run the test using the process_test binary.
  test(new Process(getProcessTestFileName(),
                   const ["1", "1", "99", "0"]));

  // Run the test using the dart binary with an echo script.
  // The test runner can be run from either the root or from runtime.
  var scriptFile = new File("tests/standalone/src/ProcessStdIOScript.dart");
  if (!scriptFile.existsSync()) {
    scriptFile = new File("../tests/standalone/src/ProcessStdIOScript.dart");
  }
  Expect.isTrue(scriptFile.existsSync());
  test(new Process(getDartFileName(), [scriptFile.name, "1"]));
}
