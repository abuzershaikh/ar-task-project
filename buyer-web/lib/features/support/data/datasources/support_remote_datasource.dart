import '../../../../core/network/dio_client.dart';
import '../models/support_ticket_model.dart';

abstract class SupportRemoteDataSource {
  Future<List<SupportTicketModel>> getTickets();
  Future<bool> createTicket(String subject, String category, String message);
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final DioClient client;

  SupportRemoteDataSourceImpl(this.client);

  @override
  Future<List<SupportTicketModel>> getTickets() async {
    final response = await client.get('/buyer/support/tickets');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data['tickets'] ?? response.data['data'] ?? [];
      return list.map((json) => SupportTicketModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<bool> createTicket(String subject, String category, String message) async {
    final response = await client.post(
      '/buyer/support/tickets',
      data: {
        'subject': subject,
        'category': category,
        'message': message,
      },
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
