import 'dart:io';
import 'dart:ui';

import 'package:eso/page/langding_page.dart';
import 'package:eso/utils.dart';
import 'package:eso/utils/cache_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../profile.dart';
import 'theme_setting.dart';

class FontFamilyPage extends StatelessWidget {
  const FontFamilyPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (context) => _FontFamilyProvider(),
        builder: (context, child) {
          final fontFamilyProvider =
              Provider.of<_FontFamilyProvider>(context, listen: false);
          context.select((_FontFamilyProvider provider) => provider._ttfList?.length);
          final profile = Provider.of<Profile>(context, listen: true);
          return Material(
            child: Container(
              decoration: globalDecoration,
              child: CupertinoPageScaffold(
                backgroundColor: Colors.transparent,
                navigationBar: CupertinoNavigationBar(
                  backgroundColor: Colors.transparent,
                  middle: Text("全局字体"),
                  border: null,
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text("添加"),
                    onPressed: () => fontFamilyProvider.pickFont(context),
                  ),
                ),
                child: fontFamilyProvider.ttfList == null
                    ? LandingPage()
                    : ListView(
                        children: [
                          _buildFontListTile("默认", null, profile),
                          _buildFontListTile("Roboto", 'Roboto', profile),
                          for (final ttf in fontFamilyProvider.ttfList)
                            _buildFontListTile(ttf, ttf, profile),
                        ],
                      ),
              ),
            ),
          );
        });

    // return Material(
    //   child: CupertinoPageScaffold(
    //     backgroundColor: CupertinoColors.systemGroupedBackground,
    //     navigationBar: CupertinoNavigationBar(
    //       middle: Text("全局字体"),
    //       border: null,
    //       trailing: CupertinoButton(
    //         padding: EdgeInsets.zero,
    //         child: Text("添加"),
    //         onPressed: () => fontFamilyProvider.pickFont(context),
    //       ),
    //       // backgroundColor: CupertinoDynamicColor.withBrightness(
    //       //   color: Color(0xF0F9F9F9),
    //       //   darkColor: Color(0xF01D1D1D),
    //       // ),
    //     ),
    //     child: ChangeNotifierProvider(
    //       create: (context) => _FontFamilyProvider(),
    //       builder: (context, child) {
    //         context.select(
    //             (_FontFamilyProvider provider) => provider._ttfList?.length);
    //         final profile = Provider.of<Profile>(context, listen: true);
    //         final fontFamilyProvider =
    //             Provider.of<_FontFamilyProvider>(context, listen: false);
    //         if (fontFamilyProvider.ttfList == null) {
    //           return LandingPage();
    //         }
    //         return ListView(
    //           children: [
    //             _buildFontListTile("默认", null, profile),
    //             _buildFontListTile("Roboto", 'Roboto', profile),
    //             for (final ttf in fontFamilyProvider.ttfList)
    //               _buildFontListTile(ttf, ttf, profile),
    //             // ListTile(
    //             //   onTap: () => fontFamilyProvider.pickFont(context),
    //             //   title: Row(
    //             //     children: [
    //             //       Icon(Icons.add_outlined),
    //             //       Expanded(
    //             //         child: Text(
    //             //           '添加本地字体文件',
    //             //           overflow: TextOverflow.ellipsis,
    //             //         ),
    //             //       ),
    //             //     ],
    //             //   ),
    //             //   subtitle: Text('路径 ${fontFamilyProvider.dir}'),
    //             // )
    //           ],
    //         );
    //       },
    //     ),
    //   ),
    // );
  }

  Widget _buildFontListTile(String name, String fontFamily, Profile profile) {
    return ListTile(
      title: Text(
        name,
        style: TextStyle(fontFamily: fontFamily),
      ),
      subtitle: Text(
        '这是一段测试文本',
        style: TextStyle(fontFamily: fontFamily),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (profile.fontFamily == fontFamily)
            Text(
              '√全局 ',
              style: TextStyle(
                color: Color(profile.primaryColor),
              ),
            ),
        ],
      ),
      onTap: () {
        profile.fontFamily = fontFamily;
      },
      // onLongPress: () => profile.novelFontFamily = fontFamily,
    );
  }
}

class _FontFamilyProvider with ChangeNotifier {
  CacheUtil _cacheUtil;
  String _dir;
  String get dir => _dir;
  PlatformFile _platformFile;
  Set<String> _ttfList;
  Set<String> get ttfList => _ttfList;

  _FontFamilyProvider() {
    init();
  }

  void init() async {
    _cacheUtil = CacheUtil(backup: true, basePath: "font");
    try {
      final p = await CacheUtil.requestPermission();
      if (!p) {
        Utils.toast('读取字体需要存储权限');
        _ttfList = Set();
        return;
      }
    } catch (e) {
      Utils.toast('读取字体需要存储权限');
      _ttfList = Set();
      return;
    }
    _dir = await _cacheUtil.cacheDir();
    refreshList();
  }

  Future<void> refreshList() async {
    if (!Directory(_dir).existsSync()) {
      await Directory(_dir).create(recursive: true);
    }
    await Future.delayed(Duration(milliseconds: 500));
    final directory = Directory(_dir);
    final files = directory.listSync();

    _ttfList =
        files.map((file) => file.path.substring(file.parent.path.length + 1)).toSet();

    _ttfList.forEach((ttf) async => await _loadFont(ttf));

    notifyListeners();
    return;
  }

  void pickFont(BuildContext context) async {
    FilePickerResult result = await FilePicker.platform.pickFiles(
        withData: false,
        type: FileType.any,
        // allowedExtensions: ["ttf", "ttc", "otf"],
        dialogTitle: "选择字体文件导入亦搜");
    if (result == null) {
      Utils.toast("未选择文件");
      // if (_platformFile == null) {
      //   if (Platform.isAndroid || Platform.isIOS) {
      //     Navigator.of(context).pop();
      //   }
      // }
      return;
    }
    _platformFile = result.files.first;

    // String ttf = await FilesystemPicker.open(
    //   title: '选择字体',
    //   context: context,
    //   rootName: _dir,
    //   rootDirectory: Directory(_dir),
    //   fsType: FilesystemType.file,
    //   folderIconColor: Colors.teal,
    //   allowedExtensions: ['.ttf', '.ttc', '.otf'],
    //   fileTileSelectMode: FileTileSelectMode.wholeTile,
    //   requestPermission: CacheUtil.requestPermission,
    // );

    if (_platformFile == null) {
      Utils.toast('未选取字体文件');
      return;
    }
    if (!["ttf", "ttc", "otf"].contains(_platformFile.extension)) {
      Utils.toast('请选择字体文件');
      return;
    }

    final file = File(_platformFile.path);
    final name = _platformFile.name;
    await _cacheUtil.putFile(name, file);
    await loadFontFromList(file.readAsBytesSync(), fontFamily: name);
    _ttfList.add(name);
    notifyListeners();

    Utils.toast('字体已保存到$_dir');
    // if (Global.isDesktop) {
    //   final f = await showOpenPanel(
    //     confirmButtonText: '选择字体',
    //     allowedFileTypes: <FileTypeFilterGroup>[
    //       FileTypeFilterGroup(
    //         label: '字体文件',
    //         fileExtensions: <String>['ttf', 'ttc', 'otf'],
    //       ),
    //       FileTypeFilterGroup(
    //         label: '其他',
    //         fileExtensions: <String>[],
    //       ),
    //     ],
    //   );
    //   if (f.canceled) {
    //     Utils.toast('未选取字体文件');
    //     return;
    //   }
    //   final ttf = f.paths.first;
    //   final file = File(ttf);
    //   final name = Utils.getFileName(ttf);
    //   await _cacheUtil.putFile(name, file);
    //   await loadFontFromList(file.readAsBytesSync(), fontFamily: name);
    //   _ttfList.add(name);
    //   notifyListeners();
    //   Utils.toast('字体已保存到$_dir');
    // } else {
    //   FilePickerResult ttfPick = await FilePicker.platform.pickFiles(
    //     type: FileType.custom,
    //   );
    //   if (ttfPick == null) {
    //     Utils.toast('未选取字体文件');
    //     return;
    //   }
    //   final ttf = ttfPick.files.single;
    //   if (ttf.extension != 'ttf' && ttf.extension != 'ttc' && ttf.extension != 'otf') {
    //     Utils.toast('只支持扩展名为ttf或otf或ttc的字体文件');
    //     return;
    //   }
    //   await _cacheUtil.putFile(ttf.name, File(ttf.path));
    //   await loadFontFromList(ttf.bytes, fontFamily: ttf.name);
    //   _ttfList.add(ttf.name);
    //   notifyListeners();
    //   Utils.toast('字体已保存到$_dir');
    // }
  }

  Future<void> _loadFont(String fontName) async {
    await loadFontFromList(await File(dir + fontName).readAsBytes(),
        fontFamily: fontName);
  }
}
