import 'package:flutter/material.dart';

class SubjectInfoScreen extends StatelessWidget {
  const SubjectInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('科目情報'),
      ),
      body: const Center(
        child: Text('科目情報画面'),
      ),
    );
  }
}