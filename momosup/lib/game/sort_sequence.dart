import 'dart:math';

List<int> sortSequence({
  required int seed,
  required int step,
  required int bins,
  required int goal,
}) {
  if (bins <= 1) return List.filled(goal, 0);
  final values = List.generate(goal, (i) => i % bins);
  values.shuffle(Random(seed + step * 7919));
  return values;
}
