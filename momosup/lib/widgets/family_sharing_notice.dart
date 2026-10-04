import 'package:flutter/material.dart';

/// External invitations stay unavailable until server-authenticated sharing exists.
class FamilySharingNotice extends StatelessWidget {
  const FamilySharingNotice({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.phonelink_lock_rounded,
          size: 42,
          color: Color(0xFF35604C),
        ),
        const SizedBox(height: 18),
        const Text(
          '지금은 이 기기에서 함께해요',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF284E3D),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '아이 프로필·그림·이용 기록은 이 기기에 보관해요. 가족 기기와 기록이나 시간 제한을 동기화하지 않아요.',
          style: TextStyle(height: 1.6),
        ),
        const SizedBox(height: 12),
        const Text(
          '가족 공유는 준비 중이에요. 아이 정보를 보호하기 위해 지금은 초대 링크를 보내거나 등록할 수 없어요.',
          style: TextStyle(height: 1.6),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('확인'),
          ),
        ),
      ],
    ),
  );
}
