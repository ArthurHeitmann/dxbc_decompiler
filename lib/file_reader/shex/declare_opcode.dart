import '../byte_data_wrapper.dart';
import '../dxbc_enums.dart';
import '../shex_reader.dart';
import 'opcode.dart';
import 'operand.dart';

abstract class DeclarationOpcode extends Opcode {
  DeclarationOpcode(super.opcodeType);

  static DeclarationOpcode read(D3D10_SB_OPCODE_TYPE opcodeType, ByteDataWrapper bytes, ShexVersion version) {
    switch (opcodeType) {
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GLOBAL_FLAGS:
        return GlobalFlagsDeclaration.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_RESOURCE:
        return ResourceDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_SAMPLER:
        return SamplerDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SIV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SGV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SIV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SGV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT_SIV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT_SGV:
        return InputOutputDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_TEMPS:
        return TempRegisterDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INDEXABLE_TEMP:
        return IndexableTempDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_CONSTANT_BUFFER:
        return ConstantBufferDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GS_INPUT_PRIMITIVE:
        return InputPrimitiveDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GS_OUTPUT_PRIMITIVE_TOPOLOGY:
        return OutputPrimitiveTopologyDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_MAX_OUTPUT_VERTEX_COUNT:
        return OutputVertexCountDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_RESOURCE_STRUCTURED:
        return ResourceStructuredDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_RESOURCE_RAW:
        return ResourceRawDeclarationOpcode.read(opcodeType, bytes, version);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_RAW:
        return UavRawDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_STRUCTURED:
        return UavStructuredDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_THREAD_GROUP:
        return ThreadGroupDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_TYPED:
        return UavTypedDeclarationOpcode.read(opcodeType, bytes, version);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_THREAD_GROUP_SHARED_MEMORY_STRUCTURED:
        return ThreadGroupSharedMemoryStructuredDeclarationOpcode.read(opcodeType, bytes);
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_THREAD_GROUP_SHARED_MEMORY_RAW:
        return ThreadGroupSharedMemoryRawDeclarationOpcode.read(opcodeType, bytes);
      default:
        throw Exception("Unknown declaration opcode ${opcodeType.name}");
    }
  }

  void checkNoExtended(ByteDataWrapper bytes) {
    var isExtended = bytes.readBits(1);
    if (isExtended == 1) {
      throw Exception("Extended opcode not allowed in $opcodeType");
    }
  }
}

/// ----------------------------------------------------------------------------
/// Global Flags Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_GLOBAL_FLAGS
/// [11:11] Refactoring allowed if bit set.
/// [23:12] Reserved for future flags.
/// [30:24] Instruction length in DWORDs including the opcode token. == 1
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by no operands.
///
/// ----------------------------------------------------------------------------
class GlobalFlagsDeclaration extends DeclarationOpcode {
  late final bool refactoringAllowed;

  GlobalFlagsDeclaration.read(super.opCodeType, ByteDataWrapper bytes) {
    refactoringAllowed = bytes.readBits(1) == 1;
    bytes.readBits(12); // reserved

    readDefaultLength(bytes);
    checkNoExtended(bytes);
  }
}

enum RegisterType {
  immediate(""),
  null_("null"),
  temp("r"),
  input("v"),
  output("o"),
  indexableTemp("r"),
  indexableInput("i"),
  indexableOutput("o"),
  constantBuffer("b"),
  immediateConstantBuffer("icb"),
  sampler("s"),
  resource("t"),
  uav("u"),
  threadGroupSharedMemory("g"),
  custom("_");

  final String letter;

  const RegisterType(this.letter);
}

abstract class DeclarationWithRegisterOpcode extends DeclarationOpcode {
  final RegisterType registerType;
  late final Operand registerIndex;

