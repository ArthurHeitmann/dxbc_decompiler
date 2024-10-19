
import '../byte_data_wrapper.dart';
import 'opcode.dart';


class SyncOpcode extends Opcode {
  late final bool threadsInGroup;
  late final bool threadGroupSharedMemory;
  late final bool unorderedAccessViewMemoryGroup;
  late final bool unorderedAccessViewMemoryGlobal;

  SyncOpcode.read(super.opcodeType, ByteDataWrapper bytes) {
    threadsInGroup = bytes.readBits(1) != 0;
    threadGroupSharedMemory = bytes.readBits(1) != 0;
    unorderedAccessViewMemoryGroup = bytes.readBits(1) != 0;
    unorderedAccessViewMemoryGlobal = bytes.readBits(1) != 0;
    bytes.readBits(9); // reserved
    readDefaultLength(bytes);
    var isExtended = bytes.readBits(1);
    assert(isExtended == 0);
  }
}
