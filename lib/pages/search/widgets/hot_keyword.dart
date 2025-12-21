// ignore: file_names
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HotKeyword extends StatelessWidget {
  final double? width;
  final List? hotSearchList;
  final Function? onClick;
  final bool showRecommendReason;

  const HotKeyword({
    this.width,
    this.hotSearchList,
    this.onClick,
    this.showRecommendReason = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outline;


    if (hotSearchList == null || hotSearchList!.isEmpty) {
      return const SizedBox();
    }

    return Wrap(
      runSpacing: 0.4,
      spacing: 5.0,
      children: [
        for (var i in hotSearchList!)
          SizedBox(
            width: width! / 2 - 4,
            child: Material(
              borderRadius: BorderRadius.circular(3),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () {
                  onClick!(i.keyword);
                },
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 2,
                      right: hotSearchList!.indexOf(i) % 2 == 1 ? 10 : 0),
                  child: Tooltip(
                    message: i.keyword!,
                    child: Row(
                      children: [
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(6, 5, 4, 5),
                            child: Text(
                              i.keyword!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        if (i.icon != null && i.icon != '')
                          SizedBox(
                            height: 15,
                            child: CachedNetworkImage(
                              imageUrl: i.icon!,
                              height: 15.0,
                              errorWidget: (context, url, error) =>
                                  const SizedBox(),
                            ),
                          )
                        else if (i.showLiveIcon == true)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6699),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (showRecommendReason &&
                            i.recommendReason != null &&
                            i.recommendReason != '')
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                i.recommendReason!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: outlineColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
