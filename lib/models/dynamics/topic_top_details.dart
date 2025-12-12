import 'topic_item.dart';

class TopicTopDetails {
  TopicItem? topicItem;
  TopicCreator? topicCreator;
  bool? hasCreateJurisdiction;
  int? wordColor;
  bool? closePubLayerEntry;

  TopicTopDetails({
    this.topicItem,
    this.topicCreator,
    this.hasCreateJurisdiction,
    this.wordColor,
    this.closePubLayerEntry,
  });

  factory TopicTopDetails.fromJson(Map<String, dynamic> json) =>
      TopicTopDetails(
        topicItem: json['topic_item'] == null
            ? null
            : TopicItem.fromJson(json['topic_item'] as Map<String, dynamic>),
        topicCreator: json['topic_creator'] == null
            ? null
            : TopicCreator.fromJson(
                json['topic_creator'] as Map<String, dynamic>),
        hasCreateJurisdiction: json['has_create_jurisdiction'] as bool?,
        wordColor: json['word_color'] as int?,
        closePubLayerEntry: json['close_pub_layer_entry'] as bool?,
      );
}

class TopicCreator {
  int? uid;
  String? face;
  String? name;

  TopicCreator({
    this.uid,
    this.face,
    this.name,
  });

  factory TopicCreator.fromJson(Map<String, dynamic> json) => TopicCreator(
        uid: json['uid'] as int?,
        face: json['face'] as String?,
        name: json['name'] as String?,
      );
}
