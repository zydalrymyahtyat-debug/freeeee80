import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _exportDatabase(BuildContext context) async {
    try {
      String dbPath = join(await getDatabasesPath(), 'smart_pos.db');
      File dbFile = File(dbPath);

      if (await dbFile.exists()) {
        final xFile = XFile(dbPath);
        await Share.shareXFiles([xFile], text: 'نسخة احتياطية لقاعدة بيانات نقاط البيع الذكية');
      } else {
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قاعدة البيانات غير موجودة!')));
        }
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النسخ الاحتياطي')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.backup, size: 100, color: Colors.blue),
              const SizedBox(height: 16),
              const Text('يمكنك تصدير قاعدة البيانات الخاصة بك وحفظها في مكان آمن للرجوع إليها لاحقاً.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('تصدير قاعدة البيانات', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                onPressed: () => _exportDatabase(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