  DeclarationWithRegisterOpcode(super.opCodeType, {required this.registerType});
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

/// ----------------------------------------------------------------------------
/// Resource Declaration (non multisampled)
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_RESOURCE
/// [15:11] D3D10_SB_RESOURCE_DIMENSION
/// [23:16] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) an operand, starting with OperandToken0, defining which
///     t# register (D3D10_SB_OPERAND_TYPE_RESOURCE) is being declared.
/// (2) a Resource Return Type token (ResourceReturnTypeToken)
///
/// ----------------------------------------------------------------------------
/// Resource Declaration (multisampled)
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_RESOURCE (same opcode as non-multisampled case)
/// [15:11] D3D10_SB_RESOURCE_DIMENSION (must be TEXTURE2DMS or TEXTURE2DMSARRAY)
/// [22:16] Sample count 1...127.  0 is currently disallowed, though
///         in future versions 0 could mean "configurable" sample count
/// [23:23] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) an operand, starting with OperandToken0, defining which
///     t# register (D3D10_SB_OPERAND_TYPE_RESOURCE) is being declared.
/// (2) a Resource Return Type token (ResourceReturnTypeToken)
///
/// ----------------------------------------------------------------------------
class ResourceDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final D3D10_SB_RESOURCE_DIMENSION resourceDimension;
  late final int sampleCount;
  late final ResourceReturnType returnType;

  ResourceDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.resource) {
    resourceDimension = D3D10_SB_RESOURCE_DIMENSION.values[bytes.readBits(5)];
    sampleCount = bytes.readBits(7);
    bytes.readBits(1); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    returnType = ResourceReturnType.read(bytes);
    bytes.readBits(16); // padding
  }
}

/// ----------------------------------------------------------------------------
/// Sampler Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_SAMPLER
/// [14:11] D3D10_SB_SAMPLER_MODE
/// [23:15] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 1 operand:
/// (1) Operand starting with OperandToken0, defining which sampler
///     (D3D10_SB_OPERAND_TYPE_SAMPLER) register # is being declared.
///
/// ----------------------------------------------------------------------------
class SamplerDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final D3D10_SB_SAMPLER_MODE samplerMode;

  SamplerDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.sampler) {
    samplerMode = D3D10_SB_SAMPLER_MODE.values[bytes.readBits(4)];
    bytes.readBits(9); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
  }
}

