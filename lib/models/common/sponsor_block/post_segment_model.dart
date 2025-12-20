import 'package:PiliPalaX/models/common/sponsor_block/action_type.dart';
import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';

class PostSegmentModel {
  PostSegmentModel({
    required this.segmentStart,
    required this.segmentEnd,
    required this.category,
    required this.actionType,
  });

  double segmentStart;
  double segmentEnd;
  SegmentType category;
  ActionType actionType;
}
