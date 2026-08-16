# Bug Report: Service Publish Type Casting Error (type 'String' is not a subtype of type 'num?')

## Issue Description
When publishing a service version in Service Builder (`publishServiceVersion`), a runtime exception occurred:
`type 'String' is not a subtype of type 'num?' in type cast`

## Root Cause Analysis
1. Device logcat evidence:
   `[ADMIN REPO] Remote getServiceById exception: type 'String' is not a subtype of type 'num?' in type cast`
   `[ADMIN REPO] publishServiceVersion server error: type 'String' is not a subtype of type 'num?' in type cast`
2. NestJS / MySQL returned numeric fields (e.g. `buyerUnitPrice`, `marginValue`, `version`, `orderIndex`) as Strings (e.g. `"50.00"`, `"1"`, `"20.0"`).
3. The repository and domain models were performing raw type assertions:
   `(pricingMap['buyerUnitPrice'] as num?)`
   `(s['version'] as num?)`
   `json['orderIndex'] ?? 0`
4. Because the JSON values were `String`, Dart's runtime type check failed and threw `TypeError`.

## Solution
1. Introduced robust helper methods `_toDouble()` and `_toInt()` in `ServiceBuilderRepositoryImpl`, `PricingConfig`, `PriceChipModel`, `TemplateElement`, and `ServiceModel`.
2. Safe helpers attempt `double.tryParse()` / `int.tryParse()` when given a `String`, falling back gracefully to defaults without throwing exceptions.

## Affected Files
- `lib/features/service_builder/data/repositories/service_builder_repository_impl.dart`
- `lib/features/service_builder/domain/models/pricing_config.dart`
- `lib/features/service_builder/domain/models/service_model.dart`
- `lib/features/service_builder/domain/models/template_element.dart`