/// ----------------------------------------------------------------------------
/// Input Register Declaration (see separate declarations for Pixel Shaders)
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INPUT
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 1 operand:
/// (1) Operand, starting with OperandToken0, defining which input
///     v# register (D3D10_SB_OPERAND_TYPE_INPUT) is being declared, 
///     including writemask.
///
/// ----------------------------------------------------------------------------
/// Input Register Declaration w/System Interpreted Value
/// (see separate declarations for Pixel Shaders)
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INPUT_SIV
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) Operand, starting with OperandToken0, defining which input
///     v# register (D3D10_SB_OPERAND_TYPE_INPUT) is being declared,
///     including writemask.  For Geometry Shaders, the input is 
///     v[vertex][attribute], and this declaration is only for which register 
///     on the attribute axis is being declared.  The vertex axis value must 
///     be equal to the # of vertices in the current input primitive for the GS
///     (i.e. 6 for triangle + adjacency).
/// (2) a System Interpreted Value Name (NameToken)
/// ----------------------------------------------------------------------------
/// Input Register Declaration w/System Generated Value
/// (available for all shaders incl. Pixel Shader, no interpolation mode needed)
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INPUT_SGV
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) Operand, starting with OperandToken0, defining which input
///     v# register (D3D10_SB_OPERAND_TYPE_INPUT) is being declared,
///     including writemask.
/// (2) a System Generated Value Name (NameToken)
/// ----------------------------------------------------------------------------
/// Pixel Shader Input Register Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INPUT_PS
/// [14:11] D3D10_SB_INTERPOLATION_MODE
/// [23:15] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 1 operand:
/// (1) Operand, starting with OperandToken0, defining which input
///     v# register (D3D10_SB_OPERAND_TYPE_INPUT) is being declared,
///     including writemask.
/// ----------------------------------------------------------------------------
/// Pixel Shader Input Register Declaration w/System Interpreted Value
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INPUT_PS_SIV
/// [14:11] D3D10_SB_INTERPOLATION_MODE
/// [23:15] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) Operand, starting with OperandToken0, defining which input
///     v# register (D3D10_SB_OPERAND_TYPE_INPUT) is being declared.
/// (2) a System Interpreted Value Name (NameToken)
/// ----------------------------------------------------------------------------
/// Pixel Shader Input Register Declaration w/System Generated Value
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INPUT_PS_SGV
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) Operand, starting with OperandToken0, defining which input
///     v# register (D3D10_SB_OPERAND_TYPE_INPUT) is being declared.
/// (2) a System Generated Value Name (NameToken)
/// ----------------------------------------------------------------------------
/// Output Register Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_OUTPUT
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 1 operand:
/// (1) Operand, starting with OperandToken0, defining which
///     o# register (D3D10_SB_OPERAND_TYPE_OUTPUT) is being declared,
///     including writemask.
///     (in Pixel Shader, output can also be D3D10_SB_OPERAND_TYPE_OUTPUT_DEPTH)
///
/// ----------------------------------------------------------------------------
/// Output Register Declaration w/System Interpreted Value
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_OUTPUT_SIV
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) an operand, starting with OperandToken0, defining which
///     o# register (D3D10_SB_OPERAND_TYPE_OUTPUT) is being declared,
///     including writemask.
/// (2) a System Interpreted Name token (NameToken)
///
/// ----------------------------------------------------------------------------
/// Output Register Declaration w/System Generated Value
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_OUTPUT_SGV
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) an operand, starting with OperandToken0, defining which
///     o# register (D3D10_SB_OPERAND_TYPE_OUTPUT) is being declared,
///     including writemask.
/// (2) a System Generated Name token (NameToken)
///
/// ----------------------------------------------------------------------------
class InputOutputDeclarationOpcode extends DeclarationWithRegisterOpcode {
  D3D10_SB_INTERPOLATION_MODE? interpolationMode;
  D3D10_SB_NAME? systemValueName;

  InputOutputDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: _inputOpcodes.contains(opCodeType) ? RegisterType.input : RegisterType.output) {
    if (_interpolatedOpcodes.contains(opcodeType)) {
      interpolationMode = D3D10_SB_INTERPOLATION_MODE.values[bytes.readBits(4)];
      bytes.readBits(9); // ignored
    }
    else {
      bytes.readBits(13); // ignored
    }
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    if (_nameTokenOpcodes.contains(opcodeType)) {
      systemValueName = D3D10_SB_NAME.values[bytes.readBits(16)];
      bytes.readBits(16); // reserved
    }
  }
}
const _inputOpcodes = [
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SIV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SGV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SIV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SGV,
];
const _interpolatedOpcodes = [
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SIV,
];
const _nameTokenOpcodes = [
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SIV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SGV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SIV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SGV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT_SIV,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT_SGV,
];

/// ----------------------------------------------------------------------------
/// Input or Output Register Indexing Range Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INDEX_RANGE
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) an operand, starting with OperandToken0, defining which
///     input (v#) or output (o#) register is having its array indexing range
///     declared, including writemask.  For Geometry Shader inputs, 
///     it is assumed that the vertex axis is always fully indexable,
///     and 0 must be specified as the vertex# in this declaration, so that 
///     only the a range of attributes are having their index range defined.
///     
/// (2) a DWORD representing the count of registers starting from the one
///     indicated in (1).
///
/// ----------------------------------------------------------------------------
// class IndexingRangeDeclarationOpcode extends DeclarationWithRegisterOpcode {
//   late final int registerCount;

//  IndexingRangeDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
//     : super(registerType: RegisterType.) {
//     bytes.readBits(13); // ignored
//     readDefaultLength(bytes);
//     checkNoExtended(bytes);
//     registerIndex = Operand.read(bytes);
//     registerCount = bytes.readUint32();
//   }
// }

