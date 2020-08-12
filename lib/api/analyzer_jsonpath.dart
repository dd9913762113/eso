import 'dart:convert';

import 'analyzer.dart';
// import 'package:jsonpath/json_path.dart';
import 'package:json_path/json_path.dart';

class AnalyzerJSonPath implements Analyzer {
  final _jsonRulePattern = RegExp(r"\{(\$\.[^\}]+)\}");
  // json object
  dynamic _ctx;
  // [?(@.price)]
  final filterAttrPattern = RegExp(r"\[\?\(@\.(\w+)\)\]");

  @override
  AnalyzerJSonPath parse(content) {
    if (content is List || content is Map) {
      _ctx = content;
    } else {
      try {
        _ctx = jsonDecode("$content");
      } catch (e) {
        _ctx = ["$content"];
      }
    }
    return this;
  }

  @override
  dynamic getElements(String rule) {
    final m = filterAttrPattern.firstMatch(rule);
    var list = [];
    if (m != null) {
      // 允许一次
      final attr = m[1];
      list = JsonPath(rule.replaceFirst(m.group(0), "[?$attr]"), filter: {
        attr: (e) => e is Map && e[attr] != null,
      }).filter(_ctx).map((e) => e.value).toList();
    } else {
      list = JsonPath(rule).filter(_ctx).map((e) => e.value).toList();
    }
    if(list == null || list.isEmpty) return <String>[];
    if(list[0] is String){
      return list.join("  ");
    }
    return list;
  }

  @override
  String getString(String rule) {
    if (rule.contains("{\$.")) {
      return rule.splitMapJoin(
        _jsonRulePattern,
        onMatch: (match) => getString(match.group(1)),
        onNonMatch: (nonMatch) => nonMatch,
      );
    }
    // return JPath.compile(rule).search(_ctx);

    final m = filterAttrPattern.firstMatch(rule);
    if (m != null) {
      // 允许一次
      final attr = m[1];
      return JsonPath(rule.replaceFirst(m.group(0), "[?$attr]"), filter: {
        attr: (e) => e is Map && e[attr] != null,
      }).filter(_ctx).map((e) => e.value).join("  ");
    }
    return JsonPath(rule).filter(_ctx).map((e) => e.value).join("  ");
  }

  @override
  dynamic getStringList(String rule) {
    return getElements(rule);
  }
}

// dynamic $;
// dynamic jsonPath(dynamic obj, String expr) {
//   $ = obj;
//   if (expr != null && obj != null) {
//     P.trace(P.normalize(expr).replaceAll(RegExp(r"^\$;"), ""), obj, "\$");
//     return (P.result?.length ?? 0) != 0 ? P.result : false;
//   }
// }

// class P {
//   static const resultType = "VALUE";
//   static const result = [];
//   static String normalize(String expr) {
//     final subx = <String>[];
//     return expr
//         .replaceAllMapped(RegExp(r"[\['](\??\(.*?\))[\]']"), (match) {
//           subx.add(match.group(1));
//           return "[#" + (int.parse(match.group(1)) - 1).toString() + "]";
//         })
//         .replaceAll(RegExp(r"'?\.'?|\['?"), ";")
//         .replaceAll(RegExp(r";;;|;;"), ";..;")
//         .replaceAll(RegExp(r";$|'?\]|'$"), "")
//         .replaceAllMapped(RegExp(r"#([0-9]+)"), (match) {
//           return subx[int.parse(match.group(1))];
//         });
//   }

//   static String asPath(String path) {
//     final x = path.split(";");
//     var p = r"$";
//     for (var i = 1, n = x.length; i < n; i++)
//       p +=
//           RegExp(r"^[0-9*]+$").hasMatch(x[i]) ? ("[" + x[i] + "]") : ("['" + x[i] + "']");
//     return p;
//   }

//   static bool store(String path, val) {
//     if (path == null) result[result.length] = resultType == "PATH" ? asPath(path) : val;
//     return path != null;
//   }

//   static void trace(String expr, val, String path) {
//     if (expr != null) {
//       final xTemp = expr.split(";");
//       final loc = xTemp.removeAt(0);
//       final x = xTemp.join(";");
//       if (val != null && val[loc] != null) {
//         trace(x, val[loc], path + ";" + loc);
//       } else if (loc == "*") {
//         walk(loc, x, val, path, (m, l, x, v, p) {
//           trace(m + ";" + x, v, p);
//         });
//       } else if (loc == "..") {
//         walk(loc, x, val, path, (m, l, x, v, p) {
//           trace(m + ";" + x, v, p);
//         });
//       }
//     } else {
//       store(path, val);
//     }
//   }

//   static void walk(String loc, String expr, val, String path,
//       Function(String, String, String, dynamic, String) f) {
//     if (val is List) {
//       for (var i = 0, n = val.length; i < n; i++)
//         if (val.indexOf(i) > -1) f(i.toString(), loc, expr, val, path);
//     } else if (val is Map) {
//       for (var m in val.keys) if (val[m] != null) f(m, loc, expr, val, path);
//     }
//   }

//   static slice(String loc, String expr, val, String path) {
//     if (val is List) {
//       var len = val.length, start = 0, end = len, step = 1;
//       loc.replaceAllMapped(RegExp(r"^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$"), (match) {
//         start = int.parse(match.group(1) ?? start);
//         end = int.parse(match.group(2) ?? end);
//         step = int.parse(match.group(3) ?? step);
//         return "";
//       });
//       start = (start < 0) ? max(0, start + len) : min(len, start);
//       end = (end < 0) ? max(0, end + len) : min(len, end);
//       for (var i = start; i < end; i += step) trace("$i;$expr", val, path);
//     }
//   }

//   static eval(String x, dynamic _v, _vname) {
//     try {
//       return $ != null && _v != null && _v[x.replaceAll(r"@\.", "")] != null;
//     } catch (e) {
//       throw "jsonPath: $e: " + x.replaceAll("@", "_v").replaceAll(RegExp("\^"), "_a");
//     }
//   }
// }
