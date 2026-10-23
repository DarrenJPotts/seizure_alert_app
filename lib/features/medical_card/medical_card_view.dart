import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'models/medical_card_data.dart';
import 'widgets/medical_card_preview.dart';

class MedicalCardView extends StatefulWidget {
  const MedicalCardView({super.key, required this.user, this.share});
  final UserDto user;
  final Future<ShareResult> Function(ShareParams)? share;
  @override
  State<MedicalCardView> createState() => _MedicalCardViewState();
}

class _MedicalCardViewState extends State<MedicalCardView> {
  final Set<MedicalCardField> _fields = MedicalCardField.values.toSet();
  bool _sharing = false;
  MedicalCardData get _data => MedicalCardData(widget.user);
  Future<void> _chooseDetails() async {
    HapticFeedback.selectionClick();
    await AppBottomSheet.show<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => AppBottomSheetContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Details to include',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: Dimensions.eight),
              Text(
                'Only selected details appear on the card and in shared text.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: Dimensions.twelve),
              for (final field in MedicalCardField.values)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(field.label),
                  subtitle: _data.values[field]!.isEmpty
                      ? const Text('Not recorded in Profile')
                      : null,
                  value:
                      _fields.contains(field) &&
                      _data.values[field]!.isNotEmpty,
                  onChanged: _data.values[field]!.isEmpty
                      ? null
                      : (value) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            value == true
                                ? _fields.add(field)
                                : _fields.remove(field);
                          });
                          updateSheet(() {});
                        },
                ),
              const SizedBox(height: Dimensions.sixteen),
              OutlinedButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share() async {
    if (_sharing || _data.selected(_fields).isEmpty) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _sharing = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Share medical information?'),
          content: const Text(
            'Only the details shown on this card will be shared as text. Choose a trusted recipient. They can keep or forward a copy, and deleting your account will not remove their copy. The app you choose may process information outside South Africa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Share'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final params = ShareParams(
        subject: 'Medical card',
        text: _data.shareText(_fields),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      );
      await (widget.share ?? SharePlus.instance.share)(params);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The medical card could not be shared. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const BackButton(),
      title: const Text('Medical card'),
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.all(Dimensions.twentyFour),
        children: [
          Text(
            'Your details, ready to share',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Dimensions.eight),
          Text(
            'Review your information and choose what to include.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.secondaryInk),
          ),
          const SizedBox(height: Dimensions.twentyFour),
          MedicalCardPreview(details: _data.selected(_fields)),
          const SizedBox(height: Dimensions.sixteen),
          OutlinedButton.icon(
            onPressed: _sharing ? null : _chooseDetails,
            icon: const Icon(Icons.tune),
            label: const Text('Choose details'),
          ),
          const SizedBox(height: Dimensions.twelve),
          ElevatedButton.icon(
            onPressed: _sharing || _data.selected(_fields).isEmpty
                ? null
                : _share,
            icon: const Icon(Icons.ios_share),
            label: Text(_sharing ? 'Preparing share…' : 'Share medical card'),
          ),
          const SizedBox(height: Dimensions.sixteen),
          Text(
            'Shared as text through an app you choose. Recipients can keep or forward a copy.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
          ),
        ],
      ),
    ),
  );
}
