import '../byte_data_wrapper.dart';
import '../dxbc_enums.dart';
import 'opcode.dart';
import 'operand.dart';

class SampleControls {
  late int uTexelImmediateOffset;
  late int vTexelImmediateOffset;
  late int wTexelImmediateOffset;

  SampleControls.read(ByteDataWrapper bytes) {
    bytes.readBits(3); // reserved
    uTexelImmediateOffset = bytes.readBits(4);
    vTexelImmediateOffset = bytes.readBits(4);
    wTexelImmediateOffset = bytes.readBits(4);
    bytes.readBits(10); // reserved
  }
}

class ResourceDim {
  late int resourceDimension;
  late int bufferStride;

  ResourceDim.read(ByteDataWrapper bytes) {
    resourceDimension = bytes.readBits(5);
    bufferStride = bytes.readBits(12);
    bytes.readBits(8); // reserved
  }
}

class ResourceReturnType {
  late D3D10_SB_RESOURCE_RETURN_TYPE returnTypeX;
  late D3D10_SB_RESOURCE_RETURN_TYPE returnTypeY;
  late D3D10_SB_RESOURCE_RETURN_TYPE returnTypeZ;
  late D3D10_SB_RESOURCE_RETURN_TYPE returnTypeW;

  ResourceReturnType.read(ByteDataWrapper bytes) {
    returnTypeX = D3D10_SB_RESOURCE_RETURN_TYPE.values[bytes.readBits(4)];
    returnTypeY = D3D10_SB_RESOURCE_RETURN_TYPE.values[bytes.readBits(4)];
    returnTypeZ = D3D10_SB_RESOURCE_RETURN_TYPE.values[bytes.readBits(4)];
    returnTypeW = D3D10_SB_RESOURCE_RETURN_TYPE.values[bytes.readBits(4)];
  }
}

class InstructionOpcode extends Opcode {
  late final D3D10_SB_RESINFO_INSTRUCTION_RETURN_TYPE returnType;
  late final bool saturate;
  late final D3D10_SB_INSTRUCTION_TEST_BOOLEAN testBoolean;
  late final bool preciseValues;
  SampleControls? sampleControls;
  ResourceDim? resourceDim;
  ResourceReturnType? resourceReturnType;
  final List<Operand> operands = [];

  InstructionOpcode.read(super.opcodeType, ByteDataWrapper bytes, int startPos) {
    returnType = D3D10_SB_RESINFO_INSTRUCTION_RETURN_TYPE.values[bytes.readBits(2)];
    saturate = bytes.readBits(1) != 0;
    bytes.readBits(4);
    testBoolean = D3D10_SB_INSTRUCTION_TEST_BOOLEAN.values[bytes.readBits(1)];
    preciseValues = bytes.readBits(4) != 0;
    bytes.readBits(1);
    readDefaultLength(bytes);

    var isExtended = bytes.readBit() == 1;
    assert(bytes.isByteAligned);
    while (isExtended) {
      var extendedOpCodeType = D3D10_SB_EXTENDED_OPCODE_TYPE.values[bytes.readBits(6)];
      switch (extendedOpCodeType) {
        case D3D10_SB_EXTENDED_OPCODE_TYPE.D3D10_SB_EXTENDED_OPCODE_SAMPLE_CONTROLS:
          if (sampleControls != null) throw Exception("SampleControls already set");
          sampleControls = SampleControls.read(bytes);
          break;
        case D3D10_SB_EXTENDED_OPCODE_TYPE.D3D11_SB_EXTENDED_OPCODE_RESOURCE_DIM:
          if (resourceDim != null) throw Exception("ResourceDim already set");
          resourceDim = ResourceDim.read(bytes);
          break;
        case D3D10_SB_EXTENDED_OPCODE_TYPE.D3D11_SB_EXTENDED_OPCODE_RESOURCE_RETURN_TYPE:
          if (resourceReturnType != null) throw Exception("ResourceReturnType already set");
          resourceReturnType = ResourceReturnType.read(bytes);
          bytes.readBits(9); // reserved
          break;
        default:
          throw Exception("Unknown extended opcode type $extendedOpCodeType");
      }
      isExtended = bytes.readBit() == 1;
    }

    var expectedEndPos = startPos + size * 4;
    while (bytes.position < expectedEndPos) {
      operands.add(Operand.read(bytes));
    }
  }
}