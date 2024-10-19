
import 'dart:math';

import '../file_reader/dxbc_enums.dart';
import '../file_reader/shex/declare_opcode.dart';
import '../file_reader/shex/instruction_opcode.dart';
import '../file_reader/shex/operand.dart';
import 'data_type.dart';
import 'resource_binding.dart';
import 'state.dart';

mixin Statement implements Writable {

}

class KeywordStatement with Statement {
  final String keyword;

  KeywordStatement(this.keyword);

  @override
  void write(DecompilerState state) {
    state.mainWriter.write("$keyword;");
    state.mainWriter.writeNewLine();
  }
}

class CommentStatement with Statement {
  final String comment;

  CommentStatement(this.comment);

  @override
  void write(DecompilerState state) {
    var lines = comment.split("\n");
    for (var line in lines) {
      state.mainWriter.write("// $line");
      state.mainWriter.writeNewLine();
    }
  }
}

class InstructionCommentStatement with Statement {
  final InstructionOpcode opcode;

  InstructionCommentStatement(this.opcode);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    writer.write("// ");
    writer.write(opcode.opcodeType.name);
    for (var op in opcode.operands) {
      writer.write(" ");
      var exp = Expression.fromOperand(state, op);
      exp.write(state);
    }
    writer.writeNewLine();
  }
}

class BlockStatement with Statement {
  final List<Statement> statements = [];

  BlockStatement();
  
  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    writer.write("{");
    writer.writeNewLine();
    writer.indent();
    for (var statement in statements) {
      statement.write(state);
    }
    writer.unindent();
    writer.write("}");
    writer.writeNewLine();
  }
}

abstract class OperationStatement with Statement {
  final String operation;
  final List<String> operands;

  OperationStatement(this.operation, this.operands);
}

enum Component {
  x, y, z, w
}
class Swizzle {
  final List<Component> components;

  Swizzle(this.components);

  Swizzle.def(int size) : components = List.generate(size, (i) => Component.values[i]);

  static Swizzle? fromOperand(Operand operand) {
    List<Component> components;
    if (operand.mask != null) {
      components = [
        if (operand.mask!.x) Component.x,
        if (operand.mask!.y) Component.y,
        if (operand.mask!.z) Component.z,
        if (operand.mask!.w) Component.w,
      ];
    }
    else if (operand.swizzle != null) {
      components = operand.swizzle!.swizzleXyzw.map((e) => Component.values[e.index]).toList();
    }
    else if (operand.componentName != null) {
      components = [Component.values[operand.componentName!.index]];
    }
    else {
      return null;
    }
    if (components.isEmpty)
      return null;
    return Swizzle(components);
  }

  Component operator [](Component index) {
    if (index.index >= components.length)
      return components.last;
    return components[index.index];
  }

  void applyDestinationSwizzle(Swizzle dest) {
    var swizzled = dest.components.map((c) => this[c]).toList();
    components.clear();
    components.addAll(swizzled);
  }

  bool isDefault(int size) {
    return components.length == size &&
      components.indexed.every((e) => e.$2.index == e.$1);
  }

  bool get usesOneComponentType => components.every((c) => c == components[0]);

  int get maxSize {
    int maxC = Component.x.index;
    for (var c in components)
      maxC = max(maxC, c.index);
    return maxC + 1;
  }

  int get maxWidth {
    int minC = Component.w.index;
    int maxC = Component.x.index;
    for (var c in components) {
      minC = min(minC, c.index);
      maxC = max(maxC, c.index);
    }
    return maxC - minC + 1;
  }

  void write(WriterState writer) {
    writer.write(".");
    for (var comp in components) {
      writer.write(comp.name);
    }
  }
}

enum NumberType {
  int,
  uint,
  float,
}

abstract class Expression implements Writable {
  Swizzle? swizzle;

  Expression();

