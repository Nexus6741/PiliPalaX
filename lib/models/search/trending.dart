// 搜索热搜榜单模型
class SearchTrendingModel {
  List<SearchTrendingItem>? list;
  List<SearchTrendingItem>? topList;

  SearchTrendingModel({this.list, this.topList});

  factory SearchTrendingModel.fromJson(Map<String, dynamic> json) {
    return SearchTrendingModel(
      list: json['list'] != null
          ? (json['list'] as List)
              .map((e) => SearchTrendingItem.fromJson(e))
              .toList()
          : null,
      topList: json['top_list'] != null
          ? (json['top_list'] as List)
              .map((e) => SearchTrendingItem.fromJson(e))
              .toList()
          : null,
    );
  }
}

class SearchTrendingItem {
  String? keyword;
  String? showName;
  String? icon;
  bool? showLiveIcon;
  String? recommendReason;

  SearchTrendingItem({
    this.keyword,
    this.showName,
    this.icon,
    this.showLiveIcon,
    this.recommendReason,
  });

  factory SearchTrendingItem.fromJson(Map<String, dynamic> json) {
    return SearchTrendingItem(
      keyword: json['keyword'],
      showName: json['show_name'],
      icon: json['icon'],
      showLiveIcon: json['show_live_icon'],
      recommendReason:
          json['recommend_reason']?.toString().replaceFirst('·', ' '),
    );
  }
}

// 搜索发现模型
class SearchRecommendModel {
  List<SearchTrendingItem>? list;

  SearchRecommendModel({this.list});

  factory SearchRecommendModel.fromJson(Map<String, dynamic> json) {
    return SearchRecommendModel(
      list: json['list'] != null
          ? (json['list'] as List)
              .map((e) => SearchTrendingItem.fromJson(e))
              .toList()
          : null,
    );
  }
}
