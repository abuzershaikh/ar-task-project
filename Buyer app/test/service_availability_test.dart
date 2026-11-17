import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:marketing_pro/core/network/dio_client.dart';
import 'package:marketing_pro/features/services/data/repositories/service_repository_impl.dart';
import 'package:marketing_pro/features/campaigns/presentation/pages/create_campaign_page.dart';

class CatalogClient implements DioClient {
  dynamic payload;
  bool fail = false;
  int catalogRequests = 0;
  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    if (path == '/buyer/services') catalogRequests++;
    if (fail) throw StateError('offline');
    return Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: payload);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late CatalogClient client;
  late ServiceRepositoryImpl repository;
  setUp(() {
    client = CatalogClient();
    repository = ServiceRepositoryImpl(dioClient: client);
  });

  test('an empty server catalog remains empty', () async {
    client.payload = {'services': []};
    expect(await repository.getPublishedServices(), isEmpty);
  });

  test('inactive and omitted services never return through local templates', () async {
    client.payload = {'services': [
      {'id': 'maps', 'code': 'GOOGLE_MAPS_RATING', 'isActive': false},
      {'id': 'other', 'code': 'OTHER', 'isActive': true},
    ]};
    expect((await repository.getPublishedServices()).map((s) => s.id), ['other']);
    client.payload = {'services': []};
    expect(await repository.getServiceById('maps'), isNull);
  });

  test('reactivation appears on the next catalog refresh', () async {
    client.payload = {'services': []};
    expect(await repository.getPublishedServices(), isEmpty);
    client.payload = {'services': [{'id': 'maps', 'code': 'GOOGLE_MAPS_RATING', 'isActive': true}]};
    expect((await repository.getPublishedServices()).single.id, 'maps');
  });

  test('network failures do not invent available services', () async {
    client.fail = true;
    await expectLater(repository.getPublishedServices(), throwsStateError);
  });

  test('malformed responses do not restore defaults', () async {
    client.payload = {'success': true};
    await expectLater(repository.getPublishedServices(), throwsStateError);
  });

  testWidgets('catalog refreshes automatically and resumes after backgrounding', (tester) async {
    client.payload = {'services': []};
    GetIt.instance.registerSingleton<DioClient>(client);
    addTearDown(() => GetIt.instance.reset());
    await tester.pumpWidget(const MaterialApp(home: CreateCampaignPage()));
    await tester.pumpAndSettle();
    expect(find.text('No services are available right now.'), findsOneWidget);
    expect(client.catalogRequests, 1);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(client.catalogRequests, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 20));
    expect(client.catalogRequests, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(client.catalogRequests, 3);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 20));
    expect(client.catalogRequests, 3);
  });
}
