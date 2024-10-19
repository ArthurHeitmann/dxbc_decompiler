
import 'dart:typed_data';

import '../byte_data_wrapper.dart';
import '../dxbc_enums.dart';
import 'opcode.dart';

class CustomDataOpcode extends Opcode {
  late final D3D10_SB_CUSTOMDATA_CLASS customDataClass;
  late final Uint8List? customData;

  CustomDataOpcode.read(super.opcodeType, ByteDataWrapper bytes) {
    customDataClass = D3D10_SB_CUSTOMDATA_CLASS.values[bytes.readBits(21)];
    size = bytes.readUint32();
    customData = bytes.asUint8List((size - 2) * 4);
    // if (size > 2)
    //     print("Unhandled custom data size ${size - 2}");
  }
}
