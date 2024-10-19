
import 'byte_data_wrapper.dart';
import 'dxbc_chunk.dart';


class Stat extends DxbcChunkBase {
  late final int instructionCount;
  late final int tempRegisterCount;
  late final int defCount;
  late final int dclCount;
  late final int floatInstructionCount;
  late final int intInstructionCount;
  late final int uintInstructionCount;
  late final int staticFlowControlCount;
  late final int dynamicFlowControlCount;
  late final int macroInstructionCount;
  late final int tempArrayCount;
  late final int arrayInstructionCount;
  late final int cutInstructionCount;
  late final int emitInstructionCount;
  late final int textureNormalInstructions;
  late final int textureLoadInstructions;
  late final int textureCompInstructions;
  late final int textureBiasInstructions;
  late final int textureGradientInstructions;
  late final List<int> reserved;

  Stat.read(ByteDataWrapper bytes) : super.read(bytes) {
    instructionCount = bytes.readUint32();
    tempRegisterCount = bytes.readUint32();
    defCount = bytes.readUint32();
    dclCount = bytes.readUint32();
    floatInstructionCount = bytes.readUint32();
    intInstructionCount = bytes.readUint32();
    uintInstructionCount = bytes.readUint32();
    staticFlowControlCount = bytes.readUint32();
    dynamicFlowControlCount = bytes.readUint32();
    macroInstructionCount = bytes.readUint32();
    tempArrayCount = bytes.readUint32();
    arrayInstructionCount = bytes.readUint32();
    cutInstructionCount = bytes.readUint32();
    emitInstructionCount = bytes.readUint32();
    textureNormalInstructions = bytes.readUint32();
    textureLoadInstructions = bytes.readUint32();
    textureCompInstructions = bytes.readUint32();
    textureBiasInstructions = bytes.readUint32();
    textureGradientInstructions = bytes.readUint32();
    reserved = List.generate(18, (index) => bytes.readUint32());
  }
}
