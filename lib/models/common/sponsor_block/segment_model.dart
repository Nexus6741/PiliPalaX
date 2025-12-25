import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';
import 'package:PiliPalaX/models/common/sponsor_block/skip_type.dart';

class SegmentModel {
  final String UUID;
  final SegmentType segmentType;
  final int segmentStart;
  final int segmentEnd;
  SkipType skipType;
  bool hasSkipped;
  bool hasShownButton;

  SegmentModel({
    required this.UUID,
    required this.segmentType,
    required this.segmentStart,
    required this.segmentEnd,
    required this.skipType,
    this.hasSkipped = false,
    this.hasShownButton = false,
  });
}
