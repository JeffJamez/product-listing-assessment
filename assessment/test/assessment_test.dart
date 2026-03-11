import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:winp_flux_assessment/di/service_locator.dart';
import 'package:winp_flux_assessment/models/product_model.dart';
import 'package:winp_flux_assessment/providers/product_list_provider.dart';
import 'package:winp_flux_assessment/services/html_content_service.dart';
import 'package:winp_flux_assessment/services/product_service.dart';
import 'package:winp_flux_assessment/widgets/responsive_layout.dart';

class _SuccessProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    return [
      ProductModel(
        id: 'p1',
        title: 'Smoke Jacket',
        imageUrl: 'https://example.com/jacket.jpg',
        htmlDescription: '<p>Test product.</p>',
        variants: [
          const VariantModel(
              id: 'v1', label: 'S', price: 49.99, currency: 'USD'),
        ],
      ),
    ];
  }
}

class _FailingProductService extends ProductService {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    throw Exception('Connection refused');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smoke test — must stay green. Do not delete.
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  test('smoke test', () {
    expect(1 + 1, 2);
  });

  // 1. Unit test — get_it resolves ProductService as the same instance.

  group('get_it service resolution', () {
    setUp(() => setupServiceLocator());
    tearDown(() => GetIt.instance.reset());

    test('ProductService resolves as the same singleton instance', () {
      final first = GetIt.instance<ProductService>();
      final second = GetIt.instance<ProductService>();

      expect(identical(first, second), isTrue);
    });

    test('HtmlContentService resolves as the same singleton instance', () {
      final first = GetIt.instance<HtmlContentService>();
      final second = GetIt.instance<HtmlContentService>();

      expect(identical(first, second), isTrue);
    });
  });

  // 2. Widget test — ResponsiveLayout renders the correct child at each breakpoint.

  group('ResponsiveLayout breakpoints', () {
    Widget buildLayout(double width) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: const ResponsiveLayout(
              mobile: Text('mobile'),
              tablet: Text('tablet'),
              desktop: Text('desktop'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders mobile child when width is below 600', (tester) async {
      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildLayout(399));
      await tester.pump();

      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('tablet'), findsNothing);
      expect(find.text('desktop'), findsNothing);
    });

    testWidgets('renders tablet child when width is between 600 and 1023',
        (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildLayout(800));
      await tester.pump();

      expect(find.text('tablet'), findsOneWidget);
      expect(find.text('mobile'), findsNothing);
      expect(find.text('desktop'), findsNothing);
    });

    testWidgets('renders desktop child when width is 1024 or above',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildLayout(1280));
      await tester.pump();

      expect(find.text('desktop'), findsOneWidget);
      expect(find.text('mobile'), findsNothing);
      expect(find.text('tablet'), findsNothing);
    });
  });

  // 3. Unit test — provider / notifier state transitions:

  group('provider state transitions', () {
    tearDown(() => GetIt.instance.reset());

    test('initial → loading → loaded on success', () async {
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _SuccessProductService());

      final provider = ProductListProvider();
      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [ProductListState.loading, ProductListState.loaded]);
      expect(provider.products, isNotEmpty);
    });

    test('initial → loading → error on failure', () async {
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _FailingProductService());

      final provider = ProductListProvider();
      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [ProductListState.loading, ProductListState.error]);
      expect(provider.errorMessage, isNotNull);
    });

    test('loaded → refreshing → loaded on second successful call', () async {
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();

      final states = <ProductListState>[];
      provider.addListener(() => states.add(provider.state));

      await provider.loadProducts();

      expect(states, [ProductListState.refreshing, ProductListState.loaded]);
    });

    test('products are not cleared when entering error from loaded', () async {
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _SuccessProductService());

      final provider = ProductListProvider();
      await provider.loadProducts();
      expect(provider.products, isNotEmpty);

      GetIt.instance.unregister<ProductService>();
      GetIt.instance.registerLazySingleton<ProductService>(
          () => _FailingProductService());

      await provider.loadProducts();

      expect(provider.state, ProductListState.error);
      expect(provider.products, isNotEmpty);
    });
  });
}
