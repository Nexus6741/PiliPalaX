/// 通用配对类，用于存储两个值
class Pair<T, R> {
  Pair({
    required this.first,
    required this.second,
  });
  T first;
  R second;
}

/// 通用三元组类，用于存储三个值
class Triple<T, R, S> {
  Triple({
    required this.first,
    required this.second,
    required this.third,
  });
  T first;
  R second;
  S third;
}
