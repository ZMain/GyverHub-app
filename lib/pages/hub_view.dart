import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class HubView extends StatefulWidget {
  const HubView({super.key});

  @override
  State<HubView> createState() => _HubViewState();
}

class _HubViewState extends State<HubView> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  @override
  void initState() {
    super.initState();
    // getComputedStyle(document.documentElement).getPropertyValue('--prim');
  }

  DateTime? currentBackPressTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // final canGoBack = await webViewController?.canGoBack() ?? false;
        final status = await webViewController?.evaluateJavascript(
          source: "document.querySelector(`#back`).style.display;",
        );

        if (status != 'none') {
          await webViewController?.goBack();
          return false;
        }

        DateTime now = DateTime.now();
        if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
          currentBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Click again to exit"),
          ));
          return false;
        }
        exit(0);
        return true;
      },
      child: Scaffold(
        extendBody: false,
        extendBodyBehindAppBar: false,
        body: Column(
          children: [
            Expanded(
              child: SafeArea(
                child: InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: WebUri('http://localhost:9090/')),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    alwaysBounceHorizontal: false,
                    horizontalScrollBarEnabled: false,
                  ),
                  onReceivedServerTrustAuthRequest: (controller, challenge) async {
                    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    var uri = navigationAction.request.url!;
                    if (uri.host != 'localhost') {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                  onWebViewCreated: (controller) async {
                    webViewController = controller;
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
