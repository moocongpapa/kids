import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/family_share.dart';
import '../models/parent_account.dart';
import 'family_sharing_notice.dart';

/// Kept for older call sites, but never renders or exports legacy invite payloads.
class KakaoShareModal extends StatelessWidget {
  const KakaoShareModal({
    required this.profile,
    required this.payload,
    this.parentAccount,
    super.key,
  });
  final ChildProfile profile;
  final FamilyInvitePayload payload;
  final ParentAccount? parentAccount;

  static Future<void> show(
    BuildContext context, {
    required ChildProfile profile,
    required FamilyInvitePayload payload,
    ParentAccount? parentAccount,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFFDF5),
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        child: KakaoShareModal(
          profile: profile,
          payload: payload,
          parentAccount: parentAccount,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => const FamilySharingNotice();
}
