
import 'data_type.dart';
import 'state.dart';
import 'statements.dart';

enum ResourceBindingType {
  constantBuffer,
  buffer,
  texture,
  sampler,
  uav,
  struct,
}

abstract class ResourceBinding {
  final String name;
  final Register register;

  ResourceBinding(this.name, this.register);

  void writeDeclaration(DecompilerState state);

  void writeName(DecompilerState state) {
    state.mainWriter.write(name);
  }
}

class ConstantBufferBinding extends ResourceBinding implements StructLike {
  final List<StructMember> members;

  ConstantBufferBinding(super.name, super.register, this.members);

  @override
  void writeDeclaration(DecompilerState state) {
    var writer = state.resourcesWriter;
    writer.write("cbuffer $name : register(${register.type.letter}${register.index}) {");
    writer.writeNewLine();
    writer.indent();
    for (var member in members) {
      member.write(writer);
    }
    writer.unindent();
    writer.write("}");
    writer.writeNewLine();
    writer.writeNewLine();
  }

  @override
  List<MemberAccess> getMemberChainAt(int offset, int size) {
    int remainingSize = size;
    List<MemberAccess> membersAccess = [];
    for (var member in members) {
      if (offset >= member.offset + member.size || offset < member.offset)
        continue;
      var newMembersAccess = member.getMemberChainAt(offset - member.offset, remainingSize, false);
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
      throw Exception("Offset $offset not in const buffer $name");
    return membersAccess;
  }

  @override
  void getMemberChainDynamic(int offset, List<String> chainOut) {
    if (members.length != 1)
      throw Exception("Can't lookup member chain for const buffers with more than one member (buffer $name, members: ${members.length})");
    members[0].getMemberChainDynamic(offset, chainOut, false);
  }
}

class TemplateBinding extends ResourceBinding {
  final String className;
  final DataType? innerType;

  TemplateBinding(super.name, super.register, this.className, this.innerType);

  @override
  void writeDeclaration(DecompilerState state) {
    var writer = state.resourcesWriter;
    writer.write(className);
    if (innerType != null) {
      writer.write("<");
      if (innerType is StructDataType)
        writer.write((innerType as StructDataType).name!);
      else
        innerType!.write(writer);
      writer.write(">");
    }
    writer.write(" $name : register(${register.type.letter}${register.index});");
    writer.writeNewLine();
  }
}

enum ParameterType {
  none(""),
  in_("in"),
  out("out"),
  inout("inout");

  final String name;

  const ParameterType(this.name);
}

class ParameterResourceBinding extends ResourceBinding {
  final ParameterType type;
  final DataType dataType;
  final String? semantic;

  ParameterResourceBinding(super.name, super.register, this.dataType, this.type, this.semantic);

  @override
  void writeDeclaration(DecompilerState state) {
    var writer = state.parametersWriter;
    if (type != ParameterType.none) {
      writer.write("${type.name} ");
    }
    dataType.write(writer);
    writer.write(" $name");
    if (semantic != null) {
      writer.write(" : $semantic");
    }
  }
}

class TempVariableBinding extends ResourceBinding {
  final DataType dataType;

  TempVariableBinding._(super.name, super.register, this.dataType);

  factory TempVariableBinding(Register register, DataType dataType) {
    var name = "temp${register.index}";
    return TempVariableBinding._(name, register, dataType);
  }

  @override
  void writeDeclaration(DecompilerState state) {
    state.mainWriter.write(name);
  }
}
