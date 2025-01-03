// Dart Packages
import 'dart:async';

// Flutter Packages
import 'package:flutter/material.dart';
import 'package:network_monitor/network_monitor_package.dart';

// This Package

class ListenToStream extends StatefulWidget {
  const ListenToStream({super.key});

  @override
  State<ListenToStream> createState() => _ListenToStreamState();
}

class _ListenToStreamState extends State<ListenToStream> {
  ConnectionStatus? _connectionStatus;
  late StreamSubscription<ConnectionStatus> _subscription;
  final NetworkMonitor _networkMonitor = NetworkMonitor.createInstance();
  @override
  void initState() {
    super.initState();
    _subscription = _networkMonitor.onStatusChange.listen((status) {
      setState(() {
        print("Live status : $status");
        _connectionStatus = status;
      });
    });
  }

  @override
  void dispose() {
    _networkMonitor.disposeStatus();
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen to Stream'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                  onPressed: () async {
                    final data = _networkMonitor.isOnline;
                    final data2 = _networkMonitor.connectionType;
               
                    
                    // final data = await NetworkMonitor().hasInternetAccess;÷
                    // print("this is fucking baashaa... $data");
                  },
                  child: Text('Cancel')),
              const Text(
                'This example shows how to listen for the internet connection '
                'status using a StreamSubscription.\n\n'
                'Changes to the internet connection status are listened and '
                'reflected in this example.',
                textAlign: TextAlign.center,
              ),
              const Divider(
                height: 48.0,
                thickness: 2.0,
              ),
              const Text('Connection Status:'),
              _connectionStatus == null
                  ? const CircularProgressIndicator.adaptive()
                  : Text(
                      _connectionStatus.toString(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
