/*
 * @Author: your name
 * @Date: 2021-04-08 16:37:31
 * @LastEditTime: 2021-10-11 14:22:51
 * @LastEditors: Noah shan
 * @Description: In User Settings Edit
 * @FilePath: /iht_flutter_jsb/lib/webview/webviewjsb.dart
 */

import 'package:iht_flutter_jsb/webview/webviewinectionjs.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert';

class WebViewJSB {
  String callBackJS = """
  WebViewJavascriptBridge._handleMessageFromObjC('{"responseId":"CALLBACKID","responseData":"RESPONSEINFO"}');
  """;

  String initBridge2Web = """
  window.bridgeToWebHandle('OBJJSON')
  """;

  String kOldProtocolScheme = 'wvjbscheme';

  String kNewProtocolScheme = 'https';

  String kQueueHasMessage = '__wvjb_queue_message__';

  String kBridgeLoaded = '__bridge_loaded__';

  static String jsExecute = 'WebViewJavascriptBridge._fetchQueue();';

  late Function handler;

  /// shareinstance
  WebViewJSB._privateConstructor();
  static WebViewJSB? instance;
  static WebViewJSB getInstance() {
    instance ??= WebViewJSB._privateConstructor();

    return instance!;
  }

  /// 注册handler
  void registerJSBHandler(Function handler) {
    this.handler = handler;
  }

  /// 判断uri是否是jsb setup 的uri
  bool isJSBSetupUrl(Uri uri) {
    String scheme = uri.scheme;
    String host = uri.host;
    /**
     [scheme isEqualToString:kNewProtocolScheme] ||
      [scheme isEqualToString:kOldProtocolScheme];
      [self isSchemeMatch:url] && [host isEqualToString:kBridgeLoaded]; 
     */

    if ((scheme == kNewProtocolScheme || scheme == kOldProtocolScheme) &&
        host == kBridgeLoaded) {
      return true;
    } else {
      return false;
    }
  }

  /// 判断uri是否是jsb 通信请求
  bool isJSBMsgReveive(Uri uri) {
    String scheme = uri.scheme;
    String host = uri.host;
    if (scheme == kNewProtocolScheme && host == kQueueHasMessage) {
      return true;
    }
    return false;
  }

  /// js注入
  Future<bool> jsInjection(InAppWebViewController controller) async {
    var result =
        await controller.evaluateJavascript(source: WebViewInjectionJS.jsbStr);
    return result;
  }

  /// 执行js代码
  Future<dynamic> evaluateJS(
      InAppWebViewController controller, String js) async {
    var result = await controller.evaluateJavascript(source: js);
    List<dynamic> jsonObj = json.decode(result);
    await jsbInvoke(jsonObj, controller);
    return true;
  }

  /// jsb插件传输数据解析与处理
  Future<void> jsbInvoke(
      List<dynamic> list, InAppWebViewController controller) async {
    if (list.isEmpty) {
      // 初始化我们自己的jsb 业务代码
      await initJSBHandle(controller);
      return;
    }
    for (dynamic item in list) {
      if (item is Map<String, dynamic>) {
        String backId = item['callbackId'];
        String nativeExecuteResult = await handler(item);
        await responseCallBack(controller, backId, nativeExecuteResult);
      } else {
        // dothing...
      }
    }
  }

  /// 检测到需要调用某个jsb插件后，之后执行的js代码通知h5页面
  Future<void> responseCallBack(InAppWebViewController controller,
      String callbackId, String executeResult) async {
    String realJS = callBackJS
        .replaceAll('CALLBACKID', callbackId)
        .replaceAll('RESPONSEINFO', executeResult);
    await controller.evaluateJavascript(source: realJS);
  }

  /// 注入完脚本后，初始化htime jsb
  Future<void> initJSBHandle(InAppWebViewController controller) async {
    // var normalObj = {
    //   'version': '3.7.4',
    //   'token': MainThreadModel.getIntance().loginInfo?.token,
    //   'OrganId': MainThreadModel.getIntance().loginInfo?.organ?.first.org_id,
    //   'state': '2',
    //   'platformCode': 'icityapp',
    //   'moduleCode': 'other',
    //   'contentCode': 'h5_jsbridge',
    //   'contentName': 'Jsbridge测试页',
    //   'contentId': '371573',
    //   'organCode': 'inspur',
    //   'build': '1',
    //   'userCorpOrganId': ''
    // };

    // Map<String, dynamic> obj = {
    //   'type': 'common',
    //   'reqid': '',
    //   'data': normalObj
    // };

    // String realJS =
    //     initBridge2Web.replaceAll('OBJJSON', JSONUti.json2String(obj));
    // var result = await controller.evaluateJavascript(source: realJS);
    // print('jsb init result: ');
    // print(result);
  }
}
