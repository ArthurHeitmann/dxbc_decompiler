
import 'byte_data_wrapper.dart';
import 'dxbc_chunk.dart';


class Signature {
  late final String semanticName;
  late final int semanticIndex;
  late final int systemValueType;
  late final int componentType;
  late final int register;
  late final int mask;

  Signature.read(ByteDataWrapper bytes, int baseOffset) {
    int semanticNameOffset = bytes.readUint32();
    semanticIndex = bytes.readUint32();
    systemValueType = bytes.readUint32();
    componentType = bytes.readUint32();
    register = bytes.readUint32();
    mask = bytes.readUint16();
    bytes.readUint16(); // padding

    int prevPos = bytes.position;
    bytes.position = baseOffset + semanticNameOffset;
    semanticName = bytes.readStringZeroTerminated();
    bytes.position = prevPos;
  }
}


class SGN extends DxbcChunkBase {
  late final List<Signature> signatures;

  SGN.read(ByteDataWrapper bytes) : super.read(bytes) {
    int baseOffset = bytes.position;
    int signatureCount = bytes.readUint32();
    bytes.readUint32(); // reserved

    signatures = List.generate(signatureCount, (index) => Signature.read(bytes, baseOffset));
  }
}