  factory Expression.fromOperand(DecompilerState state, Operand operand, {NumberType numType = NumberType.float}) {
    Expression exp;
    switch (operand.operandType) {
      case D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_IMMEDIATE32:
      case D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_IMMEDIATE64:
        List<Expression> literals;
        switch (numType) {
          case NumberType.int:
            literals = operand.valuesAsInt!.map((v) => HexLiteralExpression(v)).toList();
            break;
          case NumberType.uint:
            literals = operand.valuesAsUInt!.map((v) => HexLiteralExpression(v)).toList();
            break;
          case NumberType.float:
            literals = operand.valuesFloat!.map((v) => FloatLiteralExpression(v)).toList();
            break;
        }
        literals = literals.cast<Expression>();
        if (literals.length == 1)
          exp = literals[0];
        else
          exp = VectorExpression(literals, numType.name);
        break;
      case D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_NULL:
        exp = NullExpression();
        break;
      default:
        exp = Register.fromOperand(state, operand, applyModifiers: false);
    }
    exp.setOperandSwizzle(operand);
    if (exp is Register) {
      if (exp.offsets.isNotEmpty) {
        var binding = exp.lookupBinding(state)! as ConstantBufferBinding;
        exp.addMemberAccess(state, binding, exp.offsets[0], 16, exp.swizzle!);
      }
    }
    exp = exp.wrapModifiers(operand);
    return exp;
  }

  void setOperandSwizzle(Operand operand) {
    swizzle ??= Swizzle.fromOperand(operand);
  }

  void applyDestinationSwizzle(Swizzle dest) {
    swizzle?.applyDestinationSwizzle(dest);
  }

  Expression wrapModifiers(Operand operand) {
    switch (operand.modifier) {
      case D3D10_SB_OPERAND_MODIFIER.D3D10_SB_OPERAND_MODIFIER_ABS:
        return FunctionCall("abs", [this]);
      case D3D10_SB_OPERAND_MODIFIER.D3D10_SB_OPERAND_MODIFIER_NEG:
        return UnaryExpression("-", this);
      case D3D10_SB_OPERAND_MODIFIER.D3D10_SB_OPERAND_MODIFIER_ABSNEG:
        return FunctionCall("abs", [UnaryExpression("-", this)]);
      default:
        return this;
    }
  }
}

class ExpressionStatement with Statement {
  final Expression expression;

  ExpressionStatement(this.expression) {
    expression.swizzle = null;
  }

  @override
  void write(DecompilerState state) {
    expression.write(state);
    state.mainWriter.write(";");
    state.mainWriter.writeNewLine();
  }
}

class LiteralExpression extends Expression {
  final String value;

  LiteralExpression(this.value);

  @override
  void write(DecompilerState state) {
    state.mainWriter.write(value);
  }
}

class NullExpression extends Expression {
  @override
  void write(DecompilerState state) {
    state.mainWriter.write("null");
  }
}

class NameExpression extends Register {
  final String name;

  NameExpression(this.name) : super(RegisterType.custom, 0);

  @override
  void write(DecompilerState state) {
    state.mainWriter.write(name);
    writeMemberAccess(state);
    swizzle?.write(state.mainWriter);
  }
  
  NameExpression copy() {
    return NameExpression(name);
  }
}

class FloatLiteralExpression extends Expression {
  final num value;

  FloatLiteralExpression(this.value);

  @override
  void write(DecompilerState state) {
    state.mainWriter.write(value.toString());
  }
}

class HexLiteralExpression extends Expression {
  final int value;

  HexLiteralExpression(this.value);

  @override
  void write(DecompilerState state) {
    if (value >= 0xa)
      state.mainWriter.write("0x");
    state.mainWriter.write(value.toRadixString(16));
  }
}

class VectorExpression extends Expression {
  final List<Expression> values;
  final String type;
  final int? _size;
  int get size => _size ?? values.length;

