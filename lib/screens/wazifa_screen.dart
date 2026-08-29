import 'package:flutter/material.dart';

import 'islamic_screen.dart';

class WazifaScreen extends StatelessWidget {
  const WazifaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _WazifaHeader(),
            Expanded(child: WazifaPage()),
          ],
        ),
      ),
    );
  }
}

class _WazifaHeader extends StatelessWidget {
  const _WazifaHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Wazifa',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Aml-e-Dua for every day of the year',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}