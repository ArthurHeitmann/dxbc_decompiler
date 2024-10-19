
import 'dart:math';

import '../file_reader/dxbc_enums.dart';
import '../file_reader/shex/declare_opcode.dart';
import '../file_reader/shex/instruction_opcode.dart';
import '../file_reader/shex/opcode.dart';
import '../file_reader/rdef_reader.dart';
import 'data_type.dart';
import 'resource_binding.dart';
import 'state.dart';
import 'statements.dart';


void parseDeclResourceBinding(DeclarationWithRegisterOpcode decl, DecompilerState state) {
  var registerExp = Register.fromOperand(state, decl.registerIndex, applyModifiers: false);
  var register = registerExp.index;
  var bindingType = _opcodeToResourceBindingType[decl.opcodeType];
  if (bindingType == null)
    throw Exception("Unhandled declaration opcode type: ${decl.opcodeType.name}");
  var binding = state.rdef.resourceBindings.where((binding) => binding.bindPoint == register && _shaderInputToResourceBindingType[binding.type] == bindingType).first;
  var bindingStructs = state.structDefinitions
    .where((struct) => struct.name == binding.name && (struct.register == null || struct.register == register))
    .toList();

  ResourceBinding resourceBinding;
  switch (bindingType) {
    case ResourceBindingType.constantBuffer:
      if (!bindingStructs.isNotEmpty)
        throw Exception("No struct definition found for constant buffer: ${binding.name}");
      var bindingStruct = bindingStructs[0].type;
      if (bindingStructs.length > 1)
        throw Exception("Multiple struct definitions found for constant buffer: ${binding.name}");
      bindingStructs[0].type.includeInOutput = false;
      resourceBinding = ConstantBufferBinding(
        binding.name,
        registerExp,
        bindingStruct.members,
      );
      break;
    case ResourceBindingType.buffer:
      DataType? inner;
      if (binding.type != D3dShaderInputType.D3D_SIT_BYTEADDRESS)
        inner = _getElementMember(bindingStructs, register, binding);
      resourceBinding = TemplateBinding(
        binding.name,
        registerExp,
        _shaderInputToClassName[binding.type]!,
        inner,
      );
      break;
    case ResourceBindingType.texture:
      var textureScalarType = _resourceReturnToBindingType[binding.returnType];
      if (textureScalarType == null)
        throw Exception("Unhandled texture return type: ${binding.returnType.name}");
      var textureComponentCount = binding.textureComponentCount;
      DataType textureInnerType;
      if (textureComponentCount > 1)
        textureInnerType = VectorDataType(textureScalarType, textureComponentCount);
      else
        textureInnerType = ScalarDataType(textureScalarType);
      resourceBinding = TemplateBinding(
        binding.name,
        registerExp,
        _textureResourceDimensionToClassName[(decl as ResourceDeclarationOpcode).resourceDimension]!,
        textureInnerType,
      );
      break;
    case ResourceBindingType.sampler:
      resourceBinding = TemplateBinding(
        binding.name,
        registerExp,
        _shaderInputToClassName[binding.type]!,
        null,
      );
      break;
    case ResourceBindingType.uav:
      DataType? innerType;
      if (binding.type != D3dShaderInputType.D3D_SIT_UAV_RWBYTEADDRESS)
        innerType = _getElementMember(bindingStructs, register, binding);
      resourceBinding = TemplateBinding(
        binding.name,
        registerExp,
        _shaderInputToClassName[binding.type]!,
        innerType,
      );
      break;
    case ResourceBindingType.struct:
      var innerType = _getElementMember(bindingStructs, register, binding);
      resourceBinding = TemplateBinding(
        binding.name,
        registerExp,
        _shaderInputToClassName[binding.type]!,
        innerType,
      );
      
      break;
    default:
      throw Exception("Unhandled resource binding type: $bindingType");
  }
  state.registerBindings[(registerExp.type, register)] = resourceBinding;
  resourceBinding.writeDeclaration(state);
}

