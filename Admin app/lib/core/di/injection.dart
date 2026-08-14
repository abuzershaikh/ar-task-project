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

import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

import '../../features/workers/data/datasources/workers_remote_datasource.dart';
import '../../features/workers/domain/repositories/workers_repository.dart';
import '../../features/workers/presentation/bloc/workers_bloc.dart';

import '../../features/buyers/data/datasources/buyers_remote_datasource.dart';
import '../../features/buyers/domain/repositories/buyers_repository.dart';
import '../../features/buyers/presentation/bloc/buyers_bloc.dart';

import '../../features/orders/data/datasources/orders_remote_datasource.dart';
import '../../features/orders/domain/repositories/orders_repository.dart';
import '../../features/orders/presentation/bloc/orders_bloc.dart';

import '../../features/more/data/datasources/more_remote_datasource.dart';
import '../../features/more/domain/repositories/more_repository.dart';
import '../../features/more/presentation/bloc/more_bloc.dart';

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
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt(),
      secureStorage: getIt(),
      localStorage: getIt(),
    ),
  );
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  
  // Service Builder Feature
  getIt.registerLazySingleton<ServiceBuilderRepository>(
    () => ServiceBuilderRepositoryImpl(dioClient: getIt()),
  );

  // Dashboard Feature
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepository(getIt()),
  );

  // Workers Feature
  getIt.registerLazySingleton<WorkersRemoteDataSource>(
    () => WorkersRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<WorkersRepository>(
    () => WorkersRepositoryImpl(remoteDataSource: getIt()),
  );

  // Buyers Feature
  getIt.registerLazySingleton<BuyersRemoteDataSource>(
    () => BuyersRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<BuyersRepository>(
    () => BuyersRepositoryImpl(remoteDataSource: getIt()),
  );

  // Orders Feature
  getIt.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(remoteDataSource: getIt()),
  );

  // More Feature
  getIt.registerLazySingleton<MoreRemoteDataSource>(
    () => MoreRemoteDataSourceImpl(getIt()),
  );
  getIt.registerLazySingleton<MoreRepository>(
    () => MoreRepositoryImpl(remoteDataSource: getIt()),
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

  getIt.registerFactory(
    () => DashboardBloc(
      repository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => WorkersBloc(
      repository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => BuyersBloc(
      repository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => OrdersBloc(
      repository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => MoreBloc(
      repository: getIt(),
    ),
  );
}
