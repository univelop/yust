import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  static const String routeName = '/splash';
  static const bool signInRequired = false;

  SplashScreen({Key? key, this.appName}) : super(key: key);

  final String? appName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appName ?? '')),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
