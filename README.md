# network_monitor

# Network Monitor Plugin

A Flutter plugin that provides real-time network information, including:

- **Connection Type**: Determines whether the device is connected via WiFi, Cellular, Ethernet, or other types.
- **Internet Availability**: Checks if the connected network has internet access.
- **Real-Time Network Speed**: Measures the current network speed.
- **Network Quality**: Assesses the quality of the connected network.

## Features

1. **Connection Type**: Identify the current type of network connection (WiFi, Cellular, Ethernet, etc.).
2. **Internet Availability**: Verify whether the connected network has internet access.
3. **Real-Time Network Speed**: Get the real-time network speed in Mbps.
4. **Network Quality**: Evaluate the quality of the network connection based on latency and packet loss.

## Getting Started

Add this plugin to your `pubspec.yaml`:

```yaml
dependencies:
  network_monitor: ^1.0.0
```

Then, run:

```bash
flutter pub get
```

## Usage

Import the package:

```dart
import 'package:network_monitor/network_monitor.dart';
```

### Example

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitor_example/connectivity_helper.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
      debugShowCheckedModeBanner: false,
      home: const NetworkMonitorWidget(),
    );
  }
}

class NetworkMonitorWidget extends ConsumerWidget {
  const NetworkMonitorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final network = ref.watch(globalNetworkStatusProvider);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: network.hasInternet ? Colors.green : Colors.red,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                network.hasInternet ? 'Online' : 'Offline',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
              // SizedBox(width: 8),
              NetworkStrengthIcon(speedMbps: network.speedMbps),
            ],
          ),
        ),
        body: const Center(
          child: NetworkStatusList(),
        ));
  }
}

class NetworkStatusList extends ConsumerWidget {
  const NetworkStatusList({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final network = ref.watch(globalNetworkStatusProvider);

    TextStyle style = TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue[900]!);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ListTile(
          title: const Text('Connection Type'),
          subtitle: Text(
            network.connectionType.toString(),
            style: style,
          ),
        ),
        const Divider(
          thickness: 3,
        ),
        ListTile(
          title: const Text('Internet Access'),
          subtitle: Text(
            network.hasInternet ? 'Yes' : 'No',
            style: style,
          ),
        ),
        const Divider(
          thickness: 3,
        ),
        ListTile(
          title: const Text('Network Speed'),
          subtitle: Text(
            '${network.speedMbps.toStringAsFixed(2)} Mbps',
            style: style,
          ),
        ),
        const Divider(
          thickness: 3,
        ),
        ListTile(
          title: const Text('Network Quality'),
          subtitle: Text(
            network.quality.toString(),
            style: style,
          ),
        ),
        const Divider(
          thickness: 3,
        ),
        const SizedBox(
          height: 20,
        ),
        ElevatedButton(
          onPressed: () {
            if (kDebugMode) {
              print("Internet irukkaa?? ${network.hasInternet}");
            }
          },
          child: const Text('Check Network'),
        ),
      
      ],
    );
  }
}

class NetworkStrengthIcon extends StatelessWidget {
  final double speedMbps;

  const NetworkStrengthIcon({super.key, required this.speedMbps});

  @override
  Widget build(BuildContext context) {
    int filledBars = 0;

    if (speedMbps > 15) {
      return Icon(
        Icons.signal_cellular_alt_outlined,
        color: Colors.red[900],
        size: 40,
      );
    } else if (speedMbps > 10) {
      return Icon(
        Icons.signal_cellular_alt_outlined,
        color: Colors.red[900],
        size: 40,
      );
    } else if (speedMbps > 5) {
      return Icon(
        Icons.signal_cellular_alt_2_bar,
        color: Colors.red[900],
        size: 40,
      );
    } else if (speedMbps == 0) {
      return Icon(
        Icons.signal_cellular_connected_no_internet_0_bar_sharp,
        color: Colors.blue[900],
        size: 40,
      );
    }
    return const Placeholder();
  }
}

```

## API

### Methods

#### `getConnectionType()`
- **Description**: Returns the type of network connection (WiFi, Cellular, Ethernet, etc.).
- **Return Type**: `Future<String>`

#### `hasInternet()`
- **Description**: Checks if the connected network has internet access.
- **Return Type**: `Future<bool>`

#### `getNetworkSpeed()`
- **Description**: Measures the current network speed in Mbps.
- **Return Type**: `Future<double>`

#### `getNetworkQuality()`
- **Description**: Evaluates the network quality based on latency and packet loss.
- **Return Type**: `Future<String>`

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributions

Contributions are welcome! Feel free to open an issue or submit a pull request.

## Support

If you encounter any issues, please open a GitHub issue or contact the maintainer.

