import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_color_scheme.dart';
import '../../../../data/models/app_toast.dart';
import '../../state/radio_controller.dart';
import 'glass.dart';

class AddStationPanel extends StatefulWidget {
  const AddStationPanel({
    required this.controller,
    this.dense = false,
    super.key,
  });

  final RadioController controller;
  final bool dense;

  @override
  State<AddStationPanel> createState() => _AddStationPanelState();
}

class _AddStationPanelState extends State<AddStationPanel> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorScheme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, widget.dense ? 8 : 14),
      child: Container(
        padding: EdgeInsets.all(widget.dense ? 12 : 16),
        decoration: BoxDecoration(
          color: c.surfaceHighlight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            final nameField = TextField(
              controller: _nameController,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              cursorColor: c.textPrimary,
              decoration: glassInputDecoration(
                  context: context, hintText: 'Station name'),
            );
            final urlField = TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              style: TextStyle(fontSize: 14, color: c.textPrimary),
              cursorColor: c.textPrimary,
              decoration: glassInputDecoration(
                context: context,
                hintText: 'Stream URL (e.g. https://...)',
              ),
            );
            final addButton = FilledButton(
              onPressed: () => unawaited(_addStation()),
              style: FilledButton.styleFrom(
                minimumSize: Size(isCompact ? double.infinity : 124, 46),
                backgroundColor: c.textPrimary,
                foregroundColor: c.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Add Station',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (isCompact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      nameField,
                      const SizedBox(height: 8),
                      urlField,
                      const SizedBox(height: 10),
                      addButton,
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(child: nameField),
                      const SizedBox(width: 8),
                      Expanded(child: urlField),
                      const SizedBox(width: 10),
                      addButton,
                    ],
                  ),
                if (!widget.dense) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    'Paste a direct MP3, AAC, or OGG stream URL.',
                    style: TextStyle(
                      color: c.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _addStation() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      widget.controller
          .showToast('Please enter a station name', ToastType.error);
      return;
    }

    if (url.isEmpty) {
      widget.controller.showToast('Please enter a stream URL', ToastType.error);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      widget.controller.showToast(
        'Please enter a valid stream URL (e.g. https://...)',
        ToastType.error,
      );
      return;
    }

    await widget.controller.addCustomStation(name, url);
    _nameController.clear();
    _urlController.clear();
  }
}
