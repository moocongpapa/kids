import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<DateTime?> showChildBirthDatePicker({
  required BuildContext context,
  required DateTime initialDate,
}) {
  final today = DateUtils.dateOnly(DateTime.now());
  final firstDate = DateTime(today.year - 10, today.month, today.day);
  final date = DateUtils.dateOnly(initialDate);
  final selected = date.isBefore(firstDate)
      ? firstDate
      : date.isAfter(today)
      ? today
      : date;

  // Locale alone does not install Korean resources. Keep the dialog's delegates
  // together with its locale, even when the caller still uses an English host.
  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => Localizations.override(
      context: dialogContext,
      locale: const Locale('ko', 'KR'),
      delegates: GlobalMaterialLocalizations.delegates,
      child: DatePickerDialog(
        initialDate: selected,
        firstDate: firstDate,
        lastDate: today,
        currentDate: today,
        helpText: '아이 생년월일 선택',
        cancelText: '취소',
        confirmText: '확인',
      ),
    ),
  );
}
