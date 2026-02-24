import 'package:flutter/material.dart';

import '../../models/interaction.dart';

class InteractionFilterSheet extends StatefulWidget {
  const InteractionFilterSheet({
    super.key,
    required this.typeFilter,
    required this.momentAfter,
    required this.momentBefore,
    required this.onApply,
  });

  final int? typeFilter;
  final DateTime? momentAfter;
  final DateTime? momentBefore;
  final void Function(int? typeId, DateTime? after, DateTime? before) onApply;

  @override
  State<InteractionFilterSheet> createState() => _InteractionFilterSheetState();
}

class _InteractionFilterSheetState extends State<InteractionFilterSheet> {
  late int? _selectedType;
  late DateTime? _momentAfter;
  late DateTime? _momentBefore;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeFilter;
    _momentAfter = widget.momentAfter;
    _momentBefore = widget.momentBefore;
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Interactie-filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Na "Toepassen" worden interacties opnieuw geladen voor het huidige kaartgebied.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Alle types')),
              DropdownMenuItem(value: interactionTypeSighting, child: Text('Waarneming')),
              DropdownMenuItem(value: interactionTypeDamage, child: Text('Schade')),
              DropdownMenuItem(value: interactionTypeCollision, child: Text('Aanrijding')),
            ],
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: Text(_momentAfter == null ? 'Vanaf datum' : 'Van: ${_formatDate(_momentAfter!)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: _momentAfter ?? now,
                firstDate: DateTime(2020),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _momentAfter = date);
            },
          ),
          ListTile(
            title: Text(_momentBefore == null ? 'Tot datum' : 'Tot: ${_formatDate(_momentBefore!)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: _momentBefore ?? now,
                firstDate: DateTime(2020),
                lastDate: now.add(const Duration(days: 365)),
              );
              if (date != null) setState(() => _momentBefore = date);
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _momentAfter = null;
                    _momentBefore = null;
                  });
                  widget.onApply(null, null, null);
                },
                child: const Text('Wissen'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    if (_momentAfter != null &&
                        _momentBefore != null &&
                        _momentBefore!.isBefore(DateTime(_momentAfter!.year, _momentAfter!.month, _momentAfter!.day))) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tot datum moet op of na de vanaf-datum liggen')),
                      );
                      return;
                    }
                    widget.onApply(_selectedType, _momentAfter, _momentBefore);
                  },
                  child: const Text('Toepassen'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
