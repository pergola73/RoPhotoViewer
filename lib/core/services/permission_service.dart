import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class PermissionService {
  static Future<void> checkAndRequestPermissions(BuildContext context) async {
    // 1. Media & Meldingen
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
        Permission.notification,
      ].request();
      
      // 2. Batterijbesparing negeren (Cruciaal voor 35.000 foto's)
      final bool isIgnoring = await FlutterForegroundTask.isIgnoringBatteryOptimizations;
      if (!isIgnoring) {
        if (context.mounted) {
          await _showBatteryOptimizationDialog(context);
        }
      }
    } else if (Platform.isIOS) {
      await [
        Permission.photos, 
        Permission.notification
      ].request();
    }
  }

  static Future<void> _showBatteryOptimizationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Achtergrond Synchronisatie'),
        content: const Text(
          'Om je volledige bibliotheek betrouwbaar te synchroniseren, '
          'moet de app op de achtergrond kunnen blijven werken.\n\n'
          'Kies in het volgende scherm voor "Toestaan" of "Niet optimaliseren".'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LATER'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Probeer direct de systeem-dialoog te triggeren
              try {
                await FlutterForegroundTask.requestIgnoreBatteryOptimization();
              } catch (e) {
                // Als dat faalt, open de app settings zodat de gebruiker het handmatig kan doen
                await openAppSettings();
              }
            },
            child: const Text('NU INSTELLEN'),
          ),
        ],
      ),
    );
  }
}
