import '../../../../core/network/dio_client.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRemoteDataSource {
  Future<List<InvoiceModel>> getInvoices();
}

class InvoiceRemoteDataSourceImpl implements InvoiceRemoteDataSource {
  final DioClient client;

  InvoiceRemoteDataSourceImpl(this.client);

  @override
  Future<List<InvoiceModel>> getInvoices() async {
    final response = await client.get('/buyer/billing');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data['invoices'] ?? response.data['data'] ?? [];
      return list.map((json) => InvoiceModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
