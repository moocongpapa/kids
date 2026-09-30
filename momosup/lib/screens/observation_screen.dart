import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/play_catalog.dart';
import '../models/activity.dart';
import '../models/child_profile.dart';
import '../models/play_observation.dart';
import '../state/app_state.dart';
import '../widgets/forest_game_ui.dart';

class ObservationScreen extends StatefulWidget {
  const ObservationScreen({
    required this.state,
    required this.profile,
    required this.catalog,
    super.key,
  });
  final AppState state;
  final ChildProfile profile;
  final List<Activity> catalog;
  @override
  State<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends State<ObservationScreen> {
  PlayRecord? record;
  String? activityId;
  int? start, help, enjoyment, ending, offscreen;
  String device = 'iPhone';
  Set<String> issues = {};
  bool saving = false;
  String? error;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.state,
    builder: (context, _) {
      final rows = widget.state.observations
          .where((o) => o.profileId == widget.profile.id)
          .toList();
      final entries = playCatalog(widget.state, widget.catalog);
      final names = {
        for (final e in entries) e.id: e.title,
        for (final a in widget.state.journeys.where((a) => a.isCaregiver))
          a.id: a.title,
      };
      final records = widget.state.records
          .where((r) => r.profileId == widget.profile.id)
          .toList()
          .reversed
          .take(20)
          .toList();
      final eligible = widget.profile.caregiverMode
          ? widget.state.journeys
                .where(
                  (a) => a.supports(widget.profile.ageMonths, preschool: true),
                )
                .map((a) => a.id)
                .toList()
          : availablePlay(
              widget.state,
              widget.catalog,
              widget.profile,
            ).map((e) => e.id).toList();
      return Scaffold(
        appBar: AppBar(title: const Text('가족 놀이 관찰')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  '실제 가족과 놀아본 뒤에만 기록해 주세요.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '보호자가 곁에 머물고, 아이가 거부하거나 불편해하면 바로 멈춰요. 이름·사진·영상·목소리는 기록하지 않아요. 24개월 미만은 보호자와 화면 밖에서 놀아요.',
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('관찰 순서·준비물'),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '① 실제 휴대폰에서 소리·오프라인·전화 후 이어하기 확인\n② 보호자가 관찰에 동의하고 놀이 1개 선택\n③ 첫 조작까지 10초 정도 기다리기\n④ 필요할 때만 도움, 아이의 거부 존중\n⑤ 쉼 화면에서 종료하고 화면 밖 놀이 제안\n⑥ 아래에 본 행동만 기록하기\n\n6~23개월은 휴대폰을 내려놓은 보호자 놀이의 반응만 관찰합니다.',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Text(
                  '관찰 ${rows.length}건',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(observationSuggestion(rows)),
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '혼자 시작 ${rows.where((o) => o.start == 0).length} / ${rows.length}건 · 편안한 종료 ${rows.where((o) => o.ending == 0).length} / ${rows.length}건',
                  ),
                  for (final issue in observationIssues)
                    if (rows.any((o) => o.issues.contains(issue)))
                      Text(
                        '$issue: ${rows.where((o) => o.issues.contains(issue)).length}건',
                      ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final report = const JsonEncoder.withIndent('  ')
                          .convert({
                            'kind': 'caregiver_observations',
                            'notice': 'Actual observations only; small sample, no learning-effect claim.',
                            'count': rows.length,
                            'observations': rows
                                .map((o) => o.anonymousSummaryRow())
                                .toList(),
                          });
                      await Clipboard.setData(ClipboardData(text: report));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '이름·프로필 ID·정확한 월령·시각을 제외한 요약을 복사했어요.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('식별정보 없는 요약 복사'),
                  ),
                ],
                const Divider(height: 32),
                Text('새 관찰 기록', style: Theme.of(context).textTheme.titleLarge),
                DropdownButtonFormField<String>(
              isExpanded: true,
                  initialValue: activityId,
                  decoration: const InputDecoration(labelText: '실제로 함께한 놀이'),
                  items: [
                    for (final id in eligible)
                      DropdownMenuItem(value: id, child: Text(names[id] ?? id)),
                  ],
                  onChanged: (id) => setState(() {
                    activityId = id;
                    record = records
                        .where((r) => r.activityId == id)
                        .firstOrNull;
                  }),
                ),
                if (record != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '최근 놀이: ${record!.at.month}/${record!.at.day} ${record!.at.hour}:${record!.at.minute.toString().padLeft(2, '0')} · 실제 이용 ${record!.seconds}초\n앱을 벗어난 횟수 ${record!.metrics['interruptions'] ?? 0}회',
                    ),
                  ),
                DropdownButtonFormField<String>(
              isExpanded: true,
                  initialValue: device,
                  decoration: const InputDecoration(labelText: '사용한 기기'),
                  items: [
                    for (final d in ['iPhone', 'Android', '태블릿', '화면 밖 놀이'])
                      DropdownMenuItem(value: d, child: Text(d)),
                  ],
                  onChanged: (d) => setState(() => device = d!),
                ),
                _question('어떻게 시작했나요?', startLabels, start, (v) => start = v),
                _question('보호자가 몇 번 도왔나요?', helpLabels, help, (v) => help = v),
                _question(
                  '아이의 반응은?',
                  enjoymentLabels,
                  enjoyment,
                  (v) => enjoyment = v,
                ),
                _question('어떻게 마쳤나요?', endingLabels, ending, (v) => ending = v),
                _question(
                  '화면 밖 놀이를 했나요?',
                  offscreenLabels,
                  offscreen,
                  (v) => offscreen = v,
                ),
                const SizedBox(height: 14),
                const Text('관찰한 문제만 선택 · 없으면 비워 두세요'),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final i in observationIssues)
                      FilterChip(
                        label: Text(i),
                        selected: issues.contains(i),
                        onSelected: (v) => setState(
                          () => v ? issues.add(i) : issues.remove(i),
                        ),
                      ),
                  ],
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
                FilledButton.icon(
                  onPressed:
                      saving ||
                          activityId == null ||
                          [
                            start,
                            help,
                            enjoyment,
                            ending,
                            offscreen,
                          ].contains(null)
                      ? null
                      : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('관찰 기록 저장'),
                ),
                const Text('기기에만 보관됩니다. 자동 전송·녹음·촬영은 하지 않습니다.'),
                const Divider(height: 30),
                for (final o in rows.reversed)
                  ListTile(
                    title: Text(names[o.activityId] ?? o.activityId),
                    subtitle: Text(
                      '${o.at.month}/${o.at.day} · ${enjoymentLabels[o.enjoyment]} · ${endingLabels[o.ending]}',
                    ),
                    trailing: IconButton(
                      tooltip: '관찰 삭제',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('이 관찰 기록을 삭제할까요?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await widget.state.deleteObservation(o.id);
                          } catch (_) {
                            setState(() => error = '삭제하지 못했어요. 다시 시도해 주세요.');
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget _question(
    String title,
    List<String> labels,
    int? value,
    ValueChanged<int> choose,
  ) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: forestInk),
        ),
        Wrap(
          spacing: 6,
          children: [
            for (var i = 0; i < labels.length; i++)
              ChoiceChip(
                label: Text(labels[i]),
                selected: value == i,
                onSelected: (_) => setState(() => choose(i)),
              ),
          ],
        ),
      ],
    ),
  );
  Future<void> _save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.state.saveObservation(
        PlayObservation(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          profileId: widget.profile.id,
          activityId: activityId!,
          sessionId: record?.sessionId,
          at: DateTime.now(),
          ageMonths: widget.profile.ageMonths,
          stage: widget.profile.stageFor(activityId!),
          start: start!,
          help: help!,
          enjoyment: enjoyment!,
          ending: ending!,
          offscreen: offscreen!,
          device: device,
          issues: issues.toList(),
        ),
      );
      if (!mounted) return;
      setState(() {
        start = help = enjoyment = ending = offscreen = null;
        issues = {};
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('관찰 기록을 저장했어요.')));
    } catch (_) {
      if (mounted) setState(() => error = '저장하지 못했어요. 기록을 유지했으니 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