/// ----------------------------------------------------------------------------
/// Temp Register Declaration r0...r(n-1) 
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_TEMPS
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 1 operand:
/// (1) DWORD (unsigned int) indicating how many temps are being declared.  
///     i.e. 5 means r0...r4 are declared.
///
/// ----------------------------------------------------------------------------
class TempRegisterDeclarationOpcode extends DeclarationOpcode {
  late final int registerCount;

  TempRegisterDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerCount = bytes.readUint32();
  }
}

/// ----------------------------------------------------------------------------
/// Indexable Temp Register (x#[size]) Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_INDEXABLE_TEMP
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 3 DWORDs:
/// (1) Register index (defines which x# register is declared)
/// (2) Number of registers in this register bank
/// (3) Number of components in the array (1-4). 1 means .x, 2 means .xy etc.
///
/// ----------------------------------------------------------------------------
class IndexableTempDeclarationOpcode extends DeclarationOpcode {
  late final int registerIndex;
  late final int registerCount;
  late final int componentCount;

  IndexableTempDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = bytes.readUint32();
    registerCount = bytes.readUint32();
    componentCount = bytes.readUint32();
  }
}

/// ----------------------------------------------------------------------------
/// Constant Buffer Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_CONSTANT_BUFFER
/// [11]    D3D10_SB_CONSTANT_BUFFER_ACCESS_PATTERN
/// [23:12] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 1 operand:
/// (1) Operand, starting with OperandToken0, defining which CB slot (cb#[size])
///     is being declared. (operand type: D3D10_SB_OPERAND_TYPE_CONSTANT_BUFFER)
///     The indexing dimension for the register must be 
///     D3D10_SB_OPERAND_INDEX_DIMENSION_2D, where the first index specifies
///     which cb#[] is being declared, and the second (array) index specifies the size 
///     of the buffer, as a count of 32-bit*4 elements.  (As opposed to when the 
///     cb#[] is used in shader instructions, and the array index represents which 
///     location in the constant buffer is being referenced.)
///     If the size is specified as 0, the CB size is not known (any size CB
///     can be bound to the slot).
///
/// The order of constant buffer declarations in a shader indicates their
/// relative priority from highest to lowest (hint to driver).
/// 
/// ----------------------------------------------------------------------------
class ConstantBufferDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final D3D10_SB_CONSTANT_BUFFER_ACCESS_PATTERN accessPattern;

  ConstantBufferDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) : super(registerType: RegisterType.constantBuffer) {
    accessPattern = D3D10_SB_CONSTANT_BUFFER_ACCESS_PATTERN.values[bytes.readBits(1)];
    bytes.readBits(12); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
  }
}

/// ----------------------------------------------------------------------------
/// Geometry Shader Input Primitive Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_GS_INPUT_PRIMITIVE
/// [16:11] D3D10_SB_PRIMITIVE [not D3D10_SB_PRIMITIVE_TOPOLOGY]
/// [23:17] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token. == 1
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// ----------------------------------------------------------------------------
class InputPrimitiveDeclarationOpcode extends DeclarationOpcode {
  late final D3D10_SB_PRIMITIVE inputPrimitive;

  InputPrimitiveDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) {
    inputPrimitive = D3D10_SB_PRIMITIVE.values[bytes.readBits(6)];
    bytes.readBits(7); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
  }
}

/// ----------------------------------------------------------------------------
/// Geometry Shader Output Topology Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_GS_OUTPUT_PRIMITIVE_TOPOLOGY
/// [16:11] D3D10_SB_PRIMITIVE_TOPOLOGY
/// [23:17] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token. == 1
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// ----------------------------------------------------------------------------
class OutputPrimitiveTopologyDeclarationOpcode extends DeclarationOpcode {
  late final D3D10_SB_PRIMITIVE_TOPOLOGY outputTopology;

  OutputPrimitiveTopologyDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) {
    outputTopology = D3D10_SB_PRIMITIVE_TOPOLOGY.values[bytes.readBits(6)];
    bytes.readBits(7); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
  }
}