const _shaderInputToResourceBindingType = {
  D3dShaderInputType.D3D_SIT_CBUFFER: ResourceBindingType.constantBuffer,
  D3dShaderInputType.D3D_SIT_TBUFFER: ResourceBindingType.buffer, // RWTexture1D/2D/3D/Array
  D3dShaderInputType.D3D_SIT_TEXTURE: ResourceBindingType.texture,  // Texture1D/2D/3D/Cube
  D3dShaderInputType.D3D_SIT_SAMPLER: ResourceBindingType.sampler,  // SamplerState
  D3dShaderInputType.D3D_SIT_UAV_RWTYPED: ResourceBindingType.uav,  // RWBuffer
  D3dShaderInputType.D3D_SIT_STRUCTURED: ResourceBindingType.struct,  // StructuredBuffer
  D3dShaderInputType.D3D_SIT_UAV_RWSTRUCTURED: ResourceBindingType.uav, // RWStructuredBuffer
  D3dShaderInputType.D3D_SIT_BYTEADDRESS: ResourceBindingType.buffer, // ByteAddressBuffer
  D3dShaderInputType.D3D_SIT_UAV_RWBYTEADDRESS: ResourceBindingType.uav,  // RWByteAddressBuffer
  D3dShaderInputType.D3D_SIT_UAV_APPEND_STRUCTURED: ResourceBindingType.uav,  // AppendStructuredBuffer
  D3dShaderInputType.D3D_SIT_UAV_CONSUME_STRUCTURED: ResourceBindingType.uav, // ConsumeStructuredBuffer
  D3dShaderInputType.D3D_SIT_UAV_RWSTRUCTURED_WITH_COUNTER: ResourceBindingType.uav,  // RWStructuredBuffer
};

const _opcodeToResourceBindingType = {
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_RESOURCE: ResourceBindingType.texture,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_CONSTANT_BUFFER: ResourceBindingType.constantBuffer,
  D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_SAMPLER: ResourceBindingType.sampler,
  D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_RESOURCE_STRUCTURED: ResourceBindingType.struct,
  D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_TYPED: ResourceBindingType.uav,
  D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_RAW: ResourceBindingType.uav,
  D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_STRUCTURED: ResourceBindingType.uav,
};

const _resourceReturnToBindingType = {
  D3D10_SB_RESOURCE_RETURN_TYPE.D3D10_SB_RETURN_TYPE_FLOAT: ScalarType.float,
  D3D10_SB_RESOURCE_RETURN_TYPE.D3D10_SB_RETURN_TYPE_SINT: ScalarType.int_,
  D3D10_SB_RESOURCE_RETURN_TYPE.D3D10_SB_RETURN_TYPE_UINT: ScalarType.uint,
};

const _shaderInputToClassName = {
  D3dShaderInputType.D3D_SIT_TBUFFER: "RWTexture",
  // D3dShaderInputType.D3D_SIT_TEXTURE: "Texture",
  D3dShaderInputType.D3D_SIT_SAMPLER: "SamplerState",
  D3dShaderInputType.D3D_SIT_UAV_RWTYPED: "RWBuffer",
  D3dShaderInputType.D3D_SIT_STRUCTURED: "StructuredBuffer",
  D3dShaderInputType.D3D_SIT_UAV_RWSTRUCTURED: "RWStructuredBuffer",
  D3dShaderInputType.D3D_SIT_BYTEADDRESS: "ByteAddressBuffer",
  D3dShaderInputType.D3D_SIT_UAV_RWBYTEADDRESS: "RWByteAddressBuffer",
  D3dShaderInputType.D3D_SIT_UAV_APPEND_STRUCTURED: "AppendStructuredBuffer",
  D3dShaderInputType.D3D_SIT_UAV_CONSUME_STRUCTURED: "ConsumeStructuredBuffer",
  D3dShaderInputType.D3D_SIT_UAV_RWSTRUCTURED_WITH_COUNTER: "RWStructuredBuffer",
};

const _textureResourceDimensionToClassName = {
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE1D: "Texture1D",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE2D: "Texture2D",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE2DMS: "Texture2DMS",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE3D: "Texture3D",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURECUBE: "TextureCube",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE1DARRAY: "Texture1DArray",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE2DARRAY: "Texture2DArray",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURE2DMSARRAY: "Texture2DMSArray",
  D3D10_SB_RESOURCE_DIMENSION.D3D10_SB_RESOURCE_DIMENSION_TEXTURECUBEARRAY: "TextureCubeArray",
};

