import 'package:dxbc_decompiler/dxbc_decompiler.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty || arguments.length > 2 || arguments.contains("--help") || arguments.contains("-h")) {
    print("Usage: dxbc_decompiler <compiled_shader_path> [output_path]");
    return;
  }
  var inputPath = arguments.first;
  var outputPath = arguments.length == 2 ? arguments.last : null;
  decompileFile(inputPath, outputPath);
}
