// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("PrefixTest1.dart");

#import("PrefixTest2.dart", prefix: "prefix");
class Prefix {
  static final int foo = 43;

  static getSource() {
    return foo;
  }

  static getImport() {
    return prefix.Prefix.foo;
  }
}
