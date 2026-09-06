import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/support_ticket_model.dart';
import '../../data/repositories/support_repository_impl.dart';

abstract class SupportEvent extends Equatable {
  const SupportEvent();
  @override
  List<Object?> get props => [];
}

class LoadSupportTicketsEvent extends SupportEvent {}

class CreateSupportTicketEvent extends SupportEvent {
  final String subject;
  final String category;
  final String message;

  const CreateSupportTicketEvent({
    required this.subject,
    required this.category,
    required this.message,
  });

  @override
  List<Object?> get props => [subject, category, message];
}

abstract class SupportState extends Equatable {
  const SupportState();
  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}
class SupportLoading extends SupportState {}
class SupportLoaded extends SupportState {
  final List<SupportTicketModel> tickets;
  const SupportLoaded(this.tickets);
  @override
  List<Object?> get props => [tickets];
}
class SupportError extends SupportState {
  final String message;
  const SupportError(this.message);
  @override
  List<Object?> get props => [message];
}
class TicketCreatedSuccess extends SupportState {
  final String message;
  const TicketCreatedSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  final SupportRepository repository;

  SupportBloc({required this.repository}) : super(SupportInitial()) {
    on<LoadSupportTicketsEvent>((event, emit) async {
      emit(SupportLoading());
      final result = await repository.getTickets();
      result.fold(
        (failure) => emit(SupportError(failure.message)),
        (tickets) => emit(SupportLoaded(tickets)),
      );
    });

    on<CreateSupportTicketEvent>((event, emit) async {
      emit(SupportLoading());
      final result = await repository.createTicket(event.subject, event.category, event.message);
      result.fold(
        (failure) => emit(SupportError(failure.message)),
        (success) {
          if (success) {
            emit(const TicketCreatedSuccess('Support ticket created successfully!'));
            add(LoadSupportTicketsEvent());
          } else {
            emit(const SupportError('Failed to create ticket'));
          }
        },
      );
    });
  }
}
