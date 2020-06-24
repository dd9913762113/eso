import 'dart:convert';
import 'dart:ui';

import 'package:eso/api/api_from_rule.dart';
import 'package:eso/database/rule.dart';
import 'package:eso/model/edit_source_provider.dart';
import 'package:eso/page/langding_page.dart';
import 'package:eso/page/source/edit_rule_page.dart';
import 'package:eso/ui/edit/bottom_input_border.dart';
import 'package:eso/ui/edit/edit_view.dart';
import 'package:eso/ui/edit/search_edit.dart';
import 'package:eso/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../discover_search_page.dart';

const int ADD_RULE = 0;
const int ADD_FROM_CLIPBOARD = 1;
const int FROM_FILE = 2;
const int FROM_CLOUD = 3;
const int FROM_YICIYUAN = 4;
const int DELETE_ALL_RULES = 5;
const int FROM_CLIPBOARD = 6;

//图源编辑
class EditSourcePage extends StatefulWidget {
  const EditSourcePage({Key key}) : super(key: key);

  @override
  _EditSourcePageState createState() => _EditSourcePageState();

  static void showURLDialog(
    BuildContext context,
    bool isLoadingUrl,
    EditSourceProvider provider,
    bool isYICIYUAN,
  ) async {
    var onSubmitted = (url) async {
      Toast.show("开始导入$url", context, duration: 1);
      final count = await provider.addFromUrl(url.trim(), isYICIYUAN);
      Toast.show("导入完成，一共$count条", context, duration: 1);
      Navigator.pop(context);
    };
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Theme.of(context).canvasColor,
        title: Text("网络导入"),
        content: EditView(
          autofocus: true,
          controller: _controller,
          hint: "输入源地址, 回车开始导入",
          border: BottomInputBorder(Theme.of(context).dividerColor),
          enabled: !isLoadingUrl,
          onSubmitted: (url) => onSubmitted(url),
        ),
        actions: <Widget>[
          FlatButton(
              child: Text('取消', style: TextStyle(color: Theme.of(context).hintColor)),
              onPressed: () => Navigator.pop(context)),
          FlatButton(child: Text('确定'), onPressed: () => onSubmitted(_controller.text)),
        ],
      ),
    );
  }

  static void showDeleteAllDialog(BuildContext context, EditSourceProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Text("警告"),
            ],
          ),
          content: Text("是否删除所有站点？"),
          actions: [
            FlatButton(
              child: Text(
                "取消",
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FlatButton(
              child: Text(
                "确定",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                provider.deleteAllRules();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _EditSourcePageState extends State<EditSourcePage> {
  final SlidableController slidableController = SlidableController();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditSourceProvider>(
      create: (context) => EditSourceProvider(),
      builder: (context, child) => Scaffold(
        appBar: AppBarEx(
          titleSpacing: 0.0,
          title: SearchEdit(
            hintText:
                "搜索名称和分组(共${context.select((EditSourceProvider provider) => provider.rules)?.length ?? 0}条)",
            onSubmitted:
                Provider.of<EditSourceProvider>(context, listen: false).getRuleListByName,
            onChanged: Provider.of<EditSourceProvider>(context, listen: false)
                .getRuleListByNameDebounce,
          ),
          actions: [
            AppBarButton(
              icon: Icon(Icons.check_circle_outline),
              onPressed: Provider.of<EditSourceProvider>(context, listen: false)
                  .toggleCheckAllRule,
            ),
            _buildpopupMenu(
              context,
              context.select((EditSourceProvider provider) => provider.isLoadingUrl),
              Provider.of<EditSourceProvider>(context, listen: false),
            ),
          ],
        ),
        body: Consumer<EditSourceProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return LandingPage();
            }
            return ListView.separated(
              separatorBuilder: (BuildContext context, int index) => Container(),
              itemCount: provider.rules.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return _buildItem(context, provider, provider.rules[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, EditSourceProvider provider, Rule rule) {
    return Slidable(
      key: Key(rule.host),
      controller: slidableController,
      actionPane: SlidableDrawerActionPane(),
      actionExtentRatio: 0.2,
      showAllActionsThreshold: 0.2,
      movementDuration: Duration(milliseconds: 100),
      closeOnScroll: true,
      child: InkWell(
        child: ListTile(
          title: Text('${rule.name}'),
          subtitle: Text(
            rule.author == '' ? '${rule.host}' : '@${rule.author}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          //  leading: Checkbox(
          //      value: rule.enableSearch,
          //      activeColor: Colors.amber,
          //  ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppBarButton(
                  icon: Icon(Icons.create),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (context) => EditRulePage(rule: rule)))
                      .whenComplete(() => provider.refreshData())),
              // Checkbox(
              //   value: rule.enableSearch,
              //   onChanged: null,
              // )
            ],
          ),
          onTap: () {
            SlidableState activeState = slidableController.activeState;
            if (activeState != null && !activeState.overallMoveAnimation.isDismissed) {
              slidableController.activeState.close();
            } else {
              provider.toggleEnableSearch(rule);
            }
          },
          onLongPress: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => DiscoverSearchPage(
                    originTag: rule.id,
                    origin: rule.name,
                    discoverMap: APIFromRUle(rule).discoverMap(),
                  ))),
        ),
      ),
      secondaryActions: <Widget>[
        IconSlideAction(
          caption: '置顶',
          color: Colors.black45,
          icon: Icons.vertical_align_top,
          onTap: () => provider.setSortMax(rule),
        ),
        IconSlideAction(
          caption: '删除',
          color: Colors.red,
          icon: Icons.delete,
          onTap: () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("警告"),
                    content: Text("是否删除该站点？"),
                    actions: [
                      FlatButton(
                        child: Text(
                          "取消",
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      FlatButton(
                        child: Text(
                          "确定",
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () {
                          provider.deleteRule(rule);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                });
          },
        ),
      ],
    );
  }

  Future<bool> _addFromClipBoard(
      BuildContext context, EditSourceProvider provider, bool showEditPage) async {
    final text = await Clipboard.getData(Clipboard.kTextPlain);
    try {
      final rule = Rule.fromJson(jsonDecode(text.text));
      if (provider.rules.any((r) => r.id == rule.id)) {
        await Global.ruleDao.insertOrUpdateRule(rule);
        provider.rules.removeWhere((r) => r.id == rule.id);
        provider.rules.add(rule);
        Toast.show("更新成功", context);
      } else {
        provider.rules.add(rule);
        await Global.ruleDao.insertOrUpdateRule(rule);
        Toast.show("添加成功", context);
      }
      if (showEditPage) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => EditRulePage(rule: rule)))
            .whenComplete(() => provider.refreshData());
      } else {
        provider.refreshData(false);
      }
      return true;
    } catch (e) {
      Toast.show("失败！" + e.toString(), context, duration: 2);
      return false;
    }
  }

  Widget _buildpopupMenu(
      BuildContext context, bool isLoadingUrl, EditSourceProvider provider) {
    final primaryColor = Theme.of(context).primaryColor;
    const list = [
      {'title': '新建空白规则', 'icon': Icons.code, 'type': ADD_RULE},
      {'title': '从剪贴板新建', 'icon': Icons.note_add, 'type': ADD_FROM_CLIPBOARD},
      {'title': '粘贴单条规则', 'icon': Icons.content_paste, 'type': FROM_CLIPBOARD},
      // {'title': '阅读或异次元', 'icon': Icons.cloud_queue, 'type': FROM_YICIYUAN},
      // {'title': '文件导入', 'icon': Icons.file_download, 'type': FROM_FILE},
      {'title': '网络导入', 'icon': Icons.cloud_queue, 'type': FROM_CLOUD},
      {'title': '清空源', 'icon': Icons.clear_all, 'type': DELETE_ALL_RULES},
    ];
    return PopupMenuButton<int>(
      elevation: 20,
      icon: Icon(Icons.add),
      offset: Offset(0, 40),
      onSelected: (int value) {
        switch (value) {
          case ADD_RULE:
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => EditRulePage()))
                .whenComplete(() => provider.refreshData());
            break;
          case ADD_FROM_CLIPBOARD:
            _addFromClipBoard(context, provider, true);
            break;
          case FROM_CLIPBOARD:
            _addFromClipBoard(context, provider, false);
            break;
          case FROM_FILE:
            Toast.show("从本地文件导入", context);
            break;
          case FROM_CLOUD:
            EditSourcePage.showURLDialog(context, isLoadingUrl, provider, false);
            break;
          case FROM_YICIYUAN:
            EditSourcePage.showURLDialog(context, isLoadingUrl, provider, true);
            break;
          case DELETE_ALL_RULES:
            EditSourcePage.showDeleteAllDialog(context, provider);
            break;
          default:
        }
      },
      itemBuilder: (context) => list
          .map(
            (element) => PopupMenuItem<int>(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(element['title']),
                  Icon(element['icon'], color: primaryColor, size: 16),
                ],
              ),
              value: element['type'],
            ),
          )
          .toList(),
    );
  }
}
