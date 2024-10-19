
import 'dart:typed_data';

import '../byte_data_wrapper.dart';
import '../dxbc_enums.dart';

class SampleControls {
  late int uTexelImmediateOffset;
  late int vTexelImmediateOffset;
  late int wTexelImmediateOffset;

  SampleControls.read(ByteDataWrapper bytes) {
    bytes.readBits(3); // reserved
    uTexelImmediateOffset = bytes.readBits(4);
    vTexelImmediateOffset = bytes.readBits(4);
    wTexelImmediateOffset = bytes.readBits(4);
    bytes.readBits(10); // reserved
  }
}

class ResourceDim {
  late int resourceDimension;
  late int bufferStride;

  ResourceDim.read(ByteDataWrapper bytes) {
    resourceDimension = bytes.readBits(5);
    bufferStride = bytes.readBits(12);
    bytes.readBits(8); // reserved
  }
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

class DclTempData {
  final int tempCount;

  DclTempData.read(ByteDataWrapper bytes) :
    tempCount = bytes.readUint32();
}

class DclTempIndexableTempData {
  final int registerIndex;
  final int registerCount;
  final int componentCount;

  DclTempIndexableTempData.read(ByteDataWrapper bytes) :
    registerIndex = bytes.readUint32(),
    registerCount = bytes.readUint32(),
    componentCount = bytes.readUint32();
}


class SwizzleMask {
  late List<D3010_SB_OPERAND_4_SWIZZLE_MASK> swizzleXyzw;

  SwizzleMask.read(ByteDataWrapper bytes) {
    swizzleXyzw = List.generate(4, (_) => D3010_SB_OPERAND_4_SWIZZLE_MASK.values[bytes.readBits(2)]);
  }
}


class IndexData {
  late D3D10_SB_OPERAND_INDEX_REPRESENTATION indexRepresentation;
  int? index;
  Operand? indexData;

  IndexData.read1(ByteDataWrapper bytes) {
    indexRepresentation = D3D10_SB_OPERAND_INDEX_REPRESENTATION.values[bytes.readBits(3)];
  }

  read2(ByteDataWrapper bytes) {
    if (indexRepresentation == D3D10_SB_OPERAND_INDEX_REPRESENTATION.D3D10_SB_OPERAND_INDEX_IMMEDIATE32) {
      index = bytes.readUint32();
    }
    else if (indexRepresentation == D3D10_SB_OPERAND_INDEX_REPRESENTATION.D3D10_SB_OPERAND_INDEX_IMMEDIATE64) {
      index = bytes.readUint64();
    }
    else if (indexRepresentation == D3D10_SB_OPERAND_INDEX_REPRESENTATION.D3D10_SB_OPERAND_INDEX_RELATIVE) {
      indexData = Operand.read(bytes);
    }
    else if (indexRepresentation == D3D10_SB_OPERAND_INDEX_REPRESENTATION.D3D10_SB_OPERAND_INDEX_IMMEDIATE32_PLUS_RELATIVE) {
      index = bytes.readBits(32);
      indexData = Operand.read(bytes);
    }
    else if (indexRepresentation == D3D10_SB_OPERAND_INDEX_REPRESENTATION.D3D10_SB_OPERAND_INDEX_IMMEDIATE64_PLUS_RELATIVE) {
      index = bytes.readBits(64);
      indexData = Operand.read(bytes);
    }
    else {
      // bytes.readBits(32);
      throw Exception("Unknown index representation $indexRepresentation");
    }
  }

  @override
  String toString() {
    if (index != null) {
      return "$index";
    }
    else if (indexData != null) {
      return "IndexData($indexData)";
    }
    else {
      throw Exception("IndexData has no index or indexData");
    }
  }
}

class Operand {
  late D3D10_SB_OPERAND_NUM_COMPONENTS numComponents;
  late int numComponentsValue;
  D3D10_SB_OPERAND_4_COMPONENT_SELECTION_MODE? selectionMode;
  D3D10_SB_OPERAND_4_COMPONENT_MASK? mask;
  SwizzleMask? swizzle;
  D3D10_SB_4_COMPONENT_NAME? componentName;
  int? numComponentsN;
  late D3D10_SB_OPERAND_TYPE operandType;
  late D3D10_SB_OPERAND_INDEX_DIMENSION indexDimension;
  List<IndexData>? indexData;
  D3D10_SB_OPERAND_MODIFIER? modifier;
  D11_SB_OPERAND_MIN_PRECISION? minPrecision;
  Uint8List? _values;
  bool _is32Bit = true;
  List<int>? get valuesAsInt => _is32Bit ? _values?.buffer.asInt32List() : _values?.buffer.asInt64List();
  List<int>? get valuesAsUInt => _is32Bit ? _values?.buffer.asUint32List() : _values?.buffer.asUint64List();
  List<double>? get valuesFloat => _is32Bit ? _values?.buffer.asFloat32List() : _values?.buffer.asFloat64List();

