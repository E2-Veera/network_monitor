import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitor_example/connectivity_helper.dart';
import 'package:network_monitor_example/listen_once.dart';
import 'package:network_monitor_example/listen_stream.dart';
import 'package:network_monitor_example/speed.dart';

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
      home: const CustomURIs(),
    );
  }
}

// class NetworkMonitorWidget extends ConsumerWidget {
//   const NetworkMonitorWidget({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // final network = ref.watch(globalNetworkStatusProvider);

//     return Scaffold(
//         appBar: AppBar(
//           backgroundColor: network.hasInternet ? Colors.green : Colors.red,
//           title: Row(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 network.hasInternet ? 'Online' : 'Offline',
//                 style: const TextStyle(
//                   fontSize: 25,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.black,
//                 ),
//               ),
//               // SizedBox(width: 8),
//               NetworkStrengthIcon(speedMbps: network.speedMbps),
//             ],
//           ),
//         ),
//         body: const Center(
//           child: NetworkStatusList(),
//         ));
//   }
// }

// class NetworkStatusList extends ConsumerWidget {
//   const NetworkStatusList({super.key});

//   @override
//   Widget build(BuildContext context, ref) {
//     final network = ref.watch(globalNetworkStatusProvider);

//     TextStyle style = TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue[900]!);

//     return ListView(
//       padding: const EdgeInsets.all(16.0),
//       children: [
//         ListTile(
//           title: const Text('Connection Type'),
//           subtitle: Text(
//             network.connectionType.toString(),
//             style: style,
//           ),
//         ),
//         const Divider(
//           thickness: 3,
//         ),
//         ListTile(
//           title: const Text('Internet Access'),
//           subtitle: Text(
//             network.hasInternet ? 'Yes' : 'No',
//             style: style,
//           ),
//         ),
//         const Divider(
//           thickness: 3,
//         ),
//         ListTile(
//           title: const Text('Network Speed'),
//           subtitle: Text(
//             '${network.speedMbps.toStringAsFixed(2)} Mbps',
//             style: style,
//           ),
//         ),
//         const Divider(
//           thickness: 3,
//         ),
//         ListTile(
//           title: const Text('Network Quality'),
//           subtitle: Text(
//             network.quality.toString(),
//             style: style,
//           ),
//         ),
//         const Divider(
//           thickness: 3,
//         ),
//         const SizedBox(
//           height: 20,
//         ),
//         ElevatedButton(
//           onPressed: () {
//             if (kDebugMode) {
//               print("Internet irukkaa?? ${network.hasInternet}");
//             }
//           },
//           child: const Text('Check Network'),
//         ),
      
//       ],
//     );
//   }
// }

// class NetworkStrengthIcon extends StatelessWidget {
//   final double speedMbps;

//   const NetworkStrengthIcon({super.key, required this.speedMbps});

//   @override
//   Widget build(BuildContext context) {
//     int filledBars = 0;

//     if (speedMbps > 15) {
//       return Icon(
//         Icons.signal_cellular_alt_outlined,
//         color: Colors.red[900],
//         size: 40,
//       );
//     } else if (speedMbps > 10) {
//       return Icon(
//         Icons.signal_cellular_alt_outlined,
//         color: Colors.red[900],
//         size: 40,
//       );
//     } else if (speedMbps > 5) {
//       return Icon(
//         Icons.signal_cellular_alt_2_bar,
//         color: Colors.red[900],
//         size: 40,
//       );
//     } else if (speedMbps == 0) {
//       return Icon(
//         Icons.signal_cellular_connected_no_internet_0_bar_sharp,
//         color: Colors.blue[900],
//         size: 40,
//       );
//     }
//     return  Container();
//   }
// }
