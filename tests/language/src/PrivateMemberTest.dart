// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('PrivateMemberLibA');

#import('PrivateMemberLibB.dart');

class A {
  int i;
  int _instanceField;
  static int _staticField;
  int _fun1() { return 1; }
  void _fun2(int i) { }
}

class Test extends B {
  test() {
    i = _instanceField;
    i = _staticField;
    i = _fun1();
    _fun2(42);
  }
}

void main() {
  new Test().test();
}
