// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class HTracer extends HGraphVisitor {
  int indent = 0;
  final StringBuffer output;

  factory HTracer.singleton() {
    if (_singleton === null) _singleton = new HTracer._internal();
    return _singleton;
  }

  HTracer._internal() : output = new StringBuffer();

  void traceCompilation(String methodName) {
    tag("compilation", () {
      printProperty("name", methodName);
      printProperty("method", methodName);
      printProperty("date", new Date.now().value);
    });
  }

  void traceGraph(String name, HGraph graph) {
    tag("cfg", () {
      printProperty("name", name);
      visitDominatorTree(graph);
    });
  }

  void addPredecessors(HBasicBlock block) {
    if (block.predecessors.isEmpty()) {
      printEmptyProperty("predecessors");
    } else {
      addIndent();
      add("predecessors");
      for (HBasicBlock predecessor in block.predecessors) {
        add(' "B${predecessor.id}"');
      }
      add("\n");
    }
  }

  void addSuccessors(HBasicBlock block) {
    if (block.successors.isEmpty()) {
      printEmptyProperty("successors");
    } else {
      addIndent();
      add("successors");
      for (HBasicBlock successor in block.successors) {
        add(' "B${successor.id}"');
      }
      add("\n");
    }
  }

  void addInstructions(HInstructionStringifier stringifier,
                       HInstructionList list) {
    for (HInstruction instruction = list.first;
         instruction !== null;
         instruction = instruction.next) {
      int bci = 0;
      int uses = instruction.usedBy.length;
      addIndent();
      String temporaryId = stringifier.temporaryId(instruction);
      String instructionString = stringifier.visit(instruction);
      add("$bci $uses $temporaryId $instructionString <|@\n");
    }
  }

  void visitBasicBlock(HBasicBlock block) {
    HInstructionStringifier stringifier = new HInstructionStringifier(block);
    assert(block.id !== null);
    tag("block", () {
      printProperty("name", "B${block.id}");
      printProperty("from_bci", -1);
      printProperty("to_bci", -1);
      addPredecessors(block);
      addSuccessors(block);
      printEmptyProperty("xhandlers");
      printEmptyProperty("flags");
      if (block.dominator !== null) {
        printProperty("dominator", "B${block.dominator.id}");
      }
      tag("states", () {
        tag("locals", () {
          printProperty("size", 0);
          printProperty("method", "None");
          block.forEachPhi((phi) {
            String phiId = stringifier.temporaryId(phi);
            String inputId1 = stringifier.temporaryId(phi.inputs[0]);
            String inputId2 = stringifier.temporaryId(phi.inputs[1]);
            print("${phi.id} $phiId [ $inputId1 $inputId2 ]");
          });
        });
      });
      tag("HIR", () {
        addInstructions(stringifier, block.phis);
        addInstructions(stringifier, block);
      });
    });
  }

  void tag(String tagName, Function f) {
    print("begin_$tagName");
    indent++;
    f();
    indent--;
    print("end_$tagName");
  }

  void print(String string) {
    addIndent();
    add(string);
    add("\n");
  }

  void printEmptyProperty(String propertyName) {
    print(propertyName);
  }

  void printProperty(String propertyName, var value) {
    if (value is num) {
      print("$propertyName $value");
    } else {
      print('$propertyName "$value"');
    }
  }

  void add(String string) {
    output.add(string);
  }

  void addIndent() {
    for (int i = 0; i < indent; i++) {
      add("  ");
    }
  }

  toString() => output.toString();

  static HTracer _singleton = null;
}

class HInstructionStringifier implements HVisitor<String> {
  HBasicBlock currentBlock;

  HInstructionStringifier(this.currentBlock);

  visit(HInstruction node) => node.accept(this);

  visitBasicBlock(HBasicBlock node) {
    unreachable();
  }

  String temporaryId(HInstruction instruction) => "v${instruction.id}";

  String visitBoolify(HBoolify node) {
    return "Boolify: ${temporaryId(node.inputs[0])}";
  }

  String visitAdd(HAdd node) => visitInvoke(node);

  String visitDivide(HDivide node) => visitInvoke(node);

  String visitEquals(HEquals node) => visitInvoke(node);

  String visitExit(HExit node) => "exit";

  String visitGoto(HGoto node) {
    HBasicBlock target = currentBlock.successors[0];
    return "Goto: (B${target.id})";
  }

  String visitIf(HIf node) {
    HBasicBlock thenBlock = currentBlock.successors[0];
    HBasicBlock elseBlock = currentBlock.successors[1];
    String conditionId = temporaryId(node.inputs[0]);
    return "If ($conditionId): (B${thenBlock.id}) else (B${elseBlock.id})";
  }

  String visitGenericInvoke(String invokeType, HInvoke invoke) {
    StringBuffer arguments = new StringBuffer();
    for (int i = 0; i < invoke.inputs.length; i++) {
      if (i != 0) arguments.add(", ");
      arguments.add(temporaryId(invoke.inputs[i]));
    }
    return "$invokeType: ${invoke.element.name}($arguments)";
  }

  String visitInvoke(HInvoke invoke) {
    return visitGenericInvoke("Invoke", invoke);
  }

  String visitInvokeForeign(HInvokeForeign invoke) {
    return visitGenericInvoke("InvokeForeign", invoke);
  }

  String visitLiteral(HLiteral literal) => "Literal ${literal.value}";

  String visitLoopBranch(HLoopBranch branch) {
    HBasicBlock bodyBlock = currentBlock.successors[0];
    HBasicBlock exitBlock = currentBlock.successors[1];
    String conditionId = temporaryId(branch.inputs[0]);
    return "While ($conditionId): (B${bodyBlock.id}) then (B${exitBlock.id})";
  }

  String visitMultiply(HMultiply node) => visitInvoke(node);

  String visitParameter(HParameter node) => "p${node.parameterIndex}";

  String visitPhi(HPhi phi) {
    return "Phi(${temporaryId(phi.inputs[0])}, ${temporaryId(phi.inputs[1])})";
  }

  String visitReturn(HReturn node) => "Return ${temporaryId(node.inputs[0])}";

  String visitSubtract(HSubtract node) => visitInvoke(node);

  String visitThrow(HThrow node) => "Throw ${temporaryId(node.inputs[0])}";

  String visitTruncatingDivide(HTruncatingDivide node) => visitInvoke(node);
}