  VectorExpression(this.values, this.type, [this._size]);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    if (values.length == 1) {
      values[0].write(state);
      return;
    }
    writer.write("$type$size(");
    for (var i = 0; i < values.length; i++) {
      if (i > 0)
        writer.write(", ");
      values[i].write(state);
    }
    writer.write(")");
    swizzle?.write(writer);
  }

  @override
  void applyDestinationSwizzle(Swizzle dest) {
    if (values.length != size)
      return; // TODO
    List<Expression> swizzled = dest.components.map((c) => values[c.index]).toList();
    values.clear();
    values.addAll(swizzled);
  }
}

class SaturationExpression extends Expression {
  final Expression inner;

  SaturationExpression(this.inner);

  static Expression wrap(Expression inner, InstructionOpcode op) {
    return op.saturate ? SaturationExpression(inner) : inner;
  }

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    writer.write("saturate(");
    inner.write(state);
    writer.write(")");
  }

  @override
  void applyDestinationSwizzle(Swizzle dest) {
    inner.applyDestinationSwizzle(dest);
  }
}

class UnaryExpression extends Expression {
  final String operator;
  final Expression inner;

  UnaryExpression(this.operator, this.inner);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    writer.write(operator);
    inner.write(state);
  }

  @override
  void applyDestinationSwizzle(Swizzle dest) {
    inner.applyDestinationSwizzle(dest);
  }
}

mixin HasStructMemberAccess {
  List<String>? _memberAccess;
  Expression? _memberOffset;

  void addMemberAccess(DecompilerState state, StructLike struct, Expression offset, int offsetScale, Swizzle destSwizzle) {
    if (offset is HexLiteralExpression) {
      var size = destSwizzle.maxSize * 4;
      var members = struct.getMemberChainAt(offset.value * offsetScale, size);
      if (members.length != 1)
        throw Exception("Expected 1 member, got ${members.length}");
      _memberAccess = [members[0].path];
    }
    else {
      List<String> splitChain = [""];
      struct.getMemberChainDynamic(0, splitChain);
      _memberAccess = splitChain;
      _memberOffset = offset;
    }
  }

  static Expression generateJoinedMemberAccess(DecompilerState state, StructLike struct, Expression offset, int offsetScale, Swizzle destSwizzle, NameExpression nameExp) {
    var size = destSwizzle.maxSize * 4;
    var members = struct.getMemberChainAt((offset as HexLiteralExpression).value * offsetScale, size);
    List<(MemberAccess, Swizzle)> swizzledMembers = [];
    var startOffset = 0;
    for (var component in destSwizzle.components) {
      // find member that contains component
      var compOffset = component.index * 4;
      var memOffset = 0;
      MemberAccess? compMember;
      for (var mem in members) {
        var memEnd = memOffset + mem.size;
        if (compOffset < memEnd) {
          compMember = mem;
          break;
        }
        memOffset += mem.size;
      }
      if (compMember == null)
        throw Exception("Failed to find member of component $component");
      // set member swizzle
      if (swizzledMembers.isEmpty) {
        swizzledMembers.add((compMember, Swizzle([(compMember.getComponent(component, startOffset))])));
      } else if (swizzledMembers.last.$1 == compMember) {
        swizzledMembers.last.$2.components.add(compMember.getComponent(component, startOffset));
      } else {
        startOffset += swizzledMembers.last.$1.size;
        swizzledMembers.add((compMember, Swizzle([compMember.getComponent(component, startOffset)])));
      }
    }
    List<Expression> expressions = [];
    for (var (memAccess, swizzle) in swizzledMembers) {
      var exp = nameExp.copy();
      exp.swizzle = swizzle;
      exp._memberAccess = [memAccess.path];
      expressions.add(exp);
    }
    return VectorExpression(expressions, "float", destSwizzle.maxWidth);
  }

  static bool memberAccessRequiresMultipleStatements(DecompilerState state, StructLike struct, Expression offset, int offsetScale, Swizzle destSwizzle) {
    if (offset is HexLiteralExpression) {
      var size = destSwizzle.maxSize * 4;
      if (size == 4)
        return false;
      var members = struct.getMemberChainAt(offset.value * offsetScale, size);
      return members.length > 1;
    }
    else {
      return false;
    }
  }

  void writeMemberAccess(DecompilerState state) {
    if (_memberAccess == null)
      return;
    var writer = state.mainWriter;
    writer.write(_memberAccess![0]);
    _memberOffset?.write(state);
    writer.write(_memberAccess!.skip(1).join());
  }

  bool get hasMemberAccess => _memberAccess != null;
}

