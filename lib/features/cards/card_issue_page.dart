import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:wallet_test/features/cards/card_issue_bloc.dart';
import 'package:wallet_test/features/cards/card_issuer.dart';

class CardIssuePage extends StatefulWidget {
  const CardIssuePage({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  State<CardIssuePage> createState() => _CardIssuePageState();
}

class _CardIssuePageState extends State<CardIssuePage> {
  late final ICardIssuer _issuer = GetIt.instance<ICardIssuer>();
  late final CardIssueBloc _bloc = GetIt.instance<CardIssueBloc>();
  
  bool _cancelRequested = false;

  void _cancelOnce() {
    if (_cancelRequested) {
      return;
    }

    _cancelRequested = true;
    _issuer.cancelPending();
  }

  @override
  void dispose() {
    _cancelOnce();
    _bloc.close();
    super.dispose();
  }

  Future<void> _issue() async {
    _bloc.add(
      IssueTapped(
        CardIssueRequest(cardId: widget.cardId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Issue Card ${widget.cardId}'),
      ),
      body: Center(
        child: BlocBuilder<CardIssueBloc, CardIssueState>(
          bloc: _bloc,
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.issuing)
                  const CircularProgressIndicator()
                else if (state.error != null)
                  Text(
                    'Error: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.issuing ? null : _issue,
                  child: const Text('Issue card'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}