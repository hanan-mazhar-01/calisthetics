import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../user/presentation/providers/user_providers.dart';
import '../../domain/activity_log.dart';

/// "Add Workout": log something she did outside the plan. Shown as a full
/// sheet with Cancel / Add, a date, a name and a length in minutes.
Future<void> showAddActivity(BuildContext context, {DateTime? day}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddActivitySheet(initialDay: day),
  );
}

class _AddActivitySheet extends ConsumerStatefulWidget {
  const _AddActivitySheet({this.initialDay});
  final DateTime? initialDay;

  @override
  ConsumerState<_AddActivitySheet> createState() => _AddActivitySheetState();
}

class _AddActivitySheetState extends ConsumerState<_AddActivitySheet> {
  final _name = TextEditingController();
  final _length = TextEditingController();
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = dayOf(widget.initialDay ?? ref.read(clockProvider)());
    _name.addListener(() => setState(() {}));
    _length.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    super.dispose();
  }

  int? get _minutes {
    final v = int.tryParse(_length.text.trim());
    return v != null && v >= 1 && v <= 600 ? v : null;
  }

  bool get _valid => _name.text.trim().isNotEmpty && _minutes != null;

  Future<void> _pickDate() async {
    final today = dayOf(ref.read(clockProvider)());
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(today.year - 3),
      lastDate: today,
    );
    if (picked != null) setState(() => _day = dayOf(picked));
  }

  Future<void> _add() async {
    if (!_valid) return;
    final session = manualActivity(
      name: _name.text,
      minutes: _minutes!,
      day: _day,
      now: ref.read(clockProvider)(),
    );
    await ref.read(historyProvider.notifier).add(session);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Cancel',
                      style: AppTypography.body(c.textPrimary, fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Add Workout',
                    textAlign: TextAlign.center,
                    style: AppTypography.title(
                      18,
                      c.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  enabled: _valid,
                  label: 'Add',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _valid ? _add : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Add',
                        style: AppTypography.title(
                          16,
                          _valid ? c.accentText : c.textMuted,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _FieldRow(
                    label: 'Date',
                    onTap: _pickDate,
                    child: Text(
                      longDate(_day),
                      textAlign: TextAlign.end,
                      style: AppTypography.body(c.textPrimary, fontSize: 16),
                    ),
                  ),
                  Divider(height: 1, indent: 16, color: c.divider),
                  _FieldRow(
                    label: 'Name',
                    child: TextField(
                      controller: _name,
                      textAlign: TextAlign.end,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 40,
                      style: AppTypography.body(c.textPrimary, fontSize: 16),
                      decoration: _hint(c, 'Name'),
                    ),
                  ),
                  Divider(height: 1, indent: 16, color: c.divider),
                  _FieldRow(
                    label: 'Length',
                    child: TextField(
                      controller: _length,
                      textAlign: TextAlign.end,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      style: AppTypography.body(c.textPrimary, fontSize: 16),
                      decoration: _hint(c, 'Minutes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  InputDecoration _hint(AppColorsExtension c, String text) => InputDecoration(
    hintText: text,
    hintStyle: AppTypography.body(c.textMuted, fontSize: 16),
    border: InputBorder.none,
    counterText: '',
    isDense: true,
    contentPadding: EdgeInsets.zero,
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child, this.onTap});
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.body(
                c.textPrimary,
                fontSize: 16,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
