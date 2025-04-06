import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Blackspot extends StatefulWidget {
  const Blackspot({super.key});

  @override
  State<Blackspot> createState() => _BlackspotState();
}

class _BlackspotState extends State<Blackspot> {
  WebViewController? _controller;
  String username = "";
  String password = "";
  void getFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      username = prefs.getString('username')!;
      password = prefs.getString("password")!;
    });
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
            'https://irsms.korlantas.polri.go.id/blackspot-dashboard/$username'),
      );
  }

  @override
  void initState() {
    getFromSharedPreferences();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Black Spot'),
      ),
      body: Center(
        child: WebViewWidget(controller: _controller!),
        // child: TextButton(
        //   child: Text("Get"),
        //   onPressed: () {
        //     getFromSharedPreferences();
        //   },
        // ),
      ),
    );
  }
}
