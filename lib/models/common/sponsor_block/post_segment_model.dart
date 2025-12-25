import 'package:PiliPalaX/common/widgets/pair.dart';
import 'package:PiliPalaX/models/common/sponsor_block/action_type.dart';
import 'package:PiliPalaX/models/common/sponsor_block/segment_type.dart';

class PostSegmentModel {
  Pair<double, double> segment;
  SegmentType category;
  ActionType actionType;

  PostSegmentModel({
    required this.segment,
    required this.category,
    required this.actionType,
  });
}
