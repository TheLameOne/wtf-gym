import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class DevPanelOverlay extends StatelessWidget {
  const DevPanelOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevPanel(appName: 'WTF Guru');
  }
}
