// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class LibraryImport {
  String prefix;
  Library library;
  LibraryImport(this.library, [this.prefix = null]);
}

/** Represents a Dart library. */
class Library {
  final SourceFile baseSource;
  Map<String, Type> types;
  List<LibraryImport> imports;
  String sourceDir;
  String name;
  List<SourceFile> natives;
  List<SourceFile> sources;

  Map<String, MemberSet> _privateMembers;

  /** The type that holds top level types in the library. */
  DefinedType topType;

  /** Set to true by [WorldGenerator] once this type has been written. */
  bool isWritten = false;

  String _jsname;

  Library(this.baseSource) {
    sourceDir = dirname(baseSource.filename);
    topType = new DefinedType(null, this, null, true);
    types = { '': topType };
    imports = [];
    natives = [];
    sources = [];
    _privateMembers = {};
  }

  bool get isCore() => this == world.corelib;
  bool get isCoreImpl() => this == world.coreimpl;

  String get jsname() {
    if (_jsname == null) {
      // TODO(jimhug): Expand to handle all illegal id characters
      _jsname = name.replaceAll('.', '_').replaceAll(':', '_').replaceAll(
          ' ', '_');
    }
    return _jsname;
  }

  SourceSpan get span() => new SourceSpan(baseSource, 0, 0);

  String makeFullPath(String filename) {
    if (filename.startsWith('dart:')) return filename;
    // TODO(jmesserly): replace with node.js path.resolve
    if (filename.startsWith('/')) return filename;
    if (filename.startsWith('file:///')) return filename;
    if (filename.startsWith('http://')) return filename;
    return joinPaths(sourceDir, filename);
  }

  /** Adds an import to the library. */
  addImport(String fullname, String prefix) {
    // TODO(jimhug): Check for duplicates.
    imports.add(new LibraryImport(world.getOrAddLibrary(fullname), prefix));
  }

  addNative(String fullname) {
    natives.add(world.reader.readFile(fullname));
  }

  MemberSet _findMembers(String name) {
    if (name.startsWith('_')) {
      return _privateMembers[name];
    } else {
      return world._members[name];
    }
  }

  _addMember(Member member) {
    if (member.isPrivate) {
      if (member.isStatic) {
        if (member.declaringType.isTop) {
          world._addTopName(member);
        }
        return;
      }

      var mset = _privateMembers[member.name];
      if (mset == null) {
        // TODO(jimhug): Make this lazier!
        for (var lib in world.libraries.getValues()) {
          if (lib._privateMembers.containsKey(member.name)) {
            member.jsname = '_$jsname${member.name}';
            break;
          }
        }

        mset = new MemberSet(member);
        _privateMembers[member.name] = mset;
      } else {
        mset.members.add(member);
      }
    } else {
      world._addMember(member);
    }
  }

  // TODO(jimhug): Cache and share the types as interfaces?
  Type getOrAddFunctionType(String name, FunctionDefinition func, Type inType) {
    final def = new FunctionTypeDefinition(func, null, func.span);
    final type = new DefinedType(name, this, def, false);
    type.addMethod('\$call', func);
    type.members['\$call'].resolve(inType);
    // Functions should implement Function. See "Function Types" in the spec.
    type.interfaces = [world.functionType];
    return type;
  }

  /** Adds a type to the library. */
  Type addType(String name, Node definition, bool isClass) {
    if (types.containsKey(name)) {
      var existingType = types[name];
      if (isCore && existingType.definition == null) {
        // TODO(jimhug): Validate compatibility with natives.
        existingType.setDefinition(definition);
      } else {
        world.warning('duplicate definition of $name', definition.span);
      }
    } else {
      types[name] = new DefinedType(name, this, definition, isClass);
    }

    return types[name];
  }

  Type findType(NameTypeReference type) {
    Type result = findTypeByName(type.name.name);
    if (result == null) return null;

    if (type.names != null) {
      if (type.names.length > 1) {
        // TODO(jmesserly): can we ever get legitimate types with more than one
        // name after the library prefix?
        return null;
      }

      if (!result.isTop) {
        // No inner type support. If we get first-class types, this should
        // perform a lookup on the type.
        return null;
      }

      // The type we got back was the "top level" library type.
      // Now perform a lookup in that library for the next name.
      return result.library.findTypeByName(type.names[0].name);
    }
    return result;
  }

  Type findTypeByName(String name) {
    var ret = types[name];

    // Check all imports even if ret != null to detect conflicting names.
    // TODO(jimhug): Only do this on first lookup.
    for (var imported in imports) {
      var newRet = null;
      if (imported.prefix == null) {
        newRet = imported.library.types[name];
      } else if (imported.prefix == name) {
        newRet = imported.library.topType;
      }
      if (newRet != null) {
        // TODO(jimhug): Should not need ret != newRet here or below.
        if (ret != null  && ret != newRet) {
          world.error('conflicting types for "$name"', ret.span);
          world.error('conflicting types for "$name"', newRet.span);
        } else {
          ret = newRet;
        }
      }
    }
    return ret;
  }

