# Admin App Auth, Logout & Bad State Bugs

## 1. Worker List Not Showing (AuthException)

### Bug Description
The "Workers" tab in the Admin app was showing an `Error: Instance of AuthException` or an empty list, and the user was getting randomly logged out of the application. 

### Cause
When the app made a request to the backend (e.g., `getServiceById` or `/api/admin/workers`), the backend rejected the request with a `401 Unauthorized` status.
The `dio_client.dart` in the Flutter app was configured to aggressively intercept any `401` response and automatically delete the authentication tokens from secure storage. 
Once the tokens were deleted, all subsequent requests failed with `401`, causing the Workers list to fail loading.

### Fix / Cure
1. **Backend (JWT Auth Guard)**: Modified `jwt-auth.guard.ts` to bypass JWT authentication for all `/admin/` routes (since the admin requested to remove auth checks after initial login).
2. **Frontend (Dio Client)**: Commented out the code in `dio_client.dart` that automatically deletes tokens on `401`. This prevents the app from forcefully logging out the user due to a single endpoint failure.

---

## 2. Logout Button Not Working

### Bug Description
Tapping the "Logout" button in the "More / Control Center" tab did nothing visibly, leaving the user stuck on the same screen.

### Cause
The `AuthBloc` was correctly emitting the `AuthUnauthenticated` state. However, because the user was deep inside the navigation stack (or because of a routing quirk with `MainNavigationScreen`), the `BlocBuilder` at the root of `main.dart` changing the `home` property was not correctly popping the stuck routes to show the `LoginScreen`.

### Fix / Cure
Updated the `onTap` handler in `ControlCenterScreen` to forcefully use `Navigator.pushAndRemoveUntil` to navigate to the `LoginScreen` while clearing all previous routes from the navigator stack immediately after dispatching the `AuthLogoutRequested` event.

---

## 3. Service Creation "Bad state: No element" Error

### Bug Description
When trying to create or publish a service in the Admin app, the app crashed or showed `[ADMIN REPO] publishServiceVersion server error: Bad state: No element`.

### Cause
The `getServiceById` method in `service_builder_repository_impl.dart` was catching remote API exceptions (such as the `401` AuthException) and silently falling back to returning `_mockServices.firstWhere(...)`. 
Since `_mockServices` was an empty array, calling `.first` or `.firstWhere` threw a Dart `StateError: Bad state: No element`. This masked the actual API error and broke the service publishing flow.

### Fix / Cure
Updated `getServices` and `getServiceById` in `service_builder_repository_impl.dart` to `rethrow` the API exception if a remote fetch fails. Also added a safety check: `if (_mockServices.isEmpty) throw Exception('Service not found');` to gracefully handle empty caches instead of throwing unhandled state errors.
