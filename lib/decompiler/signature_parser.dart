
import '../file_reader/shex/declare_opcode.dart';
import '../file_reader/signature_reader.dart';
import 'data_type.dart';
import 'resource_binding.dart';
import 'state.dart';
import 'statements.dart';

void _parseSignature(DecompilerState state, SGN sgn, InputOutputDeclarationOpcode decl, ParameterType parameterType, String name) {
  var register = decl.registerIndex.indexData![0].index!;
  var signature = sgn.signatures.where((s) => s.register == register).first;
  var semanticBase = signature.semanticName.toUpperCase();
  var dataType = _semanticToDataType[semanticBase];
  if (dataType == null) {
    throw Exception("Unknown semantic: $semanticBase");
  }
  String semanticIndex;
  if (_semanticsWithIndex.contains(semanticBase))
    semanticIndex = signature.semanticIndex.toString();
  else
    semanticIndex = "";
  var binding = ParameterResourceBinding(
    name,
    Register.fromOperand(state, decl.registerIndex),
    dataType,
    parameterType,
    signature.semanticName + semanticIndex,
  );
  state.registerBindings[(binding.register.type, binding.register.index)] = binding;
}

const Map<String, DataType> _semanticToDataType = {
  "BINORMAL":tFloat4,
  "BLENDINDICES":tUint,
  "BLENDWEIGHT":tFloat,
  "COLOR":tFloat4,
  "NORMAL":tFloat4,
  "POSITION":tFloat4,
  "POSITIONT":tFloat4,
  "PSIZE":tFloat,
  "TANGENT":tFloat4,
  "TEXCOORD":tFloat4,
  "FOG":tFloat,
  "TESSFACTOR":tFloat,
  "VFACE":tFloat,
  "VPOS":tFloat2,
  "DEPTH":tFloat,
  "SV_CLIPDISTANCE":tFloat,
  "SV_CULLDISTANCE":tFloat,
  "SV_COVERAGE":tUint,
  "SV_DEPTH":tFloat,
  "SV_DEPTHGREATEREQUAL":tFloat,
  "SV_DEPTHLESSEQUAL":tFloat,
  "SV_DISPATCHTHREADID":tUint3,
  // "SV_DOMAINLOCATION":tFloat2|3,
  "SV_GROUPID":tUint3,
  "SV_GROUPINDEX":tUint,
  "SV_GROUPTHREADID":tUint3,
  "SV_GSINSTANCEID":tUint,
  // "SV_INNERCOVERAGE":_,
  // "SV_INSIDETESSFACTOR":tFloat|float[2],
  "SV_INSTANCEID":tUint,
  "SV_ISFRONTFACE":tBool,
  "SV_OUTPUTCONTROLPOINTID":tUint,
  "SV_POSITION":tFloat4,
  "SV_PRIMITIVEID":tUint,
  "SV_RENDERTARGETARRAYINDEX":tUint,
  "SV_SAMPLEINDEX":tUint,
  "SV_STENCILREF":tUint,
  "SV_TARGET":tFloat4,
  "SV_TESSFACTOR":tFloat4,
  "SV_VERTEXID":tUint,
  "SV_VIEWPORTARRAYINDEX":tUint,
  "SV_SHADINGRATE":tUint,
};
const _semanticsWithIndex = {
  "BINORMAL",
  "BLENDINDICES",
  "BLENDWEIGHT",
  "COLOR",
  "NORMAL",
  "POSITION",
  "PSIZE",
  "TANGENT",
  "TEXCOORD",
  "TESSFACTOR",
  "DEPTH",
  "SV_ClipDistance",
  "SV_CullDistance",
  "SV_Target",
};

void parseInputSignature(DecompilerState state, InputOutputDeclarationOpcode decl) {
  _parseSignature(state, state.inputSignature!, decl, ParameterType.in_, state.nextVarName("input"));
}

void parseOutputSignature(DecompilerState state, InputOutputDeclarationOpcode decl) {
  _parseSignature(state, state.outputSignature!, decl, ParameterType.out, state.nextVarName("output"));
}
