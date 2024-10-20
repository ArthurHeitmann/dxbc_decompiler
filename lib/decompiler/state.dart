
import 'dart:collection';

import '../file_reader/dxbc_chunk.dart';
import '../file_reader/shex/declare_opcode.dart';
import '../file_reader/shex/opcode.dart';
import '../file_reader/rdef_reader.dart';
import '../file_reader/shex_reader.dart';
import '../file_reader/signature_reader.dart';
import 'data_type.dart';
import 'resource_binding.dart';
import 'resource_parser.dart';
import 'statements.dart';

abstract class Writable {
  void write(DecompilerState state);
}

class WriterState {
  final _buffer = StringBuffer();
  int _indent;
  bool _hasWrittenIndent = false;

  WriterState({int indent = 0}) : _indent = indent;
  
  void write(String text) {
    if (!_hasWrittenIndent) {
      _buffer.write("\t" * _indent);
      _hasWrittenIndent = true;
    }
    _buffer.write(text);
  }

  void writeNewLine() {
    _buffer.writeln();
    _hasWrittenIndent = false;
  }

  void indent() {
    _indent++;
  }

  void unindent() {
    _indent--;
  }

  @override
  String toString() {
    return _buffer.toString();
  }
}

class DecompilerState {
  final Dxbc dbxc;
  late final Rdef rdef;
  late final SGN? inputSignature;
  late final SGN? outputSignature;
  late final List<Opcode> opcodes;
  final List<({String name, StructDataType type, int? register})> structDefinitions = [];
  final Map<(RegisterType, int), ResourceBinding> registerBindings = {};
  final List<String> functionAttributes = [];
  final structsWriter = WriterState();
  final resourcesWriter = WriterState();
  final parametersWriter = WriterState();
  final mainWriter = WriterState();
  final Map<String, int> _variableDeclarationCounts = {};
  final _blocksStack = [BlockStatement()];
  BlockStatement get mainBlock => _blocksStack.first;
  
  DecompilerState(this.dbxc) {
    rdef = dbxc.chunks.whereType<Rdef>().first;
    inputSignature = dbxc.chunks.whereType<SGN>().where((sgn) => sgn.chunkMagic == "ISGN").firstOrNull;
    outputSignature = dbxc.chunks.whereType<SGN>().where((sgn) => sgn.chunkMagic == "OSGN").firstOrNull;
    opcodes = dbxc.chunks.whereType<Shex>().first.opCodes;
    parseStructDefinitions(this);
  }

  void addStatement(Statement statement) {
    _blocksStack.last.statements.add(statement);
  }

  void pushBlock(BlockStatement block) {
    addStatement(block);
    _blocksStack.add(block);
  }

  void popBlock() {
    _blocksStack.removeLast();
  }

  String nextVarName(String base) {
    var index = _variableDeclarationCounts[base] ?? 0;
     _variableDeclarationCounts[base] = index + 1;
    return "$base$index";
  }

  bool isVariableDeclared(String name) {
    return _variableDeclarationCounts.containsKey(name);
  }

  void declareVariable(String name) {
    _variableDeclarationCounts.putIfAbsent(name, () => 0);
  }

  void writeStructs() {
    for (var struct in structDefinitions) {
      if (!struct.type.includeInOutput)
        continue;
      struct.type.write(structsWriter, isDeclaration: true);
    }
  }

  void writeParameters() {
    var parameterBindings = registerBindings.values
      .whereType<ParameterResourceBinding>()
      .toList();
    parameterBindings.sort((a, b) => a.type.index - b.type.index);
    var multiLine = parameterBindings.length >= 3;
    var isFirst = true;
    if (multiLine) {
      parametersWriter.writeNewLine();
      parametersWriter.indent();
    }
    for (var binding in parameterBindings) {
      if (!isFirst) {
        if (multiLine) {
          parametersWriter.write(",");
          parametersWriter.writeNewLine();
        } else {
          parametersWriter.write(", ");
        }
      }
      binding.writeDeclaration(this);
      isFirst = false;
    }
    if (multiLine) {
      parametersWriter.unindent();
      parametersWriter.writeNewLine();
    }
  }

  void writeStatements() {
    _blocksStack.first.write(this);
  }

  String toFileString() {
    var buffer = StringBuffer();
    buffer.write(structsWriter);
    buffer.write(resourcesWriter);
    buffer.write("\n\n");
    for (var attribute in functionAttributes) {
      buffer.write("[$attribute]\n");
    }
    buffer.write("void main(");
    buffer.write(parametersWriter);
    buffer.write(") ");
    buffer.write(mainWriter);
    return buffer.toString();
  }
}