  Operand.read(ByteDataWrapper bytes) {
    numComponents = D3D10_SB_OPERAND_NUM_COMPONENTS.values[bytes.readBits(2)];
    if (numComponents == D3D10_SB_OPERAND_NUM_COMPONENTS.D3D10_SB_OPERAND_0_COMPONENT) {
      bytes.readBits(10);
    }
    else if (numComponents == D3D10_SB_OPERAND_NUM_COMPONENTS.D3D10_SB_OPERAND_1_COMPONENT) {
      numComponentsValue = 1;
      bytes.readBits(10);
    }
    else if (numComponents == D3D10_SB_OPERAND_NUM_COMPONENTS.D3D10_SB_OPERAND_4_COMPONENT) {
      numComponentsValue = 4;
      selectionMode = D3D10_SB_OPERAND_4_COMPONENT_SELECTION_MODE.values[bytes.readBits(2)];
      if (selectionMode == D3D10_SB_OPERAND_4_COMPONENT_SELECTION_MODE.D3D10_SB_OPERAND_4_COMPONENT_MASK_MODE) {
        mask = D3D10_SB_OPERAND_4_COMPONENT_MASK.values[bytes.readBits(4)];
        bytes.readBits(4);
      }
      else if (selectionMode == D3D10_SB_OPERAND_4_COMPONENT_SELECTION_MODE.D3D10_SB_OPERAND_4_COMPONENT_SWIZZLE_MODE) {
        swizzle = SwizzleMask.read(bytes);
      }
      else if (selectionMode == D3D10_SB_OPERAND_4_COMPONENT_SELECTION_MODE.D3D10_SB_OPERAND_4_COMPONENT_SELECT_1_MODE) {
        componentName = D3D10_SB_4_COMPONENT_NAME.values[bytes.readBits(2)];
        bytes.readBits(6);
      }
    }
    else if (numComponents == D3D10_SB_OPERAND_NUM_COMPONENTS.D3D10_SB_OPERAND_N_COMPONENT) {
      numComponentsValue = bytes.readBits(10);
    }

    operandType = D3D10_SB_OPERAND_TYPE.values[bytes.readBits(8)];
    indexDimension = D3D10_SB_OPERAND_INDEX_DIMENSION.values[bytes.readBits(2)];
    var indices = indexDimension.index;
    var indicesReserved = 3 - indices;
    if (indices > 0) {
      indexData = List.generate(
        indices,
        (i) => IndexData.read1(bytes)
      );
    }
    bytes.readBits(indicesReserved * 3);

    var isExtended = bytes.readBit() == 1;
    while (isExtended) {
      var extendedOperandType = D3D10_SB_EXTENDED_OPERAND_TYPE.values[bytes.readBits(6)];
      switch (extendedOperandType) {
        case D3D10_SB_EXTENDED_OPERAND_TYPE.D3D10_SB_EXTENDED_OPERAND_MODIFIER:
          if (modifier != null || minPrecision != null) throw Exception("Modifier or minPrecision already set");
          modifier = D3D10_SB_OPERAND_MODIFIER.values[bytes.readBits(8)];
          minPrecision = D11_SB_OPERAND_MIN_PRECISION.values[bytes.readBits(3)];
          break;
        default:
          // bytes.readBits(11);
          // break;
          throw Exception("Unknown extended operand type $extendedOperandType");
      }
      bytes.readBits(14);
      isExtended = bytes.readBit() == 1;
    }

    if (operandType == D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_IMMEDIATE32) {
      _values = Uint8List.fromList(bytes.readUint8List(4 * numComponentsValue));
    }
    else if (operandType == D3D10_SB_OPERAND_TYPE.D3D10_SB_OPERAND_TYPE_IMMEDIATE64) {
      _values = Uint8List.fromList(bytes.readUint8List(8 * numComponentsValue));
      _is32Bit = false;
    }

    if (indexData != null) {
      for (var index in indexData!) {
        assert(bytes.isByteAligned);
        index.read2(bytes);
      }
    }
  }
}
