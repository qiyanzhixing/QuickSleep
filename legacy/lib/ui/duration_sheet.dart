import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../settings/preferences.dart';

Future<int?> showDurationSheet(BuildContext context, int current) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DurationSheet(current: current),
    );

class DurationSheet extends StatefulWidget {
  const DurationSheet({super.key, required this.current});
  final int current;
  @override
  State<DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<DurationSheet> {
  late final controller = TextEditingController(
    text: widget.current.toString(),
  );
  bool invalid = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void save() {
    final value = parseCustomMinutes(controller.text);
    if (value == null) {
      setState(() => invalid = true);
    } else {
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.customTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey('duration_input'),
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => save(),
                decoration: InputDecoration(
                  labelText: l.durationTitle,
                  helperText: l.customHint,
                  helperMaxLines: 3,
                  errorText: invalid ? l.customError : null,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('save_duration'),
                onPressed: save,
                child: Text(l.save),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
