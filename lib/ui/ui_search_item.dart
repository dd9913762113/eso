import 'package:eso/api/api.dart';
import 'package:eso/ui/ui_image_item.dart';
import 'package:flutter/material.dart';
import '../database/search_item.dart';
import '../utils.dart';

class UiSearchItem extends StatelessWidget {
  final SearchItem item;
  final bool showType;

  const UiSearchItem({
    @required this.item,
    this.showType = false,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UiSearchItem(
      origin: showType ? item.origin : "",
      cover: item.cover,
      name: item.name,
      author: item.author,
      chapter: item.chapter,
      description: item.description,
      contentTypeName: showType ? API.getRuleContentTypeName(item.ruleContentType) : "",
    );
  }
}

class _UiSearchItem extends StatelessWidget {
  final String origin;
  final String cover;
  final String name;
  final String author;
  final String chapter;
  final String description;
  final String contentTypeName;

  const _UiSearchItem({
    this.origin,
    this.cover,
    this.name,
    this.author,
    this.chapter,
    this.description,
    this.contentTypeName,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: 105, minWidth: double.infinity),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor, height: 1.5),
        overflow: TextOverflow.ellipsis,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 80,
              height: 104,
              child: UIImageItem(cover: cover),
            ),
            SizedBox(
              width: 8,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          name?.trim() ?? '',
                          maxLines: 2,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyText1.color,
                            fontSize: 15
                          ),
                        ),
                      ),
                      Utils.empty(origin?.trim()) ? SizedBox(width: 2) : Text(
                        origin.trim(),
                        maxLines: 1,
                        style: TextStyle(
                          color:
                          Theme.of(context).textTheme.bodyText1.color.withOpacity(0.7),
                        ),
                      ),
                      contentTypeName != null && contentTypeName.isNotEmpty
                          ? Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          contentTypeName,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.4,
                            color: Colors.white,
                            textBaseline: TextBaseline.alphabetic,
                          ),
                        ),
                      ) : SizedBox(),
                    ],
                  ),
                  Utils.empty(author?.trim()) ? SizedBox() : Text(
                    author.trim(),
                    maxLines: 1,
                  ),
                  Utils.empty(chapter?.trim()) ? SizedBox() : Text(
                    chapter.trim(),
                    maxLines: 2,
                  ),
                  Utils.empty(description?.trim()) ? SizedBox() : Text(
                    description.trim(),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
