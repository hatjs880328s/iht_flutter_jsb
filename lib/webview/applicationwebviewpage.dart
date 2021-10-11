/*
  * @Author: your name
  * @Date: 2021-03-27 14:20:47
 * @LastEditTime: 2021-10-11 14:31:31
 * @LastEditors: Noah shan
* @Description: In User Settings Edit
 * @FilePath: /iht_flutter_jsb/lib/webview/applicationwebviewpage.dart
 */

import 'package:iht_flutter_jsb/webview/webviewintecept.dart';
import 'package:iht_flutter_jsb/webview/webviewjsb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

///
/// 整体文档:
/// https://inappwebview.dev/docs/in-app-webview/basic-usage/
/// js injection:
/// https://inappwebview.dev/docs/javascript/injection/
/// webviewjavascript kit : 需要根据之前开源项目做特定处理
/// https://github.com/marcuswestin/WebViewJavascriptBridge
/// 原来的ios & android中jsb开源版本的流程说明：
///
/// 第一步：
/// 拦截url做判定是否满足条件
/// #define kOldProtocolScheme @"wvjbscheme"
/// #define kNewProtocolScheme @"https"
/// #define kQueueHasMessage   @"__wvjb_queue_message__"
/// #define kBridgeLoaded      @"__bridge_loaded__"
/// [scheme isEqualToString:kNewProtocolScheme] ||
/// [scheme isEqualToString:kOldProtocolScheme];
/// [self isSchemeMatch:url] && [host isEqualToString:kBridgeLoaded];
///
/// 第二步：
/// 注入js脚本， 在第一步完成后，识别出需要注入后，就注入
///
/// 第三步：
/// 拦截所有用户操作、url的delegate函数中，识别
/// https://__wvjb_queue_message__/
/// 识别出来之后就使用webview调用js代码：
/// WebViewJavascriptBridge._fetchQueue();
/// 返回值就是挂在到window上面函数的序列化 eg.
/// [{"handlerName":"bridgeToNative",
/// "data":"{\"reqid\":\"\",\"type\":\"ccworkGetUserInfo\"}","callbackId":"cb_3_1617873438225"}]
///
/// 第四步：
/// 接受到第三部中数据后，根据data进行数据处理，处理完毕后，通过callbackid和指定的回调函数执行js代码即可
/// WebViewJavascriptBridge._handleMessageFromObjC('{"responseId":"CALLBACKID",
/// "responseData":"Response from FlutterHtime"}');

// ignore: must_be_immutable
class ApplicationWebviewPage extends StatelessWidget {
  String model;

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          userAgent:
              'Mozilla/5.0 (iPhone; CPU iPhone OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148/emmcloud/3.7.4/isInImp lang/zh-Hans/ccwork',
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false),
      android: AndroidInAppWebViewOptions(useHybridComposition: true),
      ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true));

  late InAppWebViewController con;

  ApplicationWebviewPage(this.model, {Key? key}) : super(key: key) {
    //jsb register
    WebViewJSB.getInstance().registerJSBHandler((h52NativeInfo) async {
      await Future.delayed(const Duration(milliseconds: 1000), () {
        // TODO: your own biz code...
      });
      return 'halo,world iht_flutter_jsb';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("TITLE")),
      body: InAppWebView(
        // initialFile: "lib/lib/webview/ExampleApp.html",
        initialUrlRequest: URLRequest(url: Uri.parse(model)),
        initialOptions: options,
        onLoadStart: (con, url) {
          EasyLoading.show();
        },
        androidOnPermissionRequest: (con, origin, resource) async {
          return PermissionRequestResponse(
            resources: resource,
            action: PermissionRequestResponseAction.GRANT,
          );
        },
        // 单点登录拦截处理
        shouldOverrideUrlLoading: (con, navigationAction) async {
          var uri = navigationAction.request.url;
          if (uri == null) {
            return NavigationActionPolicy.ALLOW;
          }
          WebViewInteceptType type = WebViewIntecept().progressURLType(uri);
          switch (type) {
            case WebViewInteceptType.none:
              return NavigationActionPolicy.ALLOW;
            case WebViewInteceptType.oauth:
              URLRequest? newRequest =
                  await WebViewIntecept().progressOauth(uri);
              if (newRequest != null) {
                await con.loadUrl(urlRequest: newRequest);
                return NavigationActionPolicy.CANCEL;
              } else {
                return NavigationActionPolicy.ALLOW;
              }
            case WebViewInteceptType.sms:
              return NavigationActionPolicy.ALLOW;
            case WebViewInteceptType.jsbsetup:
              await WebViewJSB.getInstance().jsInjection(con);
              return NavigationActionPolicy.CANCEL;
            case WebViewInteceptType.jsbmsgrequest:
              await WebViewJSB.getInstance()
                  .evaluateJS(con, WebViewJSB.jsExecute);
              return NavigationActionPolicy.CANCEL;
            default:
              return NavigationActionPolicy.ALLOW;
          }
        },
        onLoadStop: (con, url) {
          EasyLoading.dismiss();
        },
        onLoadError: (con, url, code, message) {
          EasyLoading.dismiss();
        },
        onProgressChanged: (con, progress) {},
      ),
    );
  }
}
