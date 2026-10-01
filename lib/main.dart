import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:openvpn_flutter/openvpn_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const VpnScreen(),
    );
  }
}

class VpnServer {
  final String countryLong;
  final String countryShort;
  final String ip;
  final String configBase64;

  VpnServer({
    required this.countryLong,
    required this.countryShort,
    required this.ip,
    required this.configBase64,
  });

  String get ovpnConfig {
    try {
      return utf8.decode(base64.decode(configBase64.trim()));
    } catch (e) {
      return '';
    }
  }
}

class VpnScreen extends StatefulWidget {
  const VpnScreen({super.key});

  @override
  State<VpnScreen> createState() => _VpnScreenState();
}

class _VpnScreenState extends State<VpnScreen> {
  late OpenVPN engine;
  VPNStage? stage;
  List<VpnServer> serverList = [];
  VpnServer? selectedServer;
  bool isLoadingList = false;

  @override
  void initState() {
    super.initState();
    initVpn();
    fetchServers();
  }

  void initVpn() {
    engine = OpenVPN();
    engine.initialize(
      groupIdentifier: "group.com.myvpn.app",
      providerBundleIdentifier: "id.flutter.openvpn.myvpn",
      localizedDescription: "My VPN App",
      onVpnStageChanged: (s, message) {
        setState(() {
          stage = s;
        });
      },
      onVpnStatusChanged: (data) {},
    );
  }

  Future<void> fetchServers() async {
    setState(() {
      isLoadingList = true;
    });
    try {
      final response = await http.get(Uri.parse('https://www.vpngate.net/api/iphone/'));
      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        List<VpnServer> list = [];
        for (var line in lines) {
          if (line.startsWith('*') || line.startsWith('#') || line.trim().isEmpty) continue;
          final parts = line.split(',');
          if (parts.length >= 15) {
            final countryLong = parts[5];
            final countryShort = parts[6];
            final ip = parts[1];
            final base64Config = parts[14];
            if (base64Config.isNotEmpty && base64Config.length > 50) {
              list.add(VpnServer(
                countryLong: countryLong,
                countryShort: countryShort,
                ip: ip,
                configBase64: base64Config,
              ));
            }
          }
        }
        setState(() {
          serverList = list;
          if (list.isNotEmpty) {
            selectedServer = list.first;
          }
        });
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() {
        isLoadingList = false;
      });
    }
  }

  void toggleVpn() {
    if (selectedServer == null) return;
    if (stage == VPNStage.connected) {
      engine.disconnect();
    } else {
      final config = selectedServer!.ovpnConfig;
      if (config.isNotEmpty) {
        engine.connect(
          config,
          selectedServer!.countryLong,
          username: '',
          password: '',
          bypassConfig: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Multi-Country VPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchServers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.grey[900],
              child: ListTile(
                title: Text(
                  'Status: ${stage?.name.toUpperCase() ?? "DISCONNECTED"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(selectedServer != null
                    ? 'Selected: ${selectedServer!.countryLong} (${selectedServer!.ip})'
                    : 'No Server Selected'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: stage == VPNStage.connected ? Colors.red : Colors.green,
                  ),
                  onPressed: toggleVpn,
                  child: Text(
                    stage == VPNStage.connected ? 'Disconnect' : 'Connect',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Available Live Country Servers:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoadingList
                  ? const Center(child: CircularProgressIndicator())
                  : serverList.isEmpty
                      ? const Center(child: Text('Click top-right refresh icon.'))
                      : ListView.builder(
                          itemCount: serverList.length,
                          itemBuilder: (context, index) {
                            final server = serverList[index];
                            final isSelected = selectedServer == server;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(server.countryShort),
                              ),
                              title: Text(server.countryLong),
                              subtitle: Text('IP: ${server.ip}'),
                              selected: isSelected,
                              selectedTileColor: Colors.blue.withOpacity(0.2),
                              onTap: () {
                                setState(() {
                                  selectedServer = server;
                                });
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
