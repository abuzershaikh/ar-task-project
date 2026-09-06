import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/invoice_remote_datasource.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<InvoiceModel>>> getInvoices();
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  final InvoiceRemoteDataSource remoteDataSource;

  InvoiceRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<InvoiceModel>>> getInvoices() async {
    try {
      final invoices = await remoteDataSource.getInvoices();
      return Right(invoices);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