/// ----------------------------------------------------------------------------
/// Geometry Shader Maximum Output Vertex Count Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D10_SB_OPCODE_DCL_MAX_OUTPUT_VERTEX_COUNT
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by a DWORD representing the
/// maximum number of primitives that could be output
/// by the Geometry Shader.
///
/// ----------------------------------------------------------------------------
class OutputVertexCountDeclarationOpcode extends DeclarationOpcode {
  late final int maxOutputVertexCount;

  OutputVertexCountDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    maxOutputVertexCount = bytes.readUint32();
  }
}

/// ----------------------------------------------------------------------------
/// Structured Shader Resource View Declaration
///
/// OpcodeToken0:
///
/// [10:00] D3D11_SB_OPCODE_DCL_RESOURCE_STRUCTURED
/// [23:11] Ignored, 0
/// [30:24] Instruction length in DWORDs including the opcode token.
/// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
///         contains extended operand description.  This dcl is currently not
///         extended.
///
/// OpcodeToken0 is followed by 2 operands:
/// (1) an operand, starting with OperandToken0, defining which
///     g# register (D3D10_SB_OPERAND_TYPE_RESOURCE) is 
///     being declared.
/// (2) a DWORD indicating UINT32 struct byte stride
///
/// ----------------------------------------------------------------------------
class ResourceStructuredDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final int structByteStride;

  ResourceStructuredDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.resource) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    structByteStride = bytes.readUint32();
  }
}

// ----------------------------------------------------------------------------
// Raw Shader Resource View Declaration
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_RESOURCE_RAW
// [23:11] Ignored, 0
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  This dcl is currently not
//         extended.
//
// OpcodeToken0 is followed by 1 operand:
// (1) an operand, starting with OperandToken0, defining which
//     t# register (D3D10_SB_OPERAND_TYPE_RESOURCE) is being declared.
//
// OpcodeToken0 is followed by 2 operands on Shader Model 5.1 and later:
// (1) an operand, starting with OperandToken0, defining which
//     t# register (D3D10_SB_OPERAND_TYPE_RESOURCE) is being declared.
//     The indexing dimension for the register must be D3D10_SB_OPERAND_INDEX_DIMENSION_3D, 
//     and the meaning of the index dimensions are as follows: (t<id>[<lbound>:<ubound>])
//       1 <id>:     variable ID being declared
//       2 <lbound>: the lower bound of the range of resources in the space
//       3 <ubound>: the upper bound (inclusive) of this range
//     As opposed to when the t# is used in shader instructions, where the register
//     must be D3D10_SB_OPERAND_INDEX_DIMENSION_2D, and the meaning of the index 
//     dimensions are as follows: (t<id>[<idx>]):
//       1 <id>:  variable ID being used (matches dcl)
//       2 <idx>: absolute index of resource within space (may be dynamically indexed)
// (2) a DWORD indicating the space index.
//
// ----------------------------------------------------------------------------
class ResourceRawDeclarationOpcode extends DeclarationWithRegisterOpcode {
  int? spaceIndex;

  ResourceRawDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes, ShexVersion version)
    : super(registerType: RegisterType.resource) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    if (version.is51)
      spaceIndex = bytes.readUint32();
  }
}

// ----------------------------------------------------------------------------
// Raw Unordered Access View Declaration
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_RAW
// [15:11] Ignored, 0
// [16:16] D3D11_SB_GLOBALLY_COHERENT_ACCESS or 0 (LOCALLY_COHERENT)
// [23:17] Ignored, 0
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  This dcl is currently not
//         extended.
//
// OpcodeToken0 is followed by 1 operand:
// (1) an operand, starting with OperandToken0, defining which
//     u# register (D3D11_SB_OPERAND_TYPE_UNORDERED_ACCESS_VIEW) is being declared.
//
// ----------------------------------------------------------------------------
class UavRawDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final bool globallyCoherent;

  UavRawDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.uav) {
    bytes.readBits(5); // ignored
    globallyCoherent = bytes.readBits(1) == 1;
    bytes.readBits(7); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
  }
}