void fixElementStructs(DecompilerState state) {
  for (int i = 0; i < state.structDefinitions.length; i++) {
    var structBinding = state.structDefinitions[i];
    var struct = structBinding.type;
    if (struct.members.length != 1)
      continue;
    var firstMember = struct.members[0];
    if (firstMember.name != "\$Element" || firstMember.type is! StructDataType)
      continue;
    // struct.members.clear();
    // struct.members.addAll((firstMember.type as StructDataType).members);
    (firstMember.type as StructDataType).includeInOutput = struct.includeInOutput;
    state.structDefinitions[i] = (
      name: structBinding.name,
      type: firstMember.type as StructDataType,
      register: structBinding.register,
    );
  }
}

DataType _getElementMember(List<({String name, StructDataType type, int? register})> structDefinitions, int register, RdefResourceBinding binding) {
  var scalarType = _resourceReturnToBindingType[binding.returnType];
  if (scalarType != null)
    return ScalarDataType(scalarType);
  if (structDefinitions.length != 1)
    throw Exception("Unexpected number of struct definitions for struct: ${binding.name}");
  var bindingStruct = structDefinitions[0];
  if (bindingStruct.type.members.length != 1)
    throw Exception("Unexpected number of members in buffer struct: ${bindingStruct.type.members.length}");
  var member = bindingStruct.type.members[0];
  if (member.name != "\$Element")
    throw Exception("Unexpected member name in buffer struct: ${member.name}");
  if (member.type is! StructDataType)
    bindingStruct.type.includeInOutput = false;
  return member.type;
}

class _DeduplicationData {
  final Set<int> candidateRegisters = {};
  int? finalRegister;

  bool get hasSingleCandidate => finalRegister == null && candidateRegisters.length == 1;
}

void parseStructDefinitions(DecompilerState state) {
  Map<String, List<StructDataType>> structDefinitions = {};
  for (var constBuffer in state.rdef.constantBuffers) {
    var structName = constBuffer.name;
    var structMembers = constBuffer.constants.map(_parseRdefConstant).toList();
    var structType = StructDataType(structMembers, structName, constBuffer.size);
    var structList = structDefinitions.putIfAbsent(structName, () => []);
    structList.add(structType);
  }
  
  for (var structDef in structDefinitions.entries) {
    if (structDef.value.length == 1) {
      state.structDefinitions.add((name: structDef.key, type: structDef.value[0], register: null));
    }
    else {
      var structs = _deduplicateStructs(state.rdef, structDef.value, state.opcodes);
      for (var struct in structs) {
        state.structDefinitions.add((name: structDef.key, type: struct.type, register: struct.duplicates.finalRegister));
      }
    }
  }
}

