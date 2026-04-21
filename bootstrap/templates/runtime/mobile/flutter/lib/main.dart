import 'package:flutter/material.dart';

void main() {
  runApp(const AiaastMobileApp());
}

class AiaastMobileApp extends StatelessWidget {
  const AiaastMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '__AIAST_APP_NAME__',
      home: const _HomePage(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C6D7A)),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('__AIAST_APP_NAME__')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Flutter mobile scaffold',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 12),
            Text(
              'Wire this surface to your API, local runtime service, or offline data layer.',
            ),
            SizedBox(height: 24),
            Card(
              child: ListTile(
                title: Text('Default package id'),
                subtitle: Text('__AIAST_PACKAGE_NAME__'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
