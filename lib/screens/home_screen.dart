import 'package:flutter/material.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
        const HomeScreen({super.key});

        @override
        Widget build(BuildContext context) {
                return Scaffold(
                        appBar: AppBar(
                                title: const Text("🕌 Babas App"),
                                centerTitle: true,
                        ),
                        body: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                        Center(
                                                child: Column(
                                                        children: [
                                                                Image.asset(
                                                                        'assets/images/babas_logo.png',
                                                                        width: 120,
                                                                        height: 120,
                                                                        fit: BoxFit.contain,
                                                                ),
                                                                const SizedBox(height: 12),
                                                                Text(
                                                                        "Assalamu'alaikum",
                                                                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                const Text(
                                                                        "Babas App",
                                                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                        "Cahaya Al-Qur'an Dalam Genggaman",
                                                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                                                ),
                                                        ],
                                                ),
                                        ),
                                        const SizedBox(height: 20),

                                        menuTile(context, "📖 Al-Qur'an"),
                                        menuTile(context, "🕌 Jadwal Sholat"),
                                        menuTile(context, "🤲 Doa & Dzikir"),
                                        menuTile(context, "🎧 Murottal"),
                                        menuTile(context, "📅 Kalender Islami"),
                                        menuTile(context, "🌤 Cuaca"),
                                        menuTile(context, "📚 Kitab Maulid"),
                                        menuTile(context, "⭐ Premium"),
                                        menuTile(context, "⚙️ Pengaturan"),

                                        const SizedBox(height: 24),
                                        Column(
                                                children: const [
                                                        Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
                                                        SizedBox(height: 4),
                                                        Text("© Babas App", style: TextStyle(color: Colors.grey)),
                                                ],
                                        ),
                                ],
                        ),
                );
        }
}

Widget menuTile(BuildContext context, String title) {
        return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        title: Text(title),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                                if (title.contains("Al-Qur'an")) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QuranScreen()));
                                        return;
                                }
                                if (title.contains("Pengaturan")) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                        return;
                                }
                                // default: do nothing (preserve existing navigation behavior)
                        },
                ),
        );
}