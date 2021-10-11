/*
 * @Author: your name
 * @Date: 2021-04-08 14:27:54
 * @LastEditTime: 2021-10-11 14:27:08
 * @LastEditors: Noah shan
 * @Description: In User Settings Edit
 * @FilePath: /iht_flutter_jsb/lib/webview/webviewintecept.dart
 */

import 'package:iht_flutter_jsb/webview/webviewjsb.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum WebViewInteceptType {
  // 认证
  oauth,
  // 手机号
  tel,
  // 短信
  sms,
  // 无需处理
  none,
  // 其他
  others,
  // jsb set up
  jsbsetup,
  // jsb msg request
  jsbmsgrequest
}

/// url拦截处理 ： 单点登录 * 手机号 等其他操作处理
class WebViewIntecept {
  String redirectStr = 'redirect_uri';

  WebViewInteceptType progressURLType(Uri url) {
    if (WebViewJSB.getInstance().isJSBSetupUrl(url)) {
      return WebViewInteceptType.jsbsetup;
    }
    if (WebViewJSB.getInstance().isJSBMsgReveive(url)) {
      return WebViewInteceptType.jsbmsgrequest;
    }
    String uriScheme = url.scheme.toLowerCase();
    switch (uriScheme) {
      case 'sms':
        return WebViewInteceptType.sms;
      case 'tel':
        return WebViewInteceptType.tel;
      default:
        return WebViewInteceptType.none;
    }
  }

  /// 单点登录处理[返回需要处理的request]
  Future<URLRequest?> progressOauth(Uri uri) async {}
}
