import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;

  @override
  void initState() {
    super.initState();
    engine = OpenVPN(
      onVpnStatusChanged: (data) => setState(() => status = data),
      onVpnStageChanged: (data, raw) => setState(() => stage = data),
    );
    engine.initialize(
      groupIdentifier: "group.com.example.myVpnApp",
      providerBundleIdentifier: "com.example.myVpnApp.VPNExtension",
      localizedDescription: "My Flutter VPN",
    );
  }

  void toggleVPN() {
    if (stage == VPNStage.connected) {
      engine.disconnect();
    } else {
      // Sample VPN Config placeholder
      String config = ''; 
      engine.connect(config, "VPN Gate", username: "", password: "", certIsRequired: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('My Flutter VPN')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Status: ${stage?.toString().split('.').last ?? "Disconnected"}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: toggleVPN,
                child: Text(stage == VPNStage.connected ? 'Disconnect' : 'Connect VPN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
