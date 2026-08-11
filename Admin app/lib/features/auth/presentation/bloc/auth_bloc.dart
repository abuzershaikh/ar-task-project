import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    AppLogger.info('Login attempt for: ${event.email}');

    final result = await _loginUseCase(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        AppLogger.error('Login failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        AppLogger.info('Login successful for: ${user.email}');
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    AppLogger.info('Logout requested');

    final result = await _logoutUseCase();

    result.fold(
      (failure) {
        AppLogger.error('Logout failed: ${failure.message}');
        // Even on failure, go to unauthenticated state
        emit(AuthUnauthenticated());
      },
      (_) {
        AppLogger.info('Logout successful');
        emit(AuthUnauthenticated());
      },
    );
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    AppLogger.info('Checking auth status');

    final result = await _getCurrentUserUseCase();

    result.fold(
      (failure) {
        AppLogger.error('Auth check failed: ${failure.message}');
        emit(AuthUnauthenticated());
      },
      (user) {
        AppLogger.info('User authenticated: ${user.email}');
        emit(AuthAuthenticated(user));
      },
    );
  }
}
