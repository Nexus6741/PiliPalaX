class NumUtils {
  // 数字格式化（如：1234 -> 1.2k）
  static String numFormat(int? num) {
    if (num == null) return '-';

    if (num < 1000) {
      return num.toString();
    } else if (num < 10000) {
      return '${(num / 1000).toStringAsFixed(1)}k';
    } else if (num < 100000000) {
      return '${(num / 10000).toStringAsFixed(1)}万';
    } else {
      return '${(num / 100000000).toStringAsFixed(1)}亿';
    }
  }
}
