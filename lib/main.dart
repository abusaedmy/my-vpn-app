import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VPNHomeScreen(),
  ));
}

class VPNHomeScreen extends StatefulWidget {
  const VPNHomeScreen({super.key});

  @override
  State<VPNHomeScreen> createState() => _VPNHomeScreenState();
}

class _VPNHomeScreenState extends State<VPNHomeScreen> {
  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;
  bool isConnected = false;
  List<dynamic> servers = [];
  bool isLoading = true;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    engine = OpenVPN(
      onVpnStatusChanged: (s) => setState(() => status = s),
      onVpnStageChanged: (s, l) {
        setState(() {
          stage = s;
          isConnected = s == VPNStage.connected;
        });
      },
    );
    engine.initialize(
      groupIdentifier: "group.com.example.myvpnapp",
      providerBundleIdentifier: "com.example.myvpnapp.VPNExtension",
      localizedDescription: "My VPN Connection",
    );
    fetchVPNGateServers();
  }

  Future<void> fetchVPNGateServers() async {
    try {
      final response = await http.get(Uri.parse('https://www.vpngate.net/api/iphone/'));
      if (response.statusCode == 200) {
        List<String> lines = response.body.split('\n');
        List<dynamic> list = [];
        for (int i = 2; i < lines.length; i++) {
          List<String> data = lines[i].split(',');
          if (data.length > 14) {
            list.add({
              'country': data[5],
              'countryLong': data[6],
              'ip': data[1],
              'config': data[14],
            });
          }
        }
        setState(() {
          servers = list;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void toggleVPN() {
    if (isConnected) {
      engine.disconnect();
    } else {
      if (servers.isNotEmpty) {
        String configBase64 = servers[selectedIndex]['config'];
        String config = utf8.decode(base64.decode(configBase64));
        engine.connect(
          config,
          servers[selectedIndex]['countryLong'],
          username: '',
          password: '',
          certIsRequired: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text("My VPN", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2D2D44),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : Column(
              children: [
                const SizedBox(height: 30),
                Center(
                  child: GestureDetector(
                    onTap: toggleVPN,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? Colors.greenAccent : Colors.redAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? Colors.greenAccent : Colors.redAccent).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.power_settings_new,
                        size: 80,
                        color: isConnected ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  stage?.toString().split('.').last.toUpperCase() ?? "DISCONNECTED",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final server = servers[index];
                      final isSelected = index == selectedIndex;
                      return Card(
                        color: isSelected ? const Color(0xFF3D3D5C) : const Color(0xFF2D2D44),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.vpn_lock, color: Colors.cyanAccent),
                          title: Text(server['countryLong'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text("IP: ${server['ip']}", style: const TextStyle(color: Colors.grey)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.greenAccent) : null,
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
    );
  }
}
