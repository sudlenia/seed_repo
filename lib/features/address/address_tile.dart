import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/core/tokens/app_tokens.dart';
import 'package:wallet_test/features/address/address_display.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

class AddressTile extends StatefulWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.network,
  });

  final String address;
  final String network;

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  late final AddressTileBloc _bloc = GetIt.instance<AddressTileBloc>();

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textScaleFactor = textScaler.scale(1.0);
    final formattedAddress = formatAddressForCell(widget.address, textScaleFactor);
    
    return Container(
      height: AppTokens.cellHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.horizontalPadding),
      color: AppTokens.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.network,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTokens.verticalGap),
                Text(
                  formattedAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTokens.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.gapTextIcon),
          BlocBuilder<AddressTileBloc, AddressTileState>(
            bloc: _bloc,
            builder: (context, state) {
              IconData iconData;
              Color iconColor;
              
              if (state.error != null) {
                iconData = Icons.error_outline;
                iconColor = AppTokens.danger;
              } else if (state.copied) {
                iconData = Icons.check;
                iconColor = AppTokens.success;
              } else {
                iconData = Icons.copy;
                iconColor = AppTokens.textSecondary;
              }
              
              return SizedBox(
                width: AppTokens.tapTarget,
                height: AppTokens.tapTarget,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _bloc.add(CopyTapped(widget.address)),
                  icon: Icon(
                    iconData,
                    size: AppTokens.iconSize,
                    color: iconColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}