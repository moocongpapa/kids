import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/activity.dart';
import '../../models/child_profile.dart';
import '../../state/app_state.dart';
import '../../widgets/avatar_image.dart';
import '../play_screen.dart';
import 'parent_common_widgets.dart';

class PreviewCatalogScreen extends StatelessWidget {
  const PreviewCatalogScreen({
    required this.appState,
    required this.profile,
    required this.catalog,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;
  final List<Activity> catalog;

  @override
  Widget build(BuildContext context) {
    final items = catalog
        .where((activity) => activity.supportsAge(profile.ageMonths))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('콘텐츠 검토·미리보기')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const ParentNoticeCard(text: '검수와 사용권 확인이 기록된 놀이만 아이 화면에 나타납니다.'),
            const SizedBox(height: 12),
            for (final activity in items)
              ParentRow(
                child: ListTile(
                  leading: AvatarImage(avatar: activity.avatar, size: 54),
                  title: Text(activity.title),
                  subtitle: Text(
                    '${activity.theme} · ${activity.modeLabel} · '
                    '${activity.isFullyApproved ? '검수 완료' : '검수 대기'}',
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ContentDetailScreen(
                        appState: appState,
                        profile: profile,
                        activity: activity,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ContentDetailScreen extends StatelessWidget {
  const ContentDetailScreen({
    required this.appState,
    required this.profile,
    required this.activity,
    super.key,
  });

  final AppState appState;
  final ChildProfile profile;
  final Activity activity;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(activity.title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          AvatarImage(avatar: activity.avatar, size: 148),
          const SizedBox(height: 8),
          Text(
            '${activity.theme} · ${activity.modeLabel} · 약 ${activity.minutes}분',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text('시작 대본', style: Theme.of(context).textTheme.titleMedium),
          Text(activity.intro),
          const SizedBox(height: 12),
          Text('아이 행동', style: Theme.of(context).textTheme.titleMedium),
          Text(activity.prompt),
          if (activity.choices.isNotEmpty) Text(activity.choices.join(' / ')),
          if (activity.verses.isNotEmpty) Text(activity.verses.join('\n')),
          const SizedBox(height: 12),
          Text('마무리', style: Theme.of(context).textTheme.titleMedium),
          Text('${activity.outro}\n화면 밖: ${activity.offscreen}'),
          const SizedBox(height: 12),
          Text('안전 점검', style: Theme.of(context).textTheme.titleMedium),
          ...activity.safety.map((note) => Text('• $note')),
          const SizedBox(height: 16),
          const ParentNoticeCard(
            text: '조작 미리보기에서 안내 음성과 반응 소리를 함께 확인할 수 있어요. 아이 이용시간에는 기록되지 않습니다.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlayScreen(
                  activity: activity,
                  appState: appState,
                  profile: profile,
                  isParentPreview: true,
                ),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('보호자 조작 미리보기'),
          ),
        ],
      ),
    ),
  );
}

class ParentGalleryScreen extends StatefulWidget {
  const ParentGalleryScreen({required this.profile, super.key});

  final ChildProfile profile;

  @override
  State<ParentGalleryScreen> createState() => _ParentGalleryScreenState();
}

class _ParentGalleryScreenState extends State<ParentGalleryScreen> {
  late Future<List<File>> drawings = loadDrawings();

  Future<List<File>> loadDrawings() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/momosup_drawings');
    if (!await directory.exists()) return [];
    final files = await directory
        .list(followLinks: false)
        .where(
          (entry) =>
              entry is File &&
              entry.uri.pathSegments.last.startsWith('${widget.profile.id}_') &&
              entry.path.endsWith('.png'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<void> deleteDrawing(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('이 그림을 삭제할까요?'),
        content: const Text('이 기기에서 영구적으로 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await file.delete();
      if (mounted) setState(() => drawings = loadDrawings());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('그림을 삭제하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.profile.nickname}의 그림')),
    body: SafeArea(
      child: FutureBuilder<List<File>>(
        future: drawings,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('그림을 불러오지 못했어요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final files = snapshot.data!;
          if (files.isEmpty) {
            return const Center(child: Text('아직 이 기기에 저장된 그림이 없어요.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 280,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .82,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) => Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Image.file(
                      files[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),
                  IconButton(
                    tooltip: '그림 삭제',
                    onPressed: () => deleteDrawing(files[index]),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
