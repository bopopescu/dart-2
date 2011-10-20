// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("url_encoding_test");
#import("../../../../chat/http.dart");

void testParseEncodedString() {
  String encodedString = 'foo+bar%20foobar%25%26';
  Expect.equals(HTTPUtil.decodeUrlEncodedString(encodedString),
                'foo bar foobar%&');
}

void testParseQueryString() {
  // The query string includes escaped "?"s, "&"s, "%"s and "="s.
  // These should not affect the splitting of the string.
  String queryString = '%3F=%3D&foo=bar&%26=%25';
  Map<String, String> map = HTTPUtil.splitQueryString(queryString);
  for (String key in map.getKeys()) {
    Expect.equals(map[key], { '&'   : '%',
                              'foo' : 'bar',
                              '?'   : '='}[key]);
  }
  Expect.setEquals(map.getKeys(), ['&', '?', 'foo']);
}

void main() {
  testParseEncodedString();
  testParseQueryString();
}
