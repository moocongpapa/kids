import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../widgets/family_sharing_notice.dart';

/// Legacy/deep-link entries show a notice without parsing or accepting payloads.
class FamilyInviteAcceptScreen extends StatelessWidget {
  const FamilyInviteAcceptScreen({
    required this.appState,
    this.initialCodeOrUrl,
    super.key,
  });
  final AppState appState;
  final String? initialCodeOrUrl;

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
