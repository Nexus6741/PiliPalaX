/// 合作视频 Staff 模型
class Staff {
  int? mid;
  String? title;
  String? name;
  String? face;
  Vip? vip;
  Official? official;

  Staff({
    this.mid,
    this.title,
    this.name,
    this.face,
    this.vip,
    this.official,
  });

  Staff.fromJson(Map<String, dynamic> json) {
    mid = json["mid"];
    title = json["title"];
    name = json["name"];
    face = json["face"];
    vip = json["vip"] == null ? null : Vip.fromJson(json["vip"]);
    official =
        json['official'] == null ? null : Official.fromJson(json['official']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["mid"] = mid;
    data["title"] = title;
    data["name"] = name;
    data["face"] = face;
    data["vip"] = vip?.toJson();
    data["official"] = official?.toJson();
    return data;
  }
}

/// VIP 信息
class Vip {
  int? type;
  int? status;
  int? dueDate;
  int? vipPayType;
  int? themeType;
  Label? label;
  int? avatarSubscript;
  String? nicknameColor;

  Vip({
    this.type,
    this.status,
    this.dueDate,
    this.vipPayType,
    this.themeType,
    this.label,
    this.avatarSubscript,
    this.nicknameColor,
  });

  Vip.fromJson(Map<String, dynamic> json) {
    type = json["type"];
    status = json["status"];
    dueDate = json["due_date"];
    vipPayType = json["vip_pay_type"];
    themeType = json["theme_type"];
    label = json["label"] == null ? null : Label.fromJson(json["label"]);
    avatarSubscript = json["avatar_subscript"];
    nicknameColor = json["nickname_color"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["type"] = type;
    data["status"] = status;
    data["due_date"] = dueDate;
    data["vip_pay_type"] = vipPayType;
    data["theme_type"] = themeType;
    data["label"] = label?.toJson();
    data["avatar_subscript"] = avatarSubscript;
    data["nickname_color"] = nicknameColor;
    return data;
  }
}

class Label {
  String? path;
  String? text;
  String? labelTheme;
  String? textColor;
  int? bgStyle;
  String? bgColor;
  String? borderColor;

  Label({
    this.path,
    this.text,
    this.labelTheme,
    this.textColor,
    this.bgStyle,
    this.bgColor,
    this.borderColor,
  });

  Label.fromJson(Map<String, dynamic> json) {
    path = json["path"];
    text = json["text"];
    labelTheme = json["label_theme"];
    textColor = json["text_color"];
    bgStyle = json["bg_style"];
    bgColor = json["bg_color"];
    borderColor = json["border_color"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["path"] = path;
    data["text"] = text;
    data["label_theme"] = labelTheme;
    data["text_color"] = textColor;
    data["bg_style"] = bgStyle;
    data["bg_color"] = bgColor;
    data["border_color"] = borderColor;
    return data;
  }
}

/// 认证信息
class Official {
  int? role;
  String? title;
  String? desc;
  int? type;

  Official({
    this.role,
    this.title,
    this.desc,
    this.type,
  });

  Official.fromJson(Map<String, dynamic> json) {
    role = json["role"];
    title = json["title"];
    desc = json["desc"];
    type = json["type"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["role"] = role;
    data["title"] = title;
    data["desc"] = desc;
    data["type"] = type;
    return data;
  }
}