class Register extends Expression with HasStructMemberAccess {
  final RegisterType type;
  final int index;
  final List<Expression> offsets;

  Register(this.type, this.index, [this.offsets = const []]);

  factory Register.fromOperand(DecompilerState state, Operand operand, {bool applyModifiers = true}) {
    var reg = Register(
      _operandToRegisterType[operand.operandType]!,
      operand.indexData![0].index!,
      (operand.indexData ?? []).skip(1).map((i) {
        Expression? intIndex;
        Expression? opIndex;
        if (i.index != null)
          intIndex = HexLiteralExpression(i.index!);
        if (i.indexData != null)
          opIndex = Expression.fromOperand(state, i.indexData!);
        if (intIndex != null && opIndex != null)
          return TwoCombinedExpressions(intIndex, "+", opIndex);
        return intIndex ?? opIndex!;
      }).toList(),
    );
    if (applyModifiers) {
      reg.setOperandSwizzle(operand);
      if (reg.offsets.isNotEmpty) {
        var binding = reg.lookupBinding(state)! as ConstantBufferBinding;
        reg.addMemberAccess(state, binding, reg.offsets[0], 16, reg.swizzle!);
      }
    }
    return reg;
  }

  ResourceBinding? lookupBinding(DecompilerState state) {
    return state.registerBindings[(type, index)];
  }

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    if (hasMemberAccess) {
      writeMemberAccess(state);
    }
    else {
      var binding = lookupBinding(state)!;
      binding.writeName(state);
    }
    swizzle?.write(writer);
  }

  @override
  bool operator ==(Object other) {
    if (other is Register) {
      return type == other.type &&
      index == other.index &&
      offsets.length == other.offsets.length && Iterable.generate(offsets.length, (i) => offsets[i] == other.offsets[i]).every((e) => e);
    }
    return false;
  }
  
  @override
  int get hashCode => Object.hashAll([type, index, ...offsets]);
  
}

const _operandToRegisterType = {
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_TEMP: RegisterType.temp,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_INPUT: RegisterType.input,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_OUTPUT: RegisterType.output,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_INDEXABLE_TEMP: RegisterType.indexableTemp,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_SAMPLER: RegisterType.sampler,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_RESOURCE: RegisterType.resource,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_CONSTANT_BUFFER: RegisterType.constantBuffer,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_IMMEDIATE_CONSTANT_BUFFER: RegisterType.immediateConstantBuffer,
  // D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_LABEL: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_INPUT_PRIMITIVEID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_OUTPUT_DEPTH: RegisterType.,
  D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_NULL: RegisterType.null_,
  // D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_RASTERIZER: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_OUTPUT_COVERAGE_MASK: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_STREAM: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_FUNCTION_BODY: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_FUNCTION_TABLE: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INTERFACE: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_FUNCTION_INPUT: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_FUNCTION_OUTPUT: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_OUTPUT_CONTROL_POINT_ID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_FORK_INSTANCE_ID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_JOIN_INSTANCE_ID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_CONTROL_POINT: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_OUTPUT_CONTROL_POINT: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_PATCH_CONSTANT: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_DOMAIN_POINT: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_THIS_POINTER: RegisterType.,
  D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_UNORDERED_ACCESS_VIEW: RegisterType.uav,
  D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_THREAD_GROUP_SHARED_MEMORY: RegisterType.threadGroupSharedMemory,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_THREAD_ID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_THREAD_GROUP_ID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_THREAD_ID_IN_GROUP: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_COVERAGE_MASK: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_THREAD_ID_IN_GROUP_FLATTENED: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_INPUT_GS_INSTANCE_ID: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_OUTPUT_DEPTH_GREATER_EQUAL: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_OUTPUT_DEPTH_LESS_EQUAL: RegisterType.,
  // D3D10_SB_OPERAND_TYPE.D3D11_SB_OPERAND_TYPE_CYCLE_COUNTER: RegisterType.,
};

