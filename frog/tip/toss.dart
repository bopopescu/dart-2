// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('../lib/node/node.dart');
#import('../file_system_node.dart');
#import('../lang.dart');

String compileDart(String basename, String filename) {
  // Get the home directory from our executable.
  var homedir = path.dirname(fs.realpathSync(process.argv[1]));

  var fs = new NodeFileSystem();

  var basedir = path.dirname(basename);
  filename = '$basedir/$filename';

  if (compile(homedir, [null, null, filename], fs)) {
    var code = world.getGeneratedCode();
    return code;
  } else {
    return 'alert("compilation of $filename failed, see console for errors");';
  }
}


String frogify(String filename) {
  final s = @'<script\s+type="application/dart"(?:\s+src="(\w+.dart)")?>([\s\S]*)</script>';

  final text = fs.readFileSync(filename, 'utf8');
  final re = new RegExp(s, true, false);
  var m = re.firstMatch(text);
  if (m === null) return text;

  var dname = m.group(1);
  var contents = m.group(2);

  print('compiling $dname');

  var compiled = compileDart(filename, dname);

  return text.substring(0, m.start()) +
    '<script type="application/javascript">${compiled}</script>' +
    text.substring(m.start() + m.group(0).length);
}

void main() {
  http.createServer((ServerRequest req, ServerResponse res) {
    var filename;
    if (req.url.endsWith('.html')) {
      res.setHeader('Content-Type', 'text/html');
    } else if (req.url.endsWith('.css')) {
        res.setHeader('Content-Type', 'text/css');
    } else {
      res.setHeader('Content-Type', 'text/plain');
    }
    filename = '../' + req.url;

    if (path.existsSync(filename)) {
      var stat = fs.statSync(filename);
      if (stat.isFile()) {
        res.statusCode = 200;
        String data;
        if (filename.endsWith('.html')) {
          res.end(frogify(filename));
        } else {
          res.end(fs.readFileSync(filename, 'utf8'));
        }
        return;
      }
      // TODO(jimhug): Directory listings?
    }


    res.statusCode = 404;
    res.end('');
  }).listen(1337, "localhost");
  print('Server running at http://localhost:1337/');
}