// ----------------------------------------------------------------------------
// Structured Unordered Access View Declaration
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_STRUCTURED
// [15:11] Ignored, 0
// [16:16] D3D11_SB_GLOBALLY_COHERENT_ACCESS or 0 (LOCALLY_COHERENT)
// [22:17] Ignored, 0
// [23:23] D3D11_SB_UAV_HAS_ORDER_PRESERVING_COUNTER or 0
//
//            The presence of this flag means that if a UAV is bound to the
//            corresponding slot, it must have been created with 
//            D3D11_BUFFER_UAV_FLAG_COUNTER at the API.  Also, the shader
//            can contain either imm_atomic_alloc or _consume instructions
//            operating on the given UAV.
// 
//            If this flag is not present, the shader can still contain
//            either imm_atomic_alloc or imm_atomic_consume instructions for
//            this UAV.  But if such instructions are present in this case,
//            and a UAV is bound corresponding slot, it must have been created 
//            with the D3D11_BUFFER_UAV_FLAG_APPEND flag at the API.
//            Append buffers have a counter as well, but values returned 
//            to the shader are only valid for the lifetime of the shader 
//            invocation.
//
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  This dcl is currently not
//         extended.
//
// OpcodeToken0 is followed by 2 operands:
// (1) an operand, starting with OperandToken0, defining which
//     u# register (D3D11_SB_OPERAND_TYPE_UNORDERED_ACCESS_VIEW) is 
//     being declared.
// (2) a DWORD indicating UINT32 byte stride
class UavStructuredDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final bool globallyCoherent;
  late final bool hasOrderPreservingCounter;
  late final int byteStride;

  UavStructuredDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.uav) {
    bytes.readBits(5); // ignored
    globallyCoherent = bytes.readBits(1) == 1;
    bytes.readBits(6); // ignored
    hasOrderPreservingCounter = bytes.readBits(1) == 1;
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    byteStride = bytes.readUint32();
  }
}

// ----------------------------------------------------------------------------
// Thread Group Declaration (Compute Shader)
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_THREAD_GROUP
// [23:11] Ignored, 0
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  If it is extended, then
//         it contains the actual instruction length in DWORDs, since
//         it may not fit into 7 bits if enough types are used.
//
// OpcodeToken0 is followed by 3 DWORDs, the Thread Group dimensions as UINT32:
// x, y, z
//
// ----------------------------------------------------------------------------
class ThreadGroupDeclarationOpcode extends DeclarationOpcode {
  late final int x;
  late final int y;
  late final int z;

  ThreadGroupDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    x = bytes.readUint32();
    y = bytes.readUint32();
    z = bytes.readUint32();
  }
}

