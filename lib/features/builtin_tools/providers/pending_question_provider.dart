import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pending_question.dart';

class PendingQuestionState extends Equatable {
  const PendingQuestionState({this.pending, this.completer});

  final PendingQuestion? pending;
  final Completer<String>? completer;

  @override
  List<Object?> get props => [pending];
}

class PendingQuestionNotifier extends Notifier<PendingQuestionState> {
  @override
  PendingQuestionState build() => const PendingQuestionState();

  Future<String> ask(PendingQuestion question) {
    final completer = Completer<String>();
    state = PendingQuestionState(pending: question, completer: completer);
    return completer.future;
  }

  void submitAnswer(String answer) {
    final completer = state.completer;
    state = const PendingQuestionState();
    if (completer != null && !completer.isCompleted) {
      completer.complete(answer);
    }
  }

  void dismiss() {
    final completer = state.completer;
    state = const PendingQuestionState();
    if (completer != null && !completer.isCompleted) {
      completer.complete('User dismissed the question.');
    }
  }
}

final pendingQuestionProvider =
    NotifierProvider<PendingQuestionNotifier, PendingQuestionState>(
  PendingQuestionNotifier.new,
);