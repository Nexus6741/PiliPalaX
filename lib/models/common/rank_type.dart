import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:PiliPalaX/pages/rank/zone/index.dart';

enum RandType {
  all,
  animation,
  music,
  dance,
  game,
  knowledge,
  technology,
  sport,
  car,
  food,
  animal,
  madness,
  fashion,
  entertainment,
  film,
}

extension RankTypeDesc on RandType {
  String get description => [
        '全站',
        '动画',
        '音乐',
        '舞蹈',
        '游戏',
        '知识',
        '科技',
        '运动',
        '汽车',
        '美食',
        '动物',
        '鬼畜',
        '时尚',
        '娱乐',
        '影视',
      ][index];

  String get id => [
        'all',
        'animation',
        'music',
        'dance',
        'game',
        'knowledge',
        'technology',
        'sport',
        'car',
        'food',
        'animal',
        'madness',
        'fashion',
        'entertainment',
        'film',
      ][index];
}

List tabsConfig = [
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '全站',
    'type': RandType.all,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '0'),
    'page': const ZonePage(rid: 0),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '动画',
    'type': RandType.animation,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1005'),
    'page': const ZonePage(rid: 1005),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '音乐',
    'type': RandType.music,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1003'),
    'page': const ZonePage(rid: 1003),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '舞蹈',
    'type': RandType.dance,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1004'),
    'page': const ZonePage(rid: 1004),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '游戏',
    'type': RandType.game,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1008'),
    'page': const ZonePage(rid: 1008),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '知识',
    'type': RandType.knowledge,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1010'),
    'page': const ZonePage(rid: 1010),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '科技',
    'type': RandType.technology,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1012'),
    'page': const ZonePage(rid: 1012),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '运动',
    'type': RandType.sport,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1018'),
    'page': const ZonePage(rid: 1018),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '汽车',
    'type': RandType.car,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1013'),
    'page': const ZonePage(rid: 1013),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '美食',
    'type': RandType.food,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1020'),
    'page': const ZonePage(rid: 1020),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '动物',
    'type': RandType.animal,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1024'),
    'page': const ZonePage(rid: 1024),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '鬼畜',
    'type': RandType.madness,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1007'),
    'page': const ZonePage(rid: 1007),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '时尚',
    'type': RandType.fashion,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1014'),
    'page': const ZonePage(rid: 1014),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '娱乐',
    'type': RandType.entertainment,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1002'),
    'page': const ZonePage(rid: 1002),
  },
  {
    'icon': const Icon(
      Icons.live_tv_outlined,
      size: 15,
    ),
    'label': '影视',
    'type': RandType.film,
    'ctr': Get.put<ZoneController>(ZoneController(), tag: '1001'),
    'page': const ZonePage(rid: 1001),
  },
];
