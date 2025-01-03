// Dart Packages
import 'dart:async';

// Flutter Packages
import 'package:flutter/material.dart';
import 'package:network_monitor/network_monitor_package.dart';

// This Package

class CustomURIs extends StatefulWidget {
  const CustomURIs({super.key});

  @override
  State<CustomURIs> createState() => _CustomURIsState();
}

class _CustomURIsState extends State<CustomURIs> {
  late StreamSubscription<double> _subscription;
  final NetworkMonitor _networkMonitor = NetworkMonitor.createInstance(
    networkSpeedEnabled: true,
    useDefaultOptions: true,
    networkSpeedInterval: const Duration(seconds: 1),
  );
  @override
  void initState() {
    super.initState();
    _subscription = _networkMonitor.onChange.listen((status) {
      setState(() {
        print("Live speed : $status");
      });
    });
  }

  @override
  void dispose() {
    _networkMonitor.disposeSpeed();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom URIs'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    //  _networkMonitor.disposeSpeed();
                    _subscription.cancel();
                  },
                  child: Text("Test")),
              const Text(
                'This example shows how to use custom URIs to check the internet '
                'connection status.',
                textAlign: TextAlign.center,
              ),
              const Divider(
                height: 48.0,
                thickness: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
