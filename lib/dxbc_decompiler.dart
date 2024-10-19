
import 'dart:io';

import 'decompiler/opcode_parser.dart';
import 'decompiler/resource_parser.dart';
import 'decompiler/state.dart';
import 'file_reader/byte_data_wrapper.dart';
import 'file_reader/dxbc_chunk.dart';

Future<void> decompileFile(String path, String? savePath) async {
  var bytes = await ByteDataWrapper.fromFile(path);
  var dbxc = Dxbc.read(bytes);
  var state = DecompilerState(dbxc);
  parseOpcodes(state);
  fixElementStructs(state);
  applyDestinationSwizzles(state);
  state.writeStructs();
  state.writeParameters();
  state.writeStatements();
  var hlsl = state.toFileString();
  if (savePath != null) {
    await File(savePath).writeAsString(hlsl);
  }
  else {
    print(hlsl);
  }
}

