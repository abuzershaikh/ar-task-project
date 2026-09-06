import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository_impl.dart';

abstract class InvoicesEvent extends Equatable {
  const InvoicesEvent();
  @override
  List<Object?> get props => [];
}

class LoadInvoicesEvent extends InvoicesEvent {}

abstract class InvoicesState extends Equatable {
  const InvoicesState();
  @override
  List<Object?> get props => [];
}

class InvoicesInitial extends InvoicesState {}
class InvoicesLoading extends InvoicesState {}
class InvoicesLoaded extends InvoicesState {
  final List<InvoiceModel> invoices;
  const InvoicesLoaded(this.invoices);
  @override
  List<Object?> get props => [invoices];
}
class InvoicesError extends InvoicesState {
  final String message;
  const InvoicesError(this.message);
  @override
  List<Object?> get props => [message];
}

class InvoicesBloc extends Bloc<InvoicesEvent, InvoicesState> {
  final InvoiceRepository repository;

  InvoicesBloc({required this.repository}) : super(InvoicesInitial()) {
    on<LoadInvoicesEvent>((event, emit) async {
      emit(InvoicesLoading());
      final result = await repository.getInvoices();
      result.fold(
        (failure) => emit(InvoicesError(failure.message)),
        (invoices) => emit(InvoicesLoaded(invoices)),
      );
    });
  }
}