// ----------------------------------------------------------------------------
// Typed Unordered Access View Declaration
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_TYPED
// [15:11] D3D10_SB_RESOURCE_DIMENSION
// [16:16] D3D11_SB_GLOBALLY_COHERENT_ACCESS or 0 (LOCALLY_COHERENT)
// [17:17] D3D11_SB_RASTERIZER_ORDERED_ACCESS or 0
// [23:18] Ignored, 0
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  This dcl is currently not
//         extended.
//
// OpcodeToken0 is followed by 2 operands on Shader Models 4.0 through 5.0:
// (1) an operand, starting with OperandToken0, defining which
//     u# register (D3D11_SB_OPERAND_TYPE_UNORDERED_ACCESS_VIEW) is being declared.
// (2) a Resource Return Type token (ResourceReturnTypeToken)
//
// OpcodeToken0 is followed by 3 operands on Shader Model 5.1 and later:
// (1) an operand, starting with OperandToken0, defining which
//     u# register (D3D11_SB_OPERAND_TYPE_UNORDERED_ACCESS_VIEW) is being declared.
//     The indexing dimension for the register must be D3D10_SB_OPERAND_INDEX_DIMENSION_3D, 
//     and the meaning of the index dimensions are as follows: (u<id>[<lbound>:<ubound>])
//       1 <id>:     variable ID being declared
//       2 <lbound>: the lower bound of the range of UAV's in the space
//       3 <ubound>: the upper bound (inclusive) of this range
//     As opposed to when the u# is used in shader instructions, where the register
//     must be D3D10_SB_OPERAND_INDEX_DIMENSION_2D, and the meaning of the index 
//     dimensions are as follows: (u<id>[<idx>]):
//       1 <id>:  variable ID being used (matches dcl)
//       2 <idx>: absolute index of uav within space (may be dynamically indexed)
// (2) a Resource Return Type token (ResourceReturnTypeToken)
// (3) a DWORD indicating the space index.
//
// ----------------------------------------------------------------------------
class UavTypedDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final D3D10_SB_RESOURCE_DIMENSION resourceDimension;
  late final bool globallyCoherent;
  late final bool rasterizerOrderedAccess;
  late final ResourceReturnType returnType;
  int? spaceIndex;

  UavTypedDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes, ShexVersion version)
    : super(registerType: RegisterType.uav) {
    resourceDimension = D3D10_SB_RESOURCE_DIMENSION.values[bytes.readBits(5)];
    globallyCoherent = bytes.readBits(1) == 1;
    rasterizerOrderedAccess = bytes.readBits(1) == 1;
    bytes.readBits(6); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    returnType = ResourceReturnType.read(bytes);
    bytes.readBits(16); // padding
    if (version.is51)
      spaceIndex = bytes.readUint32();
  }
}

// ----------------------------------------------------------------------------
// Structured Thread Group Shared Memory Declaration
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_THREAD_GROUP_SHARED_MEMORY_STRUCTURED
// [23:11] Ignored, 0
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  This dcl is currently not
//         extended.
//
// OpcodeToken0 is followed by 3 operands:
// (1) an operand, starting with OperandToken0, defining which
//     g# register (D3D11_SB_OPERAND_TYPE_THREAD_GROUP_SHARED_MEMORY) is 
//     being declared.
// (2) a DWORD indicating UINT32 struct byte stride
// (3) a DWORD indicating UINT32 struct count
//
// ----------------------------------------------------------------------------
class ThreadGroupSharedMemoryStructuredDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final int stride;
  late final int count;

  ThreadGroupSharedMemoryStructuredDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.threadGroupSharedMemory) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    stride = bytes.readUint32();
    count = bytes.readUint32();
  }
}

// ----------------------------------------------------------------------------
// Raw Thread Group Shared Memory Declaration
//
// OpcodeToken0:
//
// [10:00] D3D11_SB_OPCODE_DCL_THREAD_GROUP_SHARED_MEMORY_RAW
// [23:11] Ignored, 0
// [30:24] Instruction length in DWORDs including the opcode token.
// [31]    0 normally. 1 if extended operand definition, meaning next DWORD
//         contains extended operand description.  This dcl is currently not
//         extended.
//
// OpcodeToken0 is followed by 2 operands:
// (1) an operand, starting with OperandToken0, defining which
//     g# register (D3D11_SB_OPERAND_TYPE_THREAD_GROUP_SHARED_MEMORY) is being declared.
// (2) a DWORD indicating the element count, # of 32-bit scalars..
//
// ----------------------------------------------------------------------------
class ThreadGroupSharedMemoryRawDeclarationOpcode extends DeclarationWithRegisterOpcode {
  late final int count;

  ThreadGroupSharedMemoryRawDeclarationOpcode.read(super.opCodeType, ByteDataWrapper bytes)
    : super(registerType: RegisterType.threadGroupSharedMemory) {
    bytes.readBits(13); // ignored
    readDefaultLength(bytes);
    checkNoExtended(bytes);
    registerIndex = Operand.read(bytes);
    count = bytes.readUint32();
  }
}