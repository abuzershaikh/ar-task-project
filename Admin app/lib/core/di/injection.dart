import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_storage_service.dart';
import '../network/network_info.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/service_builder/domain/repositories/service_builder_repository.dart';
import '../../features/service_builder/data/repositories/service_builder_repository_impl.dart';
import '../../features/service_builder/presentation/bloc/service_builder_bloc.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);
  
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  getIt.registerLazySingleton(() => secureStorage);
  
  // Core Services
  getIt.registerLazySingleton(() => SecureStorageService(getIt()));
  getIt.registerLazySingleton(() => LocalStorageService(getIt()));
  getIt.registerLazySingleton(() => DioClient(getIt()));
  getIt.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  
  // Auth Feature
  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      secureStorage: getIt(),
      localStorage: getIt(),
    ),
  );
  
  // Use cases
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  
  // Service Builder Feature
  getIt.registerLazySingleton<ServiceBuilderRepository>(
    () => ServiceBuilderRepositoryImpl(),
  );

  // BLoC
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt(),
      logoutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => ServiceBuilderBloc(
      repository: getIt(),
    ),
  );
}