  Member lookup(String name, SourceSpan span) {
    var retType = findTypeByName(name);
    var ret = null;

    if (retType != null) {
      ret = retType.typeMember;
    }

    var newRet = topType.getMember(name);
    // TODO(jimhug): Shares too much code with body of loop.
    if (newRet != null) {
      if (ret != null && ret != newRet) {
        world.error('conflicting members for "$name"', span);
        world.error('conflicting members for "$name"', ret.span);
        world.error('conflicting members for "$name"', newRet.span);
      } else {
        ret = newRet;
      }
    }

    // Check all imports even if ret != null to detect conflicting names.
    // TODO(jimhug): Only do this on first lookup.
    for (var imported in imports) {
      if (imported.prefix == null) {
        newRet = imported.library.topType.getMember(name);
        if (newRet != null) {
          if (ret != null && ret != newRet) {
            world.error('conflicting members for "$name"', span);
            world.error('conflicting members for "$name"', ret.span);
            world.error('conflicting members for "$name"', newRet.span);
          } else {
            ret = newRet;
          }
        }
      }
    }
    return ret;
  }

  resolve() {
    if (name == null) {
      // TODO(jimhug): More fodder for io library.
      name = baseSource.filename;
      var index = name.lastIndexOf('/', name.length);
      if (index >= 0) {
        name = name.substring(index+1);
      }
      index = name.indexOf('.', 0);
      if (index > 0) {
        name = name.substring(0, index);
      }
    }
    for (var type in types.getValues()) {
      type.resolve();
    }
  }

  toString() => baseSource.filename;
}


class LibraryVisitor implements TreeVisitor {
  final Library library;
  Type currentType;
  List<SourceFile> sources;

  LibraryVisitor(this.library) {
    currentType = library.topType;
    sources = [];
    addSource(library.baseSource);
  }

  addSourceFromName(String name) {
    var source = world.readFile(library.makeFullPath(name));
    sources.add(source);
  }

  addSource(SourceFile source) {
    library.sources.add(source);
    final parser = new Parser(source, /*diet:*/options.dietParse);
    final unit = parser.compilationUnit();

    for (final def in unit) {
      def.visit(this);
    }

    // TODO(jimhug): Enforce restrictions on source and import directives.
    var newSources = sources;
    sources = [];
    for (var source in newSources) {
      addSource(source);
    }
  }

  void visitDirectiveDefinition(DirectiveDefinition node) {
    var name;
    switch (node.name.name) {
      case "library":
        name = getSingleStringArg(node);
        if (library.name == null) {
          library.name = name;
          // TODO(jimhug): Hack to get native fields for io and dom - generalize.
          if (name == 'node' || name == 'dom') {
            library.topType.isNativeType = true;
          }
        } else {
          world.error('already specified library name', node.span);
        }
        break;

      case "import":
        name = getFirstStringArg(node);
        var prefix = tryGetNamedStringArg(node, 'prefix');
        if (node.arguments.length > 2 ||
            node.arguments.length == 2 && prefix == null) {
          world.error(
              'expected at most one "name" argument and one optional "prefix"'
              + ' but found ${node.arguments.length}', node.span);
        } else if (prefix != null && prefix.indexOf('.', 0) >= 0) {
          world.error('library prefix canot contain "."', node.span);
        }

        // Empty prefix and no prefix are equivalent
        if (prefix == '') prefix = null;

        library.addImport(library.makeFullPath(name), prefix);
        break;

      case "source":
        name = getSingleStringArg(node);
        addSourceFromName(name);
        break;

      case "native":
        name = getSingleStringArg(node);
        library.addNative(library.makeFullPath(name));
        break;

      case "resource":
        // TODO(jmesserly): should we do anything else here?
        getFirstStringArg(node);
        break;

      default:
        world.error('unknown directive: ${node.name.name}', node.span);
    }
  }

  String getSingleStringArg(DirectiveDefinition node) {
    if (node.arguments.length != 1) {
      world.error(
          'expected exactly one argument but found ${node.arguments.length}',
          node.span);
    }
    return getFirstStringArg(node);
  }

  String getFirstStringArg(DirectiveDefinition node) {
    if (node.arguments.length < 1) {
      world.error(
          'expected at least one argument but found ${node.arguments.length}',
          node.span);
    }
    var arg = node.arguments[0];
    if (arg.label != null) {
      world.error('label not allowed for directive', node.span);
    }
    return _parseStringArgument(arg);
  }

  String tryGetNamedStringArg(DirectiveDefinition node, String argName) {
    var args = node.arguments.filter(
        (a) => a.label != null && a.label.name == argName);

    if (args.length == 0) {
      return null;
    }
    if (args.length > 1) {
      world.error('expected at most one "${argName}" argument but found '
          + node.arguments.length, node.span);
    }
    // Even though the collection has one arg, this is the easiest way to get
    // the first item.
    for (var arg in args) {
      return _parseStringArgument(arg);
    }
  }

  String _parseStringArgument(ArgumentNode arg) {
    var expr = arg.value;
    if (expr is! LiteralExpression || !expr.type.type.isString) {
      world.error('expected string', expr.span);
    }
    return parseStringLiteral(expr.value);
  }

  void visitTypeDefinition(TypeDefinition node) {
    var oldType = currentType;
    currentType = library.addType(node.name.name, node, node.isClass);
    for (var member in node.body) {
      member.visit(this);
    }
    currentType = oldType;
  }

  void visitVariableDefinition(VariableDefinition node) {
    currentType.addField(node);
  }

  void visitFunctionDefinition(FunctionDefinition node) {
    currentType.addMethod(node.name.name, node);
  }

  void visitFunctionTypeDefinition(FunctionTypeDefinition node) {
    var type = library.addType(node.func.name.name, node, false);
    type.addMethod('\$call', node.func);
  }
}