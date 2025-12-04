/// 视频预览缩略图（雪碧图）数据模型
class VideoShotData {
  /// 预览数据地址（可选）
  String? pvdata;

  /// 每张雪碧图横向缩略图数量
  int imgXLen;

  /// 每张雪碧图纵向缩略图数量
  int imgYLen;

  /// 单个缩略图宽度
  double imgXSize;

  /// 单个缩略图高度
  double imgYSize;

  /// 每张雪碧图包含的缩略图总数
  late final int totalPerImage = imgXLen * imgYLen;

  /// 雪碧图 URL 列表
  List<String> image;

  /// 时间索引数组（秒数）
  List<int> index;

  VideoShotData({
    this.pvdata,
    required this.imgXLen,
    required this.imgYLen,
    required this.imgXSize,
    required this.imgYSize,
    required this.image,
    required this.index,
  });

  factory VideoShotData.fromJson(Map<String, dynamic> json) => VideoShotData(
        pvdata: json["pvdata"],
        imgXLen: json["img_x_len"] ?? 10,
        imgYLen: json["img_y_len"] ?? 10,
        imgXSize: (json["img_x_size"] as num?)?.toDouble() ?? 0,
        imgYSize: (json["img_y_size"] as num?)?.toDouble() ?? 0,
        image: (json["image"] as List?)?.map((e) {
              String url = e as String;
              // 处理协议相对 URL (//example.com/...)
              if (url.startsWith('//')) {
                url = 'https:$url';
              } else if (url.startsWith('http://')) {
                url = url.replaceFirst('http://', 'https://');
              }
              return url;
            }).toList() ??
            [],
        index: (json["index"] as List?)?.cast<int>() ?? [],
      );
}
