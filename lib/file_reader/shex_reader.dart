
import 'byte_data_wrapper.dart';
import 'dxbc_chunk.dart';
import 'shex/opcode.dart';


class ShexVersion {
  late final int majorVersion;
  late final int minorVersion;

  ShexVersion.read(ByteDataWrapper bytes) {
    majorVersion = bytes.readUint8();
    minorVersion = bytes.readUint8();
  }

  bool get is51 => majorVersion == 0x51 && minorVersion == 0x00;
}

class Shex extends DxbcChunkBase {
  late final ShexVersion version;
  late final int programType;
  late final int length;
  late final List<Opcode> opCodes;

  Shex.read(ByteDataWrapper bytes) : super.read(bytes) {
    int startPos = bytes.position;
    version = ShexVersion.read(bytes);
    programType = bytes.readUint16();
    length = bytes.readUint32();

    opCodes = [];
    while (bytes.position - startPos < length * 4) {
      opCodes.add(Opcode.read(bytes, version));
    }
  }
}

