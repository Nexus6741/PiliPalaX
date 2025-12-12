import 'result.dart';

class TopicCardList {
  bool? hasMore;
  List<TopicCardItem>? items;
  String? offset;
  TopicSortByConf? topicSortByConf;

  TopicCardList({
    this.hasMore,
    this.items,
    this.offset,
    this.topicSortByConf,
  });

  factory TopicCardList.fromJson(Map<String, dynamic> json) => TopicCardList(
        hasMore: json['has_more'] as bool?,
        items: (json['items'] as List<dynamic>?)
            ?.map((e) => TopicCardItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        offset: json['offset'] as String?,
        topicSortByConf: json['topic_sort_by_conf'] == null
            ? null
            : TopicSortByConf.fromJson(
                json['topic_sort_by_conf'] as Map<String, dynamic>,
              ),
      );
}

class TopicCardItem {
  DynamicItemModel? dynamicCardItem;
  String? topicType;

  TopicCardItem({this.dynamicCardItem, this.topicType});

  factory TopicCardItem.fromJson(Map<String, dynamic> json) => TopicCardItem(
        dynamicCardItem: json['dynamic_card_item'] == null
            ? null
            : DynamicItemModel.fromJson(
                json['dynamic_card_item'] as Map<String, dynamic>,
              ),
        topicType: json['topic_type'] as String?,
      );
}

class TopicSortByConf {
  List<AllSortBy>? allSortBy;
  int? defaultSortBy;
  int? showSortBy;

  TopicSortByConf({this.allSortBy, this.defaultSortBy, this.showSortBy});

  factory TopicSortByConf.fromJson(Map<String, dynamic> json) {
    return TopicSortByConf(
      allSortBy: (json['all_sort_by'] as List<dynamic>?)
          ?.map((e) => AllSortBy.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultSortBy: json['default_sort_by'] as int?,
      showSortBy: json['show_sort_by'] as int?,
    );
  }
}

class AllSortBy {
  int? sortBy;
  String? sortName;

  AllSortBy({this.sortBy, this.sortName});

  factory AllSortBy.fromJson(Map<String, dynamic> json) => AllSortBy(
        sortBy: json['sort_by'] as int?,
        sortName: json['sort_name'] as String?,
      );
}
