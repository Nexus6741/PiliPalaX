class PgcConditionValue {
  String? keyword;
  String? name;

  PgcConditionValue({
    this.keyword,
    this.name,
  });

  factory PgcConditionValue.fromJson(Map<String, dynamic> json) =>
      PgcConditionValue(
        keyword: json['keyword'] as String?,
        name: json['name'] as String?,
      );
}
