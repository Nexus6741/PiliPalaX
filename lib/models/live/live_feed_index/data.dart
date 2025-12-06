import 'card_list.dart';

class LiveIndexData {
  List<LiveCardList>? cardList;
  int? isRollback;
  int? hasMore;
  int? triggerTime;
  int? isNeedRefresh;
  LiveCardList? followItem;
  LiveCardList? areaItem;

  LiveIndexData({
    this.cardList,
    this.isRollback,
    this.hasMore,
    this.triggerTime,
    this.isNeedRefresh,
    this.followItem,
    this.areaItem,
  });

  factory LiveIndexData.fromJson(Map<String, dynamic> json) {
    LiveCardList? followItem;
    LiveCardList? areaItem;
    List<LiveCardList>? cardList;

    if ((json['card_list'] as List<dynamic>?)?.isNotEmpty == true) {
      for (var item in json['card_list']) {
        switch (item['card_type']) {
          case 'my_idol_v1':
            followItem = LiveCardList.fromJson(item);
            break;
          case 'area_entrance_v3':
            areaItem = LiveCardList.fromJson(item);
            break;
          case 'small_card_v1':
            cardList ??= <LiveCardList>[];
            cardList.add(LiveCardList.fromJson(item));
            break;
        }
      }
    }

    return LiveIndexData(
      cardList: cardList,
      isRollback: json['is_rollback'] as int?,
      hasMore: json['has_more'] as int?,
      triggerTime: json['trigger_time'] as int?,
      isNeedRefresh: json['is_need_refresh'] as int?,
      followItem: followItem,
      areaItem: areaItem,
    );
  }
}
