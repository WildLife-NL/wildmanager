import 'package:flutter/material.dart';

import '../../state/filter_state.dart';

class FilterContent extends StatefulWidget {
  const FilterContent({
    super.key,
    required this.scrollController,
    required this.initialDraft,
    required this.onApply,
  });

  final ScrollController scrollController;
  final FilterState initialDraft;
  final void Function(FilterState draft) onApply;

  @override
  State<FilterContent> createState() => _FilterContentState();
}

class _FilterContentState extends State<FilterContent> {
  late FilterState _draft;

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  void initState() {
    super.initState();
    _draft = widget.initialDraft;
  }

  @override
  void didUpdateWidget(FilterContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDraft != oldWidget.initialDraft) {
      _draft = widget.initialDraft;
    }
  }

  void _apply() {
    if (_draft.momentAfter != null &&
        _draft.momentBefore != null &&
        _draft.momentBefore!.isBefore(DateTime(
            _draft.momentAfter!.year, _draft.momentAfter!.month, _draft.momentAfter!.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tot datum moet op of na de vanaf-datum liggen')),
      );
      return;
    }
    widget.onApply(_draft);
  }

  void _reset() {
    setState(() => _draft = FilterState.defaults);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Na toepassen wordt de data opnieuw geladen.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            children: [
              _SectionTitle(title: 'PERIODE'),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  _draft.momentAfter == null
                      ? 'Vanaf datum'
                      : 'Vanaf: ${_formatDate(_draft.momentAfter!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _draft.momentAfter ?? now,
                    firstDate: DateTime(2020),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _draft = _draft.copyWith(momentAfter: date));
                },
              ),
              const SizedBox(height: 4),
              ListTile(
                title: Text(
                  _draft.momentBefore == null
                      ? 'Tot datum'
                      : 'Tot: ${_formatDate(_draft.momentBefore!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  final now = DateTime.now();
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _draft.momentBefore ?? now,
                    firstDate: DateTime(2020),
                    lastDate: now.add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _draft = _draft.copyWith(momentBefore: date));
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'TYPE GEBEURTENIS'),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text('Waarneming'),
                value: _draft.waarneming,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(waarneming: v ?? false)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Schade'),
                value: _draft.schade,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(schade: v ?? false)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Aanrijding'),
                value: _draft.aanrijding,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(aanrijding: v ?? false)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Detectie'),
                value: _draft.detectie,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(detectie: v ?? false)),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_draft.detectie) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 24, top: 4),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('Detectie visueel'),
                        value: _draft.detectieVisueel,
                        onChanged: (v) => setState(() =>
                            _draft = _draft.copyWith(detectieVisueel: v ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Detectie akoestisch'),
                        value: _draft.detectieAkoestisch,
                        onChanged: (v) => setState(() =>
                            _draft = _draft.copyWith(detectieAkoestisch: v ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Overig'),
                        value: _draft.detectieOverig,
                        onChanged: (v) => setState(() =>
                            _draft = _draft.copyWith(detectieOverig: v ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _SectionTitle(title: 'WEERGAVE'),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Toon dieren'),
                value: _draft.showAnimals,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(showAnimals: v)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              SwitchListTile(
                title: const Text('Recreatiedruk'),
                value: _draft.showHeatmap,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(showHeatmap: v)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              SwitchListTile(
                title: const Text('Living lab'),
                value: _draft.showLivingLab,
                onChanged: (v) => setState(() => _draft = _draft.copyWith(showLivingLab: v)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              children: [
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Toepassen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
