// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Compiler implements Canceler, Logger {
  final Script script;
  Queue<Element> worklist;
  Universe universe;
  String generatedCode;

  List<CompilerTask> tasks;
  ScannerTask scanner;
  ParserTask parser;
  ResolverTask resolver;
  TypeCheckerTask checker;
  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;

  static final SourceString MAIN = const SourceString('main');

  Compiler(this.script) {
    universe = new Universe();
    worklist = new Queue<Element>();
    scanner = new ScannerTask(this);
    parser = new ParserTask(this);
    resolver = new ResolverTask(this);
    checker = new TypeCheckerTask(this);
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
    tasks = [scanner, parser, resolver, checker, builder, optimizer, generator];
  }

  void ensure(bool condition) {
    if (!condition) cancel('failed assertion in leg');
  }

  void unimplemented(String methodName) {
    cancel("$methodName not implemented");
  }

  void cancel([String reason, Node node, Token token,
               HInstruction instruction]) {
    throw new CompilerCancelledException(reason);
  }

  void log(message) {
    // Do nothing.
  }

  bool run() {
    try {
      runCompiler();
    } catch (CompilerCancelledException exception) {
      log(exception.toString());
      log('compilation failed');
      return false;
    }
    // TODO(floitsch): the following code can be removed once the HTracer
    // writes directly into a file.
    if (GENERATE_SSA_TRACE) {
      print("------------------");
      print(new HTracer.singleton());
      print("------------------");
    }
    log('compilation succeeded');
    return true;
  }

  void scanCoreLibrary() {
    String fileName = io.join([legDirectory, 'lib', 'core.dart']);
    scanner.scan(readScript(fileName));
    // Make our special function a foreign kind.
    Element element = new ForeignElement(const SourceString('JS'));
    universe.define(element);
  }

  void runCompiler() {
    scanCoreLibrary();
    scanner.scan(script);
    Element element = universe.find(MAIN);
    if (element === null) cancel('Could not find $MAIN');
    compileMethod(element);
    while (!worklist.isEmpty()) {
      compileMethod(worklist.removeLast());
    }
    generatedCode = assembleProgram();
  }

  String compileMethod(Element element) {
    String code = universe.generatedCode[element];
    if (code !== null) return code;
    Node tree = parser.parse(element);
    TreeElements elements = resolver.resolve(element);
    checker.check(tree, elements);
    HGraph graph = builder.build(tree, elements);
    optimizer.optimize(graph);
    code = generator.generate(element, graph);
    universe.addGeneratedCode(element, code);
    return code;
  }

  Element resolveType(ClassElement element) {
    parser.parse(element);
    resolver.resolveType(element);
    return element;
  }

  Element resolveSignature(FunctionElement element) {
    parser.parse(element);
    resolver.resolveSignature(element);
    return element;
  }

  String assembleProgram() {
    StringBuffer buffer = new StringBuffer();
    buffer.add('function Isolate() {};\n\n');
    universe.generatedCode.forEach((Element element, String codeBlock) {
      buffer.add('Isolate.prototype.${element.name} = ');
      buffer.add(codeBlock);
      buffer.add(';\n\n');
    });
    buffer.add('var currentIsolate = new Isolate();\n');
    buffer.add('currentIsolate.main();\n');
    return buffer.toString();
  }

  reportWarning(Node node, var message) {}
  reportError(Node node, var message) {}

  Script readScript(String filename) {
    unimplemented('Compiler.readScript');
  }

  String get legDirectory() {
    unimplemented('Compiler.legDirectory');
  }
}

class CompilerTask {
  final Compiler compiler;
  final Stopwatch watch;

  CompilerTask(this.compiler) : watch = new Stopwatch();

  String get name() => 'Unknown task';
  int get timing() => watch.elapsedInMs();

  measure(Function action) {
    // TODO(kasperl): Do we have to worry about exceptions here?
    watch.start();
    var result = action();
    watch.stop();
    return result;
  }
}

class CompilerCancelledException {
  final String reason;
  CompilerCancelledException(this.reason);

  String toString() {
    String banner = 'compiler cancelled';
    return (reason !== null) ? '$banner: $reason' : '$banner';
  }
}
