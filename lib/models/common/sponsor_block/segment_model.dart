// ignore_for_file: non_constant_identifier_names

import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPalaX/models/common/sponsor_block/skip_type.dart';

class SegmentModel {
  SegmentModel({
    required this.UUID,
    required this.segmentType,
    required this.segmentStart,
    required this.segmentEnd,
    required this.skipType,
  });

  String UUID;
  SegmentType segmentType;
  int segmentStart;
  int segmentEnd;
  SkipType skipType;
  bool hasSkipped = false;
  bool hasShownButton = false; // 标记是否已显示过跳过按钮
}
