
import 'byte_data_wrapper.dart';
import 'dxbc_chunk.dart';
import 'dxbc_enums.dart';


class RdefResourceBinding {
  late final String name;
  late final D3dShaderInputType type;
  late final D3D10_SB_RESOURCE_RETURN_TYPE returnType;
  late final int dimension;
  late final int numSamples;
  late final int bindPoint;
  late final int bindCount;
  late final bool userPacked;
  late final bool comparisonSampler;
  late final int textureComponentCount;
  late final bool unused;

  RdefResourceBinding.read(ByteDataWrapper bytes, int baseOffset) {
    int nameOffset = bytes.readUint32();
    type = D3dShaderInputType.values[bytes.readUint32()];
    returnType = D3D10_SB_RESOURCE_RETURN_TYPE.values[bytes.readUint32()];
    dimension = bytes.readUint32();
    numSamples = bytes.readInt32();
    bindPoint = bytes.readUint32();
    bindCount = bytes.readUint32();
    userPacked = bytes.readBits(1) != 0;
    comparisonSampler = bytes.readBits(1) != 0;
    textureComponentCount = bytes.readBits(2) + 1;
    bytes.readBits(1); // D3D_SIF_TEXTURE_COMPONENTS
    unused = bytes.readBits(1) != 0;
    bytes.readBits(26); // reserved
    assert(bytes.isByteAligned);

    int prevPos = bytes.position;
    bytes.position = baseOffset + nameOffset;
    name = bytes.readStringZeroTerminated();
    bytes.position = prevPos;
  }
}


class RdefTypeData {
  late final String name;
  late final RdefType type;

  RdefTypeData.read(ByteDataWrapper bytes, int baseOffset) {
    int nameOffset = bytes.readUint32();
    int typeOffset = bytes.readUint32();
    bytes.readUint32(); // offsetInParent;

    int prevPos = bytes.position;
    bytes.position = baseOffset + nameOffset;
    name = bytes.readStringZeroTerminated();
    bytes.position = baseOffset + typeOffset;
    type = RdefType.read(bytes, baseOffset);
    bytes.position = prevPos;
  }
}

class RdefType {
  late final D3dShaderVariableClass wClass;
  late final D3dShaderVariableType wType;
  late final int wRows;
  late final int wColumns;
  late final int wElements;
  late final int wMembers;
  late final List<int> reserved;
  late final String name;
  late final List<RdefTypeData> members;

  RdefType.read(ByteDataWrapper bytes, int baseOffset) {
    wClass = D3dShaderVariableClass.values[bytes.readUint16()];
    wType = D3dShaderVariableType.values[bytes.readUint16()];
    wRows = bytes.readUint16();
    wColumns = bytes.readUint16();
    wElements = bytes.readUint16();
    wMembers = bytes.readUint16();
    int wOffset = bytes.readUint16();
    bytes.readUint16(); // wReserved
    reserved = bytes.readUint32List(4);
    int nameOffset = bytes.readUint32();

    int prevPos = bytes.position;
    bytes.position = baseOffset + nameOffset;
    name = bytes.readStringZeroTerminated();

    if (wClass == D3dShaderVariableClass.D3D10_SVC_STRUCT) {
      bytes.position = baseOffset + wOffset;
      members = List.generate(wMembers, (index) {
        return RdefTypeData.read(bytes, baseOffset);
      });
    }
    else {
      members = [];
    }

    bytes.position = prevPos;
  }
}

class RdefConstant {
  late final String name;
  late final int offset;
  late final int size;
  late final int flags;
  late final RdefType type;
  late final int defaultValue;

  RdefConstant.read(ByteDataWrapper bytes, int baseOffset) {
    int nameOffset = bytes.readUint32();
    offset = bytes.readUint32();
    size = bytes.readUint32();
    flags = bytes.readUint32();
    int typeOffset = bytes.readUint32();
    defaultValue = bytes.readUint32();
    bytes.readUint32List(4); // reserved

    int prevPos = bytes.position;
    bytes.position = baseOffset + nameOffset;
    name = bytes.readStringZeroTerminated();
    bytes.position = baseOffset + typeOffset;
    type = RdefType.read(bytes, baseOffset);
    bytes.position = prevPos;
  }

  bool get hasUsages => flags & 0x2 != 0;
}


class RdefConstantBuffer {
  late final String name;
  late final int size;
  late final int type;
  late final int flags;
  late final List<RdefConstant> constants;

  RdefConstantBuffer.read(ByteDataWrapper bytes, int baseOffset) {
    int nameOffset = bytes.readUint32();
    int variables = bytes.readUint32();
    int offset = bytes.readUint32();
    size = bytes.readUint32();
    type = bytes.readUint32();
    flags = bytes.readUint32();

    int prevPos = bytes.position;
    bytes.position = baseOffset + nameOffset;
    name = bytes.readStringZeroTerminated();

    bytes.position = baseOffset + offset;
    constants = List.generate(variables, (index) {
      return RdefConstant.read(bytes, baseOffset);
    });

    bytes.position = prevPos;
  }
}


class Rdef extends DxbcChunkBase {
  late final int version_major;
  late final int version_minor;
  late final int programType;
  late final int flags;
  late final String magic;
  late final List<RdefConstantBuffer> constantBuffers;
  late final List<RdefResourceBinding> resourceBindings;
  late final String creator;

  Rdef.read(ByteDataWrapper bytes) : super.read(bytes) {
    int baseOffset = bytes.position;
    int constBufferCount = bytes.readUint32();
    int constBufferOffset = bytes.readUint32();
    int boundResourcesCount = bytes.readUint32();
    int boundResourcesOffset = bytes.readUint32();
    version_major = bytes.readUint8();
    version_minor = bytes.readUint8();
    programType = bytes.readUint16();
    flags = bytes.readUint32();
    int creatorOffset = bytes.readUint32();
    magic = bytes.readString(4);
    bytes.readUint32List(7); // reserved

    bytes.position = baseOffset + constBufferOffset;
    constantBuffers = List.generate(constBufferCount, (index) {
      return RdefConstantBuffer.read(bytes, baseOffset);
    });

    bytes.position = baseOffset + boundResourcesOffset;
    resourceBindings = List.generate(boundResourcesCount, (index) {
      return RdefResourceBinding.read(bytes, baseOffset);
    });

    bytes.position = baseOffset + creatorOffset;
    creator = bytes.readStringZeroTerminated();
  }
}
