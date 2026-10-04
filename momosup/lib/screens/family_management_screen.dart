import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../state/app_state.dart';
import '../widgets/family_sharing_notice.dart';

class FamilyManagementScreen extends StatelessWidget {
  const FamilyManagementScreen({
    required this.appState,
    required this.profile,
    super.key,
  });
  final AppState appState;
  final ChildProfile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('기기별 프로필 안내')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: const SingleChildScrollView(child: FamilySharingNotice()),
        ),
      ),
    ),
  );
}
