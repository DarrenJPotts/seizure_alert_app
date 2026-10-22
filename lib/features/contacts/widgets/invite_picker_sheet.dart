import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/constants/snackbar_margin.dart';
import 'package:seizure_app/core/dtos/onboarding_invite_dto.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/core/services/circle_invite_service.dart';
import 'package:seizure_app/core/services/invite_service.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';

typedef RegenerateInviteCallback = Future<ResultDto<String>> Function();

class InvitePickerSheet extends StatefulWidget {
  const InvitePickerSheet({
    super.key,
    required this.phone,
    required this.contactName,
    this.code,
    this.loadCode,
    this.onRegenerate,
  }) : assert(code != null || loadCode != null);

  final String phone;
  final String contactName;
  final String? code;
  final RegenerateInviteCallback? loadCode;
  final RegenerateInviteCallback? onRegenerate;

  static void showAfterNavigation(OnboardingInviteDto invite) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = Get.context;
      if (context == null) return;
      AppBottomSheet.show(
        context: context,
        builder: (_) => InvitePickerSheet(
          phone: invite.phone,
          contactName: invite.contactName,
          code: invite.code,
          onRegenerate: () => CircleInviteService.instance().createCircleInvite(
            contactId: invite.contactId,
            regenerate: true,
          ),
        ),
      );
    });
  }

  @override
  State<InvitePickerSheet> createState() => _InvitePickerSheetState();
}

class _InvitePickerSheetState extends State<InvitePickerSheet> {
  late String? _code = widget.code;
  bool _isLoadingCode = false;
  String? _loadError;

  bool get _codeReady => _code != null && !_isLoadingCode && !_isRegenerating;

  @override
  void initState() {
    super.initState();
    if (_code == null) _loadCode();
  }

  Future<void> _loadCode() async {
    setState(() {
      _isLoadingCode = true;
      _loadError = null;
    });
    try {
      final result = await widget.loadCode!();
      if (!mounted) return;
      setState(() {
        _isLoadingCode = false;
        _code = result.isSuccess ? result.data : null;
        if (_code == null) _loadError = result.error ?? 'Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingCode = false;
        _loadError = 'Could not load the invite code. Please try again.';
      });
    }
  }

  bool _isRegenerating = false;

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generate a new code?'),
        content: const Text('The current invite code will stop working.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Generate new code'),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.onRegenerate == null || !mounted) return;

    setState(() => _isRegenerating = true);
    final result = await widget.onRegenerate!();
    if (!mounted) return;
    setState(() => _isRegenerating = false);
    if (!result.isSuccess || result.data == null) {
      Get.snackbar(
        'Could not generate code',
        result.error ?? 'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: snackbarMargin,
      );
      return;
    }
    setState(() => _code = result.data!);
  }

  Future<void> _copyCode() async {
    if (!_codeReady) return;
    await Clipboard.setData(ClipboardData(text: _code!));
    if (!mounted) return;
    Get.snackbar(
      'Code copied',
      'Share it with ${widget.contactName}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetContent(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invite ${widget.contactName}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: Dimensions.four),
          Text(
            'This code expires 24 hours after generation. Reopen this invite to resend it.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
          ),
          const SizedBox(height: Dimensions.twentyFour),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: Dimensions.sixteen,
              horizontal: Dimensions.twenty,
            ),
            decoration: BoxDecoration(
              border: context.designBorder,
              borderRadius: BorderRadius.circular(context.design.cardRadius),
            ),
            child: _isLoadingCode || _isRegenerating
                ? Center(
                    child: SizedBox(
                      width: Dimensions.twentyFour,
                      height: Dimensions.twentyFour,
                      child: CircularProgressIndicator(
                        color: context.ink,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : _loadError != null
                ? Column(
                    children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _loadCode,
                        child: const Text('Retry'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            _code ?? '',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                  fontFeatures: [
                                    const FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy code',
                        onPressed: _codeReady ? _copyCode : null,
                        icon: const Icon(Icons.copy_outlined),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: Dimensions.twentyFour),
          Text(
            'Share or resend',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Dimensions.twelve),
          _ChannelRow(
            icon: Icons.sms_outlined,
            label: 'Via SMS',
            enabled: _codeReady,
            onTap: () {
              if (!_codeReady) return;
              Get.back();
              InviteService.sendSmsInvite(phone: widget.phone, code: _code!);
            },
          ),
          const SizedBox(height: Dimensions.twelve),
          _ChannelRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Via WhatsApp',
            enabled: _codeReady,
            onTap: () {
              if (!_codeReady) return;
              Get.back();
              InviteService.sendWhatsAppInvite(
                phone: widget.phone,
                code: _code!,
              );
            },
          ),
          if (widget.onRegenerate != null) ...[
            const SizedBox(height: Dimensions.twelve),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _codeReady ? _regenerate : null,
                icon: _isRegenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  _isRegenerating ? 'Generating…' : 'Generate new code',
                ),
              ),
            ),
          ],
          const SizedBox(height: Dimensions.eight),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(foregroundColor: context.ink),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(context.design.cardRadius),
    child: Container(
      padding: const EdgeInsets.all(Dimensions.sixteen),
      decoration: BoxDecoration(
        border: context.designBorder,
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.ink.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 20, color: context.secondaryInk),
          ),
          const SizedBox(width: Dimensions.twelve),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? context.ink
                    : context.ink.withValues(alpha: 0.26),
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.ink.withValues(alpha: 0.26)),
        ],
      ),
    ),
  );
}
