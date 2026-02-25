import 'package:flutter/material.dart';
import 'package:wildlifenl_detection_components/wildlifenl_detection_components.dart';

import '../../models/interaction.dart';

class InteractionFilterSheet extends StatefulWidget {
  const InteractionFilterSheet({
    super.key,
    required this.typeFilter,
    required this.detectionTypeFilter,
    required this.momentAfter,
    required this.momentBefore,
    this.heatmapRoodVanaf,
    this.heatmapCellSizeMeters,
    required this.onApply,
  });

  final int? typeFilter;
  final DetectionType? detectionTypeFilter;
  final DateTime? momentAfter;
  final DateTime? momentBefore;
  final int? heatmapRoodVanaf;
  final double? heatmapCellSizeMeters;
  final void Function(
    int? typeId,
    DetectionType? detectionType,
    DateTime? after,
    DateTime? before, {
    int? heatmapRoodVanaf,
    double? heatmapCellSizeMeters,
  }) onApply;

  @override
  State<InteractionFilterSheet> createState() => _InteractionFilterSheetState();
}

class _InteractionFilterSheetState extends State<InteractionFilterSheet> {
  late int? _selectedType;
  late DetectionType? _selectedDetectionType;
  late DateTime? _momentAfter;
  late DateTime? _momentBefore;
  late TextEditingController _roodVanafController;
  late TextEditingController _cellSizeController;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.typeFilter;
    _selectedDetectionType = widget.detectionTypeFilter;
    _momentAfter = widget.momentAfter;
    _momentBefore = widget.momentBefore;
    _roodVanafController = TextEditingController(
      text: widget.heatmapRoodVanaf?.toString() ?? '',
    );
    _cellSizeController = TextEditingController(
      text: widget.heatmapCellSizeMeters?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _roodVanafController.dispose();
    _cellSizeController.dispose();
    super.dispose();
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Na "Toepassen" worden interacties en detections opnieuw geladen voor het huidige kaartgebied.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Interactie type'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Alle types')),
              DropdownMenuItem(value: interactionTypeSighting, child: Text('Waarneming')),
              DropdownMenuItem(value: interactionTypeDamage, child: Text('Schade')),
              DropdownMenuItem(value: interactionTypeCollision, child: Text('Aanrijding')),
            ],
            onChanged: (v) => setState(() => _selectedType = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DetectionType?>(
            value: _selectedDetectionType,
            decoration: const InputDecoration(labelText: 'Detectie type'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Alle detecties')),
              DropdownMenuItem(value: DetectionType.visual, child: Text('Visueel')),
              DropdownMenuItem(value: DetectionType.acoustic, child: Text('Acoustisch')),
              DropdownMenuItem(value: DetectionType.chemical, child: Text('Chemisch')),
              DropdownMenuItem(value: DetectionType.other, child: Text('Overig')),
            ],
            onChanged: (v) => setState(() => _selectedDetectionType = v),
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
          const SizedBox(height: 20),
          Text('Heatmap', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _roodVanafController,
            decoration: const InputDecoration(
              labelText: 'Rood vanaf',
              hintText: 'bijv. 35',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cellSizeController,
            decoration: const InputDecoration(
              labelText: 'Celgrootte (meters)',
              hintText: 'bijv. 50, 75, 100',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedType = null;
                    _selectedDetectionType = null;
                    _momentAfter = null;
                    _momentBefore = null;
                    _roodVanafController.text = '';
                    _cellSizeController.text = '';
                  });
                  widget.onApply(null, null, null, null, heatmapRoodVanaf: null, heatmapCellSizeMeters: null);
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
                    final roodVanaf = int.tryParse(_roodVanafController.text.trim());
                    final cellSizeM = double.tryParse(_cellSizeController.text.trim());
                    widget.onApply(
                      _selectedType,
                      _selectedDetectionType,
                      _momentAfter,
                      _momentBefore,
                      heatmapRoodVanaf: roodVanaf,
                      heatmapCellSizeMeters: cellSizeM,
                    );
                  },
                  child: const Text('Toepassen'),
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }
}
