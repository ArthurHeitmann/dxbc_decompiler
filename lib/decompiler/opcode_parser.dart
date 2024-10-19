
import '../file_reader/dxbc_enums.dart';
import '../file_reader/shex/declare_opcode.dart';
import '../file_reader/shex/instruction_opcode.dart';
import '../file_reader/shex/opcode.dart';
import 'data_type.dart';
import 'resource_binding.dart';
import 'resource_parser.dart';
import 'signature_parser.dart';
import 'state.dart';
import 'statements.dart';

void parseOpcodes(DecompilerState state) {
  for (var opcode in state.opcodes) {
    switch (opcode.opcodeType) {
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ADD:
        _parse2Exp(state, opcode, "+");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_AND:
        _parse2Exp(state, opcode, "&");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_BREAK:
        state.addStatement(KeywordStatement("break"));
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_BREAKC:
        _parseConditionalKeyword(state, opcode, "break");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CALL:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CALLC:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CASE:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CONTINUE:
        state.addStatement(KeywordStatement("continue"));
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CONTINUEC:
        _parseConditionalKeyword(state, opcode, "continue");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CUT:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DEFAULT:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DERIV_RTX:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DERIV_RTY:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DISCARD:
        state.addStatement(KeywordStatement("discard"));
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DIV:
        _parse2Exp(state, opcode, "/");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DP2:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DP3:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DP4:
        _parseFunctionCall(state, opcode, "dot");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ELSE:
        state.popBlock();
        _parseBlock(state, opcode, "else");
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_EMIT:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_EMITTHENCUT:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ENDIF:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ENDLOOP:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ENDSWITCH:
        state.popBlock();
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_EQ:
        _parse2Exp(state, opcode, "==");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_EXP:
        _parseFunctionCall(state, opcode, "exp");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_FRC:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_FTOI:
        _parseCast(state, opcode, tInt);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_FTOU:
        _parseCast(state, opcode, tUint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_GE:
        _parse2Exp(state, opcode, ">=");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IADD:
        _parse2Exp(state, opcode, "+", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IEQ:
        _parse2Exp(state, opcode, "==", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IGE:
        _parse2Exp(state, opcode, ">=", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IF:
        _parseConditionBlock(state, opcode, "if");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ILT:
        _parse2Exp(state, opcode, "<", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IMAD:
        _parse3Exp(state, opcode, "*", "+", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IMAX:
        _parseFunctionCall(state, opcode, "max", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IMIN:
        _parseFunctionCall(state, opcode, "min", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_IMUL:
        _parse2Exp(state, opcode, "*", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_INE:
        _parse2Exp(state, opcode, "!=", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_INEG:
        _parseUnaryExp(state, opcode, "-", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ISHL:
        _parse2Exp(state, opcode, "<<", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ISHR:
        _parse2Exp(state, opcode, ">>", numType: NumberType.int);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ITOF:
        _parseCast(state, opcode, tFloat, numType: NumberType.int);
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_LABEL:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_LD:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_LD_MS:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_LOG:
        _parseFunctionCall(state, opcode, "log");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_LOOP:
        _parseConditionBlock(state, opcode, "while", condition: LiteralExpression("true"));
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_LT:
        _parse2Exp(state, opcode, "<");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_MAD:
        _parse3Exp(state, opcode, "*", "+");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_MIN:
        _parseFunctionCall(state, opcode, "min");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_MAX:
        _parseFunctionCall(state, opcode, "max");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_CUSTOMDATA:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_MOV:
        _parseMove(state, opcode);
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_MOVC:
        _parse3Exp(state, opcode, "?", ":");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_MUL:
        _parse2Exp(state, opcode, "*");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_NE:
        _parse2Exp(state, opcode, "!=");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_NOP:
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_NOT:
        _parseUnaryExp(state, opcode, "~", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_OR:
        _parse2Exp(state, opcode, "|");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_RESINFO:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_RET:
        state.addStatement(KeywordStatement("return"));
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_RETC:
        _parseFunctionCall(state, opcode, "return");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ROUND_NE:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ROUND_NI:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ROUND_PI:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ROUND_Z:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_RSQ:
        _parseFunctionCall(state, opcode, "rsqrt");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SAMPLE:
        _parseSample(state, opcode, "Sample");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SAMPLE_C:
        _parseSample(state, opcode, "SampleCmp");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SAMPLE_C_LZ:
        _parseSample(state, opcode, "SampleCmpLevelZero");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SAMPLE_L:
        _parseSample(state, opcode, "SampleLevel");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SAMPLE_D:
        _parseSample(state, opcode, "SampleGrad");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SAMPLE_B:
        _parseSample(state, opcode, "SampleBias");
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SQRT:
        _parseFunctionCall(state, opcode, "sqrt");
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SWITCH:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_SINCOS:
        _parseSinCos(state, opcode);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UDIV:
        _parse2Exp(state, opcode, "/", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_ULT:
        _parse2Exp(state, opcode, "<", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UGE:
        _parse2Exp(state, opcode, ">=", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UMUL:
        _parse2Exp(state, opcode, "*", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UMAD:
        _parse3Exp(state, opcode, "*", "+", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UMAX:
        _parseFunctionCall(state, opcode, "max", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UMIN:
        _parseFunctionCall(state, opcode, "min", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_USHR:
        _parse2Exp(state, opcode, ">>", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_UTOF:
        _parseCast(state, opcode, tFloat, numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_XOR:
        _parse2Exp(state, opcode, "^", numType: NumberType.uint);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_BUFINFO:
        _parseBufInfo(state, opcode);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_LD_STRUCTURED:
        _parseLoadStructured(state, opcode);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_RESOURCE:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_CONSTANT_BUFFER:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_SAMPLER:
      case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_RESOURCE_STRUCTURED:
        parseDeclResourceBinding(opcode as DeclarationWithRegisterOpcode , state);
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INDEX_RANGE:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GS_OUTPUT_PRIMITIVE_TOPOLOGY:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GS_INPUT_PRIMITIVE:
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_MAX_OUTPUT_VERTEX_COUNT:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SGV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_SIV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SGV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INPUT_PS_SIV:
        parseInputSignature(state, opcode as InputOutputDeclarationOpcode);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT_SGV:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_OUTPUT_SIV:
        parseOutputSignature(state, opcode as InputOutputDeclarationOpcode);
        break;
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_TEMPS:
        var decl = opcode as TempRegisterDeclarationOpcode;
        var temps = List.generate(
          decl.registerCount,
          (i) => TempVariableBinding(Register(RegisterType.temp, i), VectorDataType(ScalarType.float, 4)),
        );
        for (var temp in temps) {
          state.registerBindings[(RegisterType.temp, temp.register.index)] = temp;
        }
        state.addStatement(TempVariableDeclarationStatement(temps));
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_INDEXABLE_TEMP:
      case D3D10_SB_OPCODE_TYPE.D3D10_SB_OPCODE_DCL_GLOBAL_FLAGS:
        break;
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_STREAM:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_FUNCTION_BODY:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_FUNCTION_TABLE:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_INTERFACE:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_INPUT_CONTROL_POINT_COUNT:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_OUTPUT_CONTROL_POINT_COUNT:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_TESS_DOMAIN:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_TESS_PARTITIONING:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_TESS_OUTPUT_PRIMITIVE:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_HS_MAX_TESSFACTOR:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_HS_FORK_PHASE_INSTANCE_COUNT:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_HS_JOIN_PHASE_INSTANCE_COUNT:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_THREAD_GROUP:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_TYPED:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_RAW:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_UNORDERED_ACCESS_VIEW_STRUCTURED:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_THREAD_GROUP_SHARED_MEMORY_RAW:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_THREAD_GROUP_SHARED_MEMORY_STRUCTURED:
      // case D3D10_SB_OPCODE_TYPE.D3D11_SB_OPCODE_DCL_RESOURCE_RAW:
      default:
      if (opcode is InstructionOpcode)
        state.addStatement(InstructionCommentStatement(opcode));
      else
        state.addStatement(CommentStatement("TODO ${opcode.opcodeType.name}"));
    }
  }
}

void _parseMove(DecompilerState state, Opcode opcode) {
  var op = opcode as InstructionOpcode;
  var exp = Expression.fromOperand(state, op.operands[1]);
  exp = SaturationExpression.wrap(exp, op);
  state.addStatement(
    AssignmentStatement(
      Register.fromOperand(state, op.operands[0]),
      exp,
    )
  );
}

void _parseUnaryExp(DecompilerState state, Opcode opcode, String operand, {NumberType numType = NumberType.float}) {
  var op = opcode as InstructionOpcode;
  Expression exp = UnaryExpression(operand, Expression.fromOperand(state, op.operands[1], numType: numType));
  exp = SaturationExpression.wrap(exp, op);
  state.addStatement(AssignmentStatement(Register.fromOperand(state, op.operands[0]), exp));
}

void _parse2Exp(DecompilerState state, Opcode opcode, String operand, {NumberType numType = NumberType.float}) {
  var op = opcode as InstructionOpcode;
  Expression exp = TwoCombinedExpressions(
    Expression.fromOperand(state, op.operands[1], numType: numType),
    operand,
    Expression.fromOperand(state, op.operands[2], numType: numType),
  );
  exp = SaturationExpression.wrap(exp, op);
  state.addStatement(AssignmentStatement(Register.fromOperand(state, op.operands[0]), exp));
}

void _parse3Exp(DecompilerState state, Opcode opcode, String operand1, String operand2, {NumberType numType = NumberType.float}) {
  var op = opcode as InstructionOpcode;
  Expression exp = ThreeCombinedExpressions(
    Expression.fromOperand(state, op.operands[1], numType: numType),
    operand1,
    Expression.fromOperand(state, op.operands[2], numType: numType),
    operand2,
    Expression.fromOperand(state, op.operands[3], numType: numType),
  );
  exp = SaturationExpression.wrap(exp, op);
  state.addStatement(AssignmentStatement(Register.fromOperand(state, op.operands[0]), exp));
}

void _parseFunctionCall(DecompilerState state, Opcode opcode, String function, {NumberType numType = NumberType.float}) {
  var op = opcode as InstructionOpcode;
  var dest = Register.fromOperand(state, op.operands[0]);
  var args = op.operands.skip(1).map((op) => Expression.fromOperand(state, op, numType: numType)).toList();
  Expression exp = FunctionCall(function, args);
  exp = SaturationExpression.wrap(exp, op);
  state.addStatement(AssignmentStatement(dest, exp));
}

void _parseCast(DecompilerState state, Opcode opcode, DataType type, {NumberType numType = NumberType.float}) {
  var op = opcode as InstructionOpcode;
  var dest = Register.fromOperand(state, op.operands[0]);
  var src = Expression.fromOperand(state, op.operands[1], numType: numType);
  Expression exp = CastExpression(type, src);
  exp = SaturationExpression.wrap(exp, op);
  state.addStatement(AssignmentStatement(dest, exp));
}

Expression _makeCondition(DecompilerState state, InstructionOpcode op, int conditionIndex, NumberType numType) {
  var conditionValue = Expression.fromOperand(state, op.operands[conditionIndex], numType: numType);
  var comp = op.testBoolean == D3D10_SB_INSTRUCTION_TEST_BOOLEAN.D3D10_SB_INSTRUCTION_TEST_NONZERO ? "!=" : "==";
  return TwoCombinedExpressions(conditionValue, comp, FloatLiteralExpression(0));
}

void _parseConditionBlock(DecompilerState state, Opcode opcode, String keyword, {Expression? condition, NumberType numType = NumberType.float}) {
  condition ??= _makeCondition(state, opcode as InstructionOpcode, 0, numType);
  var block = ConditionalBlock(keyword, condition);
  state.pushBlock(block);
}

void _parseBlock(DecompilerState state, Opcode opcode, String keyword) {
  var block = ConditionalBlock(keyword, null);
  state.pushBlock(block);
}

void _parseSample(DecompilerState state, Opcode opcode, String function) {
  var op = opcode as InstructionOpcode;
  var dest = Register.fromOperand(state, op.operands[0]);
  var coords = Expression.fromOperand(state, op.operands[1]);
  var tex = Register.fromOperand(state, op.operands[2]);
  var sampler = Register.fromOperand(state, op.operands[3]);
  var args = op.operands.skip(4).map((op) => Expression.fromOperand(state, op)).toList();
  var expr = FunctionCall(function, [sampler, coords, ...args], tex);
  state.addStatement(AssignmentStatement(dest, expr));
}

void _parseConditionalKeyword(DecompilerState state, Opcode opcode, String keyword) {
  var condition = _makeCondition(state, opcode as InstructionOpcode, 0, NumberType.float);
  var block = ConditionalBlock("if", condition);
  state.pushBlock(block);
  var keywordStatement = KeywordStatement(keyword);
  state.addStatement(keywordStatement);
  state.popBlock();
}

const _getDimensionSignature = {
  "AppendStructuredBuffer": ["numStructs", "stride"],
  "Buffer": ["dim"],
  "ByteAddressBuffer": ["dim"],
  "ConsumeStructuredBuffer": ["numStructs", "stride"],
  "RWBuffer": ["dim"],
  "RWByteAddressBuffer": ["dim"],
  "RWStructuredBuffer": ["numStructs", "stride"],
  "RWTexture1D": ["width"],
  "RWTexture1DArray": ["width", "elements"],
  "RWTexture2D": ["width", "height"],
  "RWTexture2DArray": ["width", "height", "elements"],
  "RWTexture3D": ["width", "height", "depth"],
  "StructuredBuffer": ["numStructs", "stride"],
  "Texture1D": ["mipLevel", "width", "numberOfLevels"],
  "Texture1DArray": ["mipLevel", "width", "elements", "numberOfLevels"],
  "Texture2D": ["mipLevel", "width", "height", "numberOfLevels"],
  "Texture2DArray": ["mipLevel", "width", "height", "elements", "numberOfLevels"],
  "Texture2DMS": ["width", "height", "numberOfSamples"],
  "Texture2DMSArray": ["width", "height", "elements", "numberOfSamples"],
  "Texture3D": ["mipLevel", "width", "height", "depth", "numberOfLevels"],
};
const _elementCountParameters = {"elements", "numStructs", "dim"};
const _inParameter = "mipLevel";
void _parseBufInfo(DecompilerState state, Opcode opcode) {
  var op = opcode as InstructionOpcode;
  var src = Register.fromOperand(state, op.operands[1]);
  var resBind = state.registerBindings[(src.type, src.index)] as TemplateBinding;
  var signature = _getDimensionSignature[resBind.className]!;
  List<Expression> args = [];
  Expression? elements;
  for (var param in signature) {
    if (param == _inParameter) {
      args.add(HexLiteralExpression(0));
      continue;
    }
    NameExpression nameExp;
    if (!state.isVariableDeclared(param)) {
      var stat = VariableDeclarationStatement(ScalarDataType(ScalarType.uint), param);
      state.addStatement(stat);
      state.declareVariable(param);
      nameExp = stat.asName();
    }
    else {
      nameExp = NameExpression(param);
    }
    args.add(nameExp);
    if (_elementCountParameters.contains(param))
      elements = nameExp;
  }
  var call = FunctionCall("GetDimensions", args, src);
  state.addStatement(ExpressionStatement(call));
  var dest = Register.fromOperand(state, op.operands[0]);
  var assign = AssignmentStatement(dest, elements!);
  state.addStatement(assign);
}

const _loadRequiresStatus = "Buffer";
void _parseLoadStructured(DecompilerState state, Opcode opcode) {
  var op = opcode as InstructionOpcode;
  var src = Register.fromOperand(state, op.operands[3]);
  var resBind = src.lookupBinding(state) as TemplateBinding;
  var addStatusVar = _loadRequiresStatus.contains(resBind.className);
  VariableDeclarationStatement? statusVar;
  if (addStatusVar && !state.isVariableDeclared("status")) {
    statusVar = VariableDeclarationStatement(ScalarDataType(ScalarType.uint), "status");
    state.addStatement(statusVar);
    state.declareVariable("status");
  }
  var loc = Expression.fromOperand(state, op.operands[1]);
  var offset = Expression.fromOperand(state, op.operands[2], numType: NumberType.uint);
  var hasMemberAccess = resBind.innerType is StructDataType;
  var requiresMultipleStatements = hasMemberAccess && HasStructMemberAccess.memberAccessRequiresMultipleStatements(
    state,
    resBind.innerType as StructDataType,
    offset,
    1,
    src.swizzle!,
  );
  var dest = Register.fromOperand(state, op.operands[0]);
  var args = [
    if (addStatusVar)
      statusVar!.asName(),
    loc,
  ];
  Expression assignExp = FunctionCall("Load", args, src);
  if (hasMemberAccess) {
    if (requiresMultipleStatements) {
      var tmpVarName = "temp_${resBind.name}";
      NameExpression nameExp;
      if (!state.isVariableDeclared(tmpVarName)) {
        var tempStruct = VariableDeclarationStatement(resBind.innerType!, tmpVarName);
        state.addStatement(tempStruct);
        state.declareVariable(tmpVarName);
        nameExp = tempStruct.asName();
      }
      else {
        nameExp = NameExpression(tmpVarName);
      }
      var assign = AssignmentStatement(nameExp, assignExp);
      state.addStatement(assign);
      var joinedExp = HasStructMemberAccess.generateJoinedMemberAccess(
        state,
        resBind.innerType as StructDataType,
        offset,
        1,
        assignExp.swizzle!,
        nameExp,
      );
      assignExp.swizzle = null;
      assignExp = joinedExp;
    }
    else {
      (assignExp as FunctionCall).addMemberAccess(state, resBind.innerType as StructDataType, offset, 1, assignExp.swizzle!);
    }
  }
  if (!hasMemberAccess || !requiresMultipleStatements) {
    if (resBind.innerType is ScalarDataType && dest.swizzle?.components.length == 1)
      assignExp.swizzle = null;
  }
  var assign = AssignmentStatement(dest, assignExp);
  state.addStatement(assign);
}

void _parseSinCos(DecompilerState state, Opcode opcode) {
  var op = opcode as InstructionOpcode;
  var destSin = Expression.fromOperand(state, op.operands[0]);
  var destCos = Expression.fromOperand(state, op.operands[1]);
  var src = Expression.fromOperand(state, op.operands[2]);
  if (destSin is Register) {
    Expression exp = FunctionCall("sin", [src]);
    exp = SaturationExpression.wrap(exp, op);
    state.addStatement(AssignmentStatement(destSin, exp));
  }
  if (destCos is Register) {
    Expression exp = FunctionCall("cos", [src]);
    exp = SaturationExpression.wrap(exp, op);
    state.addStatement(AssignmentStatement(destCos, exp));
  }
}


void applyDestinationSwizzles(DecompilerState state) {
  _applyDestinationSwizzles(state.mainBlock);
}
void _applyDestinationSwizzles(BlockStatement block) {
  for (var statement in block.statements) {
    if (statement is AssignmentStatement) {
      var destSwizzle = statement.destination.swizzle;
      if (destSwizzle != null)
        statement.source.applyDestinationSwizzle(destSwizzle);
    }
    else if (statement is BlockStatement) {
      _applyDestinationSwizzles(statement);
    }
  }
}
