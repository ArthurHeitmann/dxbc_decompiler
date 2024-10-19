import '../byte_data_wrapper.dart';
import '../dxbc_enums.dart';
import '../shex_reader.dart';
import 'custom_data_opcode.dart';
import 'declare_opcode.dart';
import 'instruction_opcode.dart';
import 'sync_opcode.dart';

abstract class Opcode {
  late final D3D10_SB_OPCODE_TYPE opcodeType;
  late final int size;

  Opcode(this.opcodeType);

  static Opcode read(ByteDataWrapper bytes, ShexVersion version) {
    int startPos = bytes.position;
    var opcodeType = D3D10_SB_OPCODE_TYPE.values[bytes.readBits(11)];

    Opcode opCode;
    if (opcodeType == D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CUSTOMDATA) {
      opCode = CustomDataOpcode.read(opcodeType, bytes);
    } else if (
      opcodeType.index >= D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_RESOURCE.index && opcodeType.index <= D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GLOBAL_FLAGS.index ||
      opcodeType.index >= D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_STREAM.index && opcodeType.index <= D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_RESOURCE_STRUCTURED.index
    ) {
      opCode = DeclarationOpcode.read(opcodeType, bytes, version);
    } else if (opcodeType == D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_SYNC) {
      opCode = SyncOpcode.read(opcodeType, bytes);
    } else {
      opCode = InstructionOpcode.read(opcodeType, bytes, startPos);
    }

    int endPos = bytes.position;
    if (endPos - startPos != opCode.size * 4) {
      throw Exception("OpCode ${opcodeType.name} size mismatch ${endPos - startPos} != ${opCode.size * 4} at 0x${startPos.toRadixString(16)}");
    }
    assert(bytes.isByteAligned);

    return opCode;
  }

  void readDefaultLength(ByteDataWrapper bytes) {
    size = bytes.readBits(7);
  }
}