List<({StructDataType type, _DeduplicationData duplicates})> _deduplicateStructs(Rdef rdef, List<StructDataType> structs, List<Opcode> opcodes) {
  var structName = structs.first.name;
  var relevantRegisters = rdef.resourceBindings
    .where((binding) => binding.type == D3dShaderInputType.D3D_SIT_CBUFFER)
    .where((binding) => binding.name == structName)
    .map((binding) => binding.bindPoint)
    .toList();
  
  var declOpcodes = opcodes
    .whereType<ConstantBufferDeclarationOpcode>()
    .where((op) => relevantRegisters.contains(op.registerIndex.indexData![0].index!))
    .toList();

  if (structs.length != relevantRegisters.length || structs.length != declOpcodes.length)
    throw Exception("Struct count mismatch: ${structs.length} structs, ${relevantRegisters.length} relevant registers, ${declOpcodes.length} declaration opcodes");
  
  var registerOperandOffsets = opcodes
    .whereType<InstructionOpcode>()
    .map((op) => op.operands)
    .expand((operands) => operands)
    .where((operand) => operand.operandType == D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_CONSTANT_BUFFER)
    .where((operand) => operand.indexData![1].index != null)
    .where((operand) => relevantRegisters.contains(operand.indexData![0].index!))
    .map((operand) => (operand.indexData!.map((index) => index.index!).take(2).toList()));
  Map<int, int> registerMaxOffsets = {};
  for (var registerOffset in registerOperandOffsets) {
    var register = registerOffset[0];
    var offset = registerOffset[1];
    registerMaxOffsets[register] = max(registerMaxOffsets[register] ?? 0, offset);
  }
  
  var declSizes = {
    for (var op in declOpcodes)
      op.registerIndex.indexData![0].index!: op.registerIndex.indexData![1].index!,
  };

  var result = structs.map((struct) => (type: struct, duplicates: _DeduplicationData())).toList();
  // collect candidate registers
  for (var (type: struct, duplicates: duplicates) in result) {
    var usedSize = struct.calcUsedSize();
    for (var register in relevantRegisters) {
      var declSize = declSizes[register]!;
      var maxOffset = registerMaxOffsets[register]!;
      if (declSize > usedSize || maxOffset > usedSize)
        continue;
      duplicates.candidateRegisters.add(register);
    }
  }
  // find final registers
  while (true) {
    var singleRegisterStructs = result.where((struct) => struct.duplicates.hasSingleCandidate).toList();
    if (singleRegisterStructs.isEmpty)
      break;
    for (var (type: _, duplicates: singleDuplicates) in singleRegisterStructs) {
      var register = singleDuplicates.candidateRegisters.first;
      singleDuplicates.finalRegister = register;
      singleDuplicates.candidateRegisters.clear();
      for (var (type: _, duplicates: resultDuplicates) in result) {
        if (singleDuplicates == resultDuplicates)
          continue;
        resultDuplicates.candidateRegisters.remove(register);
      }
    }
  }

  if (result.any((struct) => struct.duplicates.finalRegister == null)) {
    // fallback to: decl opcode order == struct order
    for (int i = 0; i < structs.length; i++) {
      var duplicates = result[i].duplicates;
      duplicates.finalRegister ??= relevantRegisters[i];
    }
  }

  return result;
}

StructMember _parseRdefConstant(RdefConstant constant) {
  return StructMember(
    constant.name,
    _parseRdefType(constant.type, size: constant.size ~/ max(1, constant.type.wElements)),
    constant.type.wElements,
    constant.size,
    constant.offset,
    hasUsages: constant.hasUsages,
  );
}

DataType _parseRdefType(RdefType type, {int? size}) {
  switch (type.wClass) {
    case D3dShaderVariableClass.D3D10_SVC_SCALAR:
      assert(type.wColumns == 1);
      assert(type.wRows == 1);
      assert(type.wMembers == 0);
      return ScalarDataType(_variableTypeToScalar(type.wType));
    case D3dShaderVariableClass.D3D10_SVC_VECTOR:
      assert(type.wRows == 1);
      assert(type.wMembers == 0);
      return VectorDataType(_variableTypeToScalar(type.wType), type.wColumns);
    case D3dShaderVariableClass.D3D10_SVC_MATRIX_COLUMNS:
      assert(type.wMembers == 0);
      return MatrixDataType(_variableTypeToScalar(type.wType), type.wRows, type.wColumns);
    case D3dShaderVariableClass.D3D10_SVC_STRUCT:
      List<StructMember> members = [];
      int offset = 0;
      for (var member in type.members) {
        var type = _parseRdefType(member.type);
        members.add(StructMember(
          member.name,
          type,
          member.type.wElements,
          type.size,
          offset,
        ));
        offset += type.size;
      }
      return StructDataType(
        members,
        type.name,
        size!,
        includeInOutput: false,
      );
    default:
      throw Exception("Unsupported variable class: ${type.wClass.name}");
  }
}

ScalarType _variableTypeToScalar(D3dShaderVariableType variableType) {
  switch (variableType) {
    case D3dShaderVariableType.D3D10_SVT_BOOL:
      return ScalarType.bool;
    case D3dShaderVariableType.D3D10_SVT_INT:
      return ScalarType.int_;
    case D3dShaderVariableType.D3D10_SVT_UINT:
      return ScalarType.uint;
    case D3dShaderVariableType.D3D10_SVT_FLOAT:
      return ScalarType.float;
    default:
      throw Exception("Unsupported scalar type: $variableType");
  }
}
