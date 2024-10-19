
import 'dart:math';

import 'state.dart';
import 'statements.dart';

enum ScalarType {
  bool(1),
  int_(4),
  uint(4),
  half(2),
  float(4),
  double(8);

  final int size;

  const ScalarType(this.size);
}

enum DataTypeType {
  scalar,
  vector,
  matrix,
  sampler,
  texture,
  buffer,
  struct,
  array,
}

abstract class DataType {
  int get size;

  const DataType();

  void write(WriterState writer);
}

class ScalarDataType extends DataType {
  final ScalarType type;
  @override
  int get size => type.size;

  const ScalarDataType(this.type);

  @override
  void write(WriterState writer) {
    writer.write(type.name);
  }
}

class VectorDataType extends DataType {
  final ScalarType type;
  final int count;
  @override
  int get size => type.size * count;

  const VectorDataType(this.type, this.count);

  @override
  void write(WriterState writer) {
    writer.write("${type.name}$count");
  }
}

class MatrixDataType extends DataType {
  final ScalarType type;
  final int rows;
  final int columns;
  @override
  int get size => type.size * rows * columns;

  const MatrixDataType(this.type, this.rows, this.columns);

  @override
  void write(WriterState writer) {
    writer.write("${type.name}${rows}x$columns");
  }
}


class StructMember {
  final String name;
  final DataType type;
  final int elements;
  final bool hasUsages;
  final int size;
  final int offset;

  const StructMember(this.name, this.type, this.elements, this.size, this.offset, {this.hasUsages = false});

  void write(WriterState writer) {
    type.write(writer);
    writer.write(" $name");
    if (elements > 1) {
      writer.write("[$elements]");
    }
    writer.write(";");
    writer.writeNewLine();
  }
  
  List<MemberAccess> getMemberChainAt(int targetOffset, int targetSize, bool addDot) {
    String chain = "";
    var typeSize = type.size;
    if (addDot)
      chain += ".";
    chain += name;
    if (elements > 1) {
      int index = targetOffset ~/ typeSize;
      chain += "[$index]";
    }
    List<MemberAccess> membersAccess;
    if (type is StructDataType) {
      chain += ".$name";
      membersAccess = (type as StructDataType).getMemberChainAt(targetOffset % typeSize, targetSize);
    } else if (type is MatrixDataType) {
      throw Exception("Matrix member access not supported");
    } else {
      var availableSize = size - targetOffset;
      var readSize = min(availableSize, targetSize);
      membersAccess = [MemberAccess("", readSize, targetOffset)];
    }
    for (var mem in membersAccess)
      mem.addPrefix(chain);
    
    return membersAccess;
  }
  
  void getMemberChainDynamic(int offset, List<String> chainOut, bool addDot) {
    var lastI = chainOut.length - 1;
    if (addDot)
      chainOut[lastI] += ".";
    chainOut[lastI] += name;
    if (elements > 1) {
      if (chainOut.length > 1)
        throw Exception("Can't resolve member with nested arrays");
      if (type.size > 16)
        throw Exception("Can't resolve member array size > 16 (${type.size})");
      chainOut[lastI] += "[";
      chainOut.add("]");
      lastI += 1;
    }
    if (type is StructDataType)
      (type as StructDataType).getMemberChainDynamic(offset, chainOut);
    else if (type is MatrixDataType)
      chainOut[lastI] += "/* ? */";
  }
}

class MemberAccess {
  String path;
  final int size; /*12*/
  final int startOffset; /*0*/

  MemberAccess(this.path, this.size, this.startOffset);

  void addPrefix(String prefix) {
    path = prefix + path;
  }

  Component getComponent(Component swizzle /*y - 1*/, int offset /*4*/) {
    // if (offset + swizzle.index * 4 > size)
    //   return null;
    return Component.values[(startOffset ~/ 4 - offset ~/ 4 + swizzle.index) % Component.values.length];
  }
}

abstract class StructLike {
  List<MemberAccess> getMemberChainAt(int offset, int size);

  void getMemberChainDynamic(int offset, List<String> chainOut);
}

class StructDataType extends DataType implements StructLike {
  final List<StructMember> members;
  final String? name;
  @override
  final int size;
  bool includeInOutput;

  StructDataType(this.members, this.name, this.size, {this.includeInOutput = true});

  int calcUsedSize() {
    var unusedTrailingSize = members
      .reversed
      .takeWhile((member) => !member.hasUsages)
      .fold(0, (int acc, member) => acc + member.size);
    int declarationSize = size;
    declarationSize -= unusedTrailingSize;
    declarationSize = (declarationSize / 16).ceil();
    return declarationSize;
  }

  @override
  void write(WriterState writer, {bool isDeclaration = false}) {
    writer.write("struct ");
    if (name != null) {
      writer.write(name!);
      writer.write(" ");
    }
    writer.write("{");
    writer.writeNewLine();
    writer.indent();
    for (var member in members) {
      member.write(writer);
    }
    writer.unindent();
    writer.write("}");
    if (isDeclaration) {
      writer.write(";");
      writer.writeNewLine();
      writer.writeNewLine();
    }
  }

  @override
  List<MemberAccess> getMemberChainAt(int offset, int size) {
    int remainingSize = size;
    List<MemberAccess> membersAccess = [];
    for (var member in members) {
      if (offset >= member.offset + member.size || offset < member.offset)
        continue;
      var newMembersAccess = member.getMemberChainAt(offset - member.offset, remainingSize, true);
      for (var mem in newMembersAccess) {
        remainingSize -= mem.size;
        offset += mem.size;
      }
      membersAccess.addAll(newMembersAccess);
      if (remainingSize == 0)
        break;
      if (remainingSize < 0)
        throw Exception("Read too much :(");
    }
    if (membersAccess.isEmpty)
      throw Exception("Offset $offset not in struct of size $size");
    return membersAccess;
  }

  @override
  void getMemberChainDynamic(int offset, List<String> chainOut) {
    if (members.length != 1)
      throw Exception("Can't lookup member chain for structs with more than one member (struct $name, members: ${members.length})");
    members[0].getMemberChainDynamic(offset, chainOut, true);
  }
}


const tFloat = ScalarDataType(ScalarType.float);
const tFloat2 = VectorDataType(ScalarType.float, 2);
const tFloat4 = VectorDataType(ScalarType.float, 4);
const tUint = ScalarDataType(ScalarType.uint);
const tUint2 = VectorDataType(ScalarType.uint, 2);
const tUint3 = VectorDataType(ScalarType.uint, 3);
const tUint4 = VectorDataType(ScalarType.uint, 4);
const tInt = ScalarDataType(ScalarType.int_);
const tInt2 = VectorDataType(ScalarType.int_, 2);
const tInt3 = VectorDataType(ScalarType.int_, 3);
const tInt4 = VectorDataType(ScalarType.int_, 4);
const tBool = ScalarDataType(ScalarType.bool);