class ConditionalBlock extends BlockStatement {
  final String keyword;
  final Expression? condition;

  ConditionalBlock(this.keyword, this.condition);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    writer.write("$keyword ");
    if (condition != null) {
      writer.write("(");
      condition!.write(state);
      writer.write(") ");
    }
    super.write(state);
  }
}

class AssignmentStatement with Statement {
  final Register destination;
  final Expression source;

  AssignmentStatement(this.destination, this.source);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    destination.write(state);
    writer.write(" = ");
    source.write(state);
    writer.write(";");
    writer.writeNewLine();
  }
}

class TempVariableDeclarationStatement with Statement {
  final List<TempVariableBinding> temps;

  TempVariableDeclarationStatement(this.temps);

  @override
  void write(DecompilerState state) {
    if (temps.isEmpty)
      return;
    var type = temps[0].dataType;
    var writer = state.mainWriter;
    type.write(writer);
    writer.write(" ");
    var isFirst = true;
    for (var temp in temps) {
      if (!isFirst)
        writer.write(", ");
      writer.write(temp.name);
      isFirst = false;
    }
    writer.write(";");
    writer.writeNewLine();
  }
}

class VariableDeclarationStatement with Statement {
  final DataType dataType;
  final String name;

  VariableDeclarationStatement(this.dataType, this.name);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    if (dataType is StructDataType)
      writer.write((dataType as StructDataType).name!);
    else
      dataType.write(writer);
    writer.write(" ");
    writer.write(name);
    writer.write(";");
    writer.writeNewLine();
  }

  NameExpression asName() {
    return NameExpression(name);
  }
}

class TwoCombinedExpressions extends Expression {
  final Expression left;
  final Expression right;
  final String operator;

  TwoCombinedExpressions(this.left, this.operator, this.right);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    left.write(state);
    writer.write(" $operator ");
    right.write(state);
  }

  @override
  void applyDestinationSwizzle(Swizzle dest) {
    left.applyDestinationSwizzle(dest);
    right.applyDestinationSwizzle(dest);
  }
}

class ThreeCombinedExpressions extends Expression {
  final Expression left;
  final Expression middle;
  final Expression right;
  final String operator1;
  final String operator2;

  ThreeCombinedExpressions(this.left, this.operator1, this.middle, this.operator2, this.right);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    left.write(state);
    writer.write(" $operator1 ");
    middle.write(state);
    writer.write(" $operator2 ");
    right.write(state);
  }

  @override
  void applyDestinationSwizzle(Swizzle dest) {
    left.applyDestinationSwizzle(dest);
    middle.applyDestinationSwizzle(dest);
    right.applyDestinationSwizzle(dest);
  }
}

class FunctionCall extends Expression with HasStructMemberAccess {
  final Register? source;
  final String function;
  final List<Expression> arguments;

  FunctionCall(this.function, this.arguments, [this.source]) {
    if (source?.swizzle != null) {
      swizzle = source!.swizzle;
      source!.swizzle = null;
    }
  }

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    if (source != null) {
      source!.write(state);
      writer.write(".");
    }
    writer.write("$function(");
    for (var i = 0; i < arguments.length; i++) {
      if (i > 0)
        writer.write(", ");
      arguments[i].write(state);
    }
    writer.write(")");
    writeMemberAccess(state);
    swizzle?.write(writer);    
  }
}

class CastExpression extends Expression {
  final DataType dataType;
  final Expression inner;

  CastExpression(this.dataType, this.inner);

  @override
  void write(DecompilerState state) {
    var writer = state.mainWriter;
    dataType.write(writer);
    writer.write("(");
    inner.write(state);
    writer.write(")");
  }

  @override
  void applyDestinationSwizzle(Swizzle dest) {
    inner.applyDestinationSwizzle(dest);
  }
}
