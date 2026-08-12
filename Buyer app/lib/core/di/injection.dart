import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../storage/secure_storage_service.dart';
import '../storage/local_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/data/datasources/dashboard_remote_datasource.dart';
import '../../features/home/data/repositories/dashboard_repository_impl.dart';
import '../../features/home/domain/repositories/dashboard_repository.dart';
import '../../features/home/domain/usecases/get_dashboard_data_usecase.dart';
import '../../features/home/presentation/bloc/dashboard_bloc.dart';
import '../../features/wallet/data/datasources/wallet_remote_datasource.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/domain/usecases/get_wallet_balance.dart';
import '../../features/wallet/domain/usecases/get_transactions.dart';
import '../../features/wallet/domain/usecases/add_balance.dart';
import '../../features/wallet/domain/usecases/verify_balance_payment.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  const secureStorage = FlutterSecureStorage();
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  
  // Storage Services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(getIt()),
  );
  
  getIt.registerLazySingleton<LocalStorageService>(
    () => LocalStorageService(getIt()),
  );
  
  // Network
  getIt.registerLazySingleton<AuthInterceptor>(
    () => AuthInterceptor(getIt()),
  );
  
  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.interceptors.add(getIt<AuthInterceptor>());
    return dio;
  });
  
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(getIt()),
  );
  
  // Auth Feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt()),
  );
  
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
  
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt()));
  
  getIt.registerFactory(() => AuthBloc(
    loginUseCase: getIt(),
    logoutUseCase: getIt(),
    secureStorage: getIt(),
    authRepository: getIt(),
  ));
  
  // Home/Dashboard Feature
  getIt.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSourceImpl(getIt()),
  );
  
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt()),
  );
  
  getIt.registerLazySingleton(() => GetDashboardDataUseCase(getIt()));
  
  getIt.registerFactory(() => DashboardBloc(getIt()));
  
  // Wallet Feature
  getIt.registerLazySingleton<WalletRemoteDataSource>(
    () => WalletRemoteDataSourceImpl(client: getIt()),
  );
  
  getIt.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(remoteDataSource: getIt()),
  );
  
  getIt.registerLazySingleton(() => GetWalletBalance(getIt()));
  getIt.registerLazySingleton(() => GetTransactions(getIt()));
  getIt.registerLazySingleton(() => AddBalance(getIt()));
  getIt.registerLazySingleton(() => VerifyBalancePayment(getIt()));
  
  getIt.registerFactory(() => WalletBloc(
    getWalletBalance: getIt(),
    getTransactions: getIt(),
    addBalance: getIt(),
    verifyBalancePayment: getIt(),
  ));
}
