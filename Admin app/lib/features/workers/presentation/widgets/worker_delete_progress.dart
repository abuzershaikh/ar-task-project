import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/workers_bloc.dart';

Future<bool> deleteWorkersWithFeedback(BuildContext context, List<String> ids,
    {bool batch = false}) async {
  final bloc = context.read<WorkersBloc>();
  final messenger = ScaffoldMessenger.of(context);
  final result = await showDialog<Object>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _WorkerDeleteProgress(bloc: bloc, ids: ids, batch: batch),
  );
  final success = result == true;
  messenger.showSnackBar(SnackBar(
    content: Text(success
        ? 'Worker account and all worker history permanently deleted.'
        : 'Deletion failed: $result'),
    backgroundColor: success ? const Color(0xFF0F172A) : Colors.red.shade700,
    duration: Duration(seconds: success ? 3 : 8),
  ));
  return success;
}

class _WorkerDeleteProgress extends StatefulWidget {
  final WorkersBloc bloc;
  final List<String> ids;
  final bool batch;
  const _WorkerDeleteProgress({required this.bloc, required this.ids, required this.batch});

  @override
  State<_WorkerDeleteProgress> createState() => _WorkerDeleteProgressState();
}

class _WorkerDeleteProgressState extends State<_WorkerDeleteProgress> {
  int _completed = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _total = widget.ids.length;
    final completion = Completer<void>();
    completion.future.then((_) {
      if (mounted) Navigator.of(context).pop(true);
    }, onError: (Object error, StackTrace stack) {
      if (mounted) Navigator.of(context).pop(error);
    });
    widget.bloc.add(widget.batch
        ? BatchDeleteWorkersEvent(
            widget.ids,
            completion: completion,
            onProgress: (completed, total) {
              if (mounted) {
                setState(() {
                  _completed = completed;
                  _total = total;
                });
              }
            },
          )
        : DeleteWorkerEvent(widget.ids.single, completion: completion));
  }

  @override
  Widget build(BuildContext context) {
    final progressText = widget.batch && _total > 1
        ? 'Deleting workers ($_completed / $_total)…\nPlease wait, do not close.'
        : 'Deleting worker data. Please wait…';
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(progressText)),
        ]),
      ),
    );
  }
}
