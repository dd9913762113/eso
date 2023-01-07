import 'menu_item.dart';

enum MenuRight {
  copy,
  cut,
  paste,
  all,
  clear,
}

List<DKMenuItem<MenuRight>> rightMenus = [
  DKMenuItem<MenuRight>(text: '复制', value: MenuRight.copy),
  DKMenuItem<MenuRight>(text: '剪切', value: MenuRight.cut),
  DKMenuItem<MenuRight>(text: '粘贴', value: MenuRight.paste),
  DKMenuItem<MenuRight>(text: '全选', value: MenuRight.all),
  DKMenuItem<MenuRight>(text: '清空', value: MenuRight.clear),
];
