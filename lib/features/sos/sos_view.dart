import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';

class SosView extends StatelessWidget {
  const SosView({super.key, required this.viewModel});

  final RootViewModel viewModel;

  void _handleSOS(BuildContext context) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MinimalAlertDialog(
        onConfirm: () {
          Navigator.pop(context);
          _sendSOSAlert();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _sendSOSAlert() {
    HapticFeedback.heavyImpact();
    // TODO: trigger notification + location share
    Get.snackbar(
      '',
      '',
      titleText: Text(
        'Alert Sent',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      messageText: Text('Your circle has been notified', style: TextStyle(color: Colors.white)),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black,
      margin: EdgeInsets.all(16),
      borderRadius: 8,
      duration: Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimensions.twentyFour,
        children: [
          MinimalSOSButton(onPressed: () => _handleSOS(context)),
          Column(
            spacing: Dimensions.eight,
            children: [
              Text('Your circle will be notified immediately', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'with your live location',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
              ),
            ],
          ),

          /// Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.black12)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.twelve),
                child: Text('or', style: TextStyle(color: Colors.black38, fontSize: 13)),
              ),
              Expanded(child: Divider(color: Colors.black12)),
            ],
          ).paddingSymmetric(horizontal: Dimensions.thirtySix),

          /// Heads Up button
          Obx(() {
            final hasActive = HeadsUpViewModel.instance().activeHeadsUp.value != null;
            return OutlinedButton.icon(
              onPressed: hasActive ? null : () => HeadsUpBottomSheet.show(),
              icon: Icon(Icons.warning_amber_outlined, size: 18),
              label: Text(hasActive ? 'Heads Up already active' : 'Send a Heads Up instead'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: BorderSide(color: Colors.black26),
                padding: EdgeInsets.symmetric(horizontal: Dimensions.twentyFour, vertical: Dimensions.twelve),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
