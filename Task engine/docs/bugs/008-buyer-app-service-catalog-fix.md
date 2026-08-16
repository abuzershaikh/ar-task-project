# Bug Report: Buyer App Missing Services & Type Cast Error (`String is not a subtype of num?`)

## Issue Description
1. In the Buyer App, created custom services were not showing up in the Services Catalog.
2. Opening the Services page resulted in a runtime exception: `type 'String' is not a subtype of type 'num?' in type cast`.

## Root Cause Analysis
1. **Backend Filtering Bug (`buyer/service-catalog.controller.ts`)**:
   When admins created custom services without explicit active pricing records, `getActivePricing()` threw a `NotFoundException` and the NestJS controller skipped those services from `catalogList`.
2. **Buyer App Data Model Unsafe Casts**:
   `ServiceModel.fromJson`, `PricingConfig.fromJson`, `PriceChipModel.fromJson`, and `TemplateElement.fromJson` in Buyer App performed raw `as num?` and `as int?` casts. Because numeric values from MySQL/NestJS JSON were strings (e.g. `"50.00"` or `"1"`), Dart runtime threw a `TypeError`, causing Buyer App's BLoC to fail and hide all services.

## Solution
1. **Backend Fix**: Updated `buyer/service-catalog.controller.ts` in NestJS Task Engine to provide fallback unit pricing (`buyerUnitPrice: 50.0`) when no custom pricing entity is attached, ensuring no created admin services are hidden from buyers.
2. **Buyer App Fix**: Added safe type converters (`parseD` and `parseI`) to `ServiceModel.fromJson`, `PricingConfig.fromJson`, `PriceChipModel.fromJson`, and `TemplateElement.fromJson` in Buyer App, enabling graceful parsing of strings, ints, doubles, and numbers.

## Affected Files
- `Task engine/apps/api/controllers/buyer/service-catalog.controller.ts`
- `Buyer app/lib/features/services/domain/models/service_model.dart`
- `Buyer app/lib/features/services/domain/models/pricing_config.dart`
- `Buyer app/lib/features/services/domain/models/template_element.dart`
