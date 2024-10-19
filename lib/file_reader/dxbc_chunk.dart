
import "byte_data_wrapper.dart";
import "rdef_reader.dart";
import "shex_reader.dart";
import "signature_reader.dart";
import "stat_reader.dart";

abstract class DxbcChunkBase {
  final String chunkMagic;
  final int chunkSize;

  DxbcChunkBase.read(ByteDataWrapper bytes) :
    chunkMagic = bytes.readString(4),
    chunkSize = bytes.readUint32();
  
  static DxbcChunkBase readChunk(ByteDataWrapper bytes) {
    var type = bytes.readString(4);
    bytes.position -= 4;
    switch (type) {
      case "DXBC":
        throw Exception("DXBC chunk is not supported");
      case "ISGN":
      case "OSGN":
        return SGN.read(bytes);
      case "RDEF":
        return Rdef.read(bytes);
      case "SHEX":
        return Shex.read(bytes);
      case "STAT":
        return Stat.read(bytes);
      default:
        return UnknownDxbcChunk.read(bytes);
    }
  }
}

class UnknownDxbcChunk extends DxbcChunkBase {
  late final List<int> data;

  UnknownDxbcChunk.read(ByteDataWrapper bytes) : super.read(bytes) {
    data = bytes.readUint8List(chunkSize);
  }
}

class Dxbc {
  final List<DxbcChunkBase> chunks = [];

  Dxbc.read(ByteDataWrapper bytes) {
    var magic = bytes.readString(4);
    if (magic != "DXBC") {
      throw Exception("Invalid DXBC magic: $magic");
    }
    bytes.position += 16; // skip hash
    bytes.position += 4; // skip version
    bytes.position += 4; // skip size
    var partCount = bytes.readUint32();
    var partOffsets = bytes.readUint32List(partCount);
    for (var offset in partOffsets) {
      bytes.position = offset;
      chunks.add(DxbcChunkBase.readChunk(bytes));
    }
  }
}
