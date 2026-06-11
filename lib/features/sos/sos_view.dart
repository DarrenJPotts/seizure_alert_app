import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/widgets/alert_map_widget.dart';
import 'package:seizure_app/core/widgets/alert_responses_widget.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:seizure_app/features/sos/widgets/active_heads_up_card.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';

class SosView extends StatelessWidget {
  const SosView({super.key, required this.viewModel});

  final RootViewModel viewModel;

  void _handleSOS(BuildContext context, SosViewModel sosVm) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownAlertDialog(
        onConfirm: () {
          Navigator.pop(context);
          sosVm.startSos();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosVm = Get.find<SosViewModel>();

    return Obx(() {
      if (sosVm.activeSos.value != null) {
        return _buildActiveState(context, sosVm);
      }
      return _buildIdleState(context, sosVm);
    });
  }

  Widget _buildActiveState(BuildContext context, SosViewModel sosVm) {
    final alertId = sosVm.activeSos.value?.id ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.twentyFour,
            Dimensions.sixteen,
            Dimensions.twentyFour,
            0,
          ),
          child: Text('Emergency',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: Dimensions.twentyFour),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulsingSOSCircle(),
                      SizedBox(height: Dimensions.twentyFour),
                      Obx(() => Text(
                            'Active for ${sosVm.formattedElapsed()}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          )),
                      SizedBox(height: Dimensions.eight),
                      Text(
                        'Your circle is monitoring your status',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.black45),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: Dimensions.twentyFour),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Obx(() {
                      final alert = sosVm.activeSos.value;
                      final lat = alert?.latitude;
                      final lng = alert?.longitude;
                      if (lat == null || lng == null) {
                        return const AlertMapPlaceholder();
                      }
                      return AlertMapWidget(latitude: lat, longitude: lng);
                    }),
                  ),
                ),
                if (alertId.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                      Dimensions.eight,
                    ),
                    child: AlertResponsesWidget(alertId: alertId),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.thirtySix,
            Dimensions.sixteen,
            Dimensions.thirtySix,
            48,
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: sosVm.cancelSos,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black26),
                padding:
                    EdgeInsets.symmetric(vertical: Dimensions.sixteen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel Alert'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleState(BuildContext context, SosViewModel sosVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            Dimensions.twentyFour,
            Dimensions.sixteen,
            Dimensions.twentyFour,
            0,
          ),
          child: Text('Emergency',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SOSButton(onPressed: () => _handleSOS(context, sosVm)),
              SizedBox(height: Dimensions.thirtyTwo),
              Text(
                'Tap to alert your circle',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimensions.eight),
              Text(
                'Your contacts will be notified with your location',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Obx(() {
          final headsUpVm = HeadsUpViewModel.instance();
          final hasActiveHeadsUp = headsUpVm.activeHeadsUp.value != null;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              Dimensions.thirtySix,
              0,
              Dimensions.thirtySix,
              48,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.black12)),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.sixteen),
                      child: const Text(
                        'or',
                        style: TextStyle(color: Colors.black38, fontSize: 13),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.black12)),
                  ],
                ),
                SizedBox(height: Dimensions.sixteen),
                if (hasActiveHeadsUp)
                  ActiveHeadsUpCard(vm: headsUpVm)
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => HeadsUpBottomSheet.show(),
                      icon: const Icon(Icons.warning_amber_outlined,
                          size: 18),
                      label: const Text('Send a Heads Up instead'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black26),
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.twentyFour,
                          vertical: Dimensions.twelve,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
