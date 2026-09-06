# Contributing to Marketing Pro - Buyer App

Thank you for considering contributing to Marketing Pro! This document provides guidelines and instructions for contributing to the project.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Architecture Guidelines](#architecture-guidelines)
- [Testing Guidelines](#testing-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Collaborate and communicate openly
- Prioritize product quality and user experience

## Getting Started

### Prerequisites
1. Install Flutter SDK (3.0.0+)
2. Install Android Studio
3. Set up Android SDK
4. Install Git
5. Read ARCHITECTURE.md and SETUP.md

### Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd "Buyer app"

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Development Workflow

### Branch Strategy

**Main Branches:**
- `main` - Production-ready code
- `develop` - Integration branch for features
- `staging` - Pre-production testing

**Feature Branches:**
```
feature/feature-name
bugfix/bug-description
hotfix/critical-fix
refactor/refactor-description
```

### Workflow Steps

1. **Create Branch**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/campaign-creation
```

2. **Develop**
- Write code following standards
- Add tests
- Update documentation

3. **Test**
```bash
flutter test
flutter analyze
```

4. **Commit**
```bash
git add .
git commit -m "feat: add campaign creation flow"
```

5. **Push & PR**
```bash
git push origin feature/campaign-creation
# Create Pull Request on GitHub
```

## Code Standards

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines.

#### Naming Conventions

**Files:**
```dart
// Use snake_case
campaign_detail_page.dart
auth_repository.dart
dashboard_bloc.dart
```

**Classes:**
```dart
// Use PascalCase
class CampaignDetailPage {}
class AuthRepository {}
class DashboardBloc {}
```

**Variables & Functions:**
```dart
// Use camelCase
final userEmail = 'user@example.com';
void fetchCampaigns() {}
```

**Constants:**
```dart
// Use lowerCamelCase
const maxRetryAttempts = 3;
const apiBaseUrl = 'https://api.example.com';
```

**Private Members:**
```dart
// Prefix with underscore
final _controller = TextEditingController();
void _handleSubmit() {}
```

#### Code Formatting

```bash
# Format all files
flutter format .

# Format specific file
flutter format lib/features/auth/presentation/pages/login_page.dart
```

#### Code Analysis

```bash
# Analyze code
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

### Widget Guidelines

**Use const constructors:**
```dart
// Good
const Text('Hello');
const SizedBox(height: 16);

// Avoid
Text('Hello');
SizedBox(height: 16);
```

**Extract reusable widgets:**
```dart
// Good
class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  const _CampaignCard({required this.campaign});
  
  @override
  Widget build(BuildContext context) {
    return Card(...);
  }
}

// Avoid - Large widgets in build method
```

**Keep build methods small:**
```dart
// Aim for < 50 lines in build()
// Extract complex UI into separate methods or widgets
```

## Architecture Guidelines

### Clean Architecture Layers

```
presentation/ (UI, BLoC)
    ↓
domain/ (Entities, Use Cases, Repository Interfaces)
    ↓
data/ (Models, Repository Implementations, Data Sources)
```

### Feature Structure

Each feature must follow this structure:

```
feature/
├── data/
│   ├── datasources/
│   │   └── feature_remote_datasource.dart
│   ├── models/
│   │   └── feature_model.dart
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── feature_entity.dart
│   ├── repositories/
│   │   └── feature_repository.dart
│   └── usecases/
│       └── feature_usecase.dart
└── presentation/
    ├── bloc/
    │   └── feature_bloc.dart
    ├── pages/
    │   └── feature_page.dart
    └── widgets/
        └── feature_widget.dart
```

### BLoC Pattern

**Events:**
```dart
abstract class CampaignEvent extends Equatable {}

class LoadCampaignsEvent extends CampaignEvent {
  @override
  List<Object?> get props => [];
}
```

**States:**
```dart
abstract class CampaignState extends Equatable {}

class CampaignLoading extends CampaignState {
  @override
  List<Object?> get props => [];
}

class CampaignLoaded extends CampaignState {
  final List<Campaign> campaigns;
  
  CampaignLoaded(this.campaigns);
  
  @override
  List<Object?> get props => [campaigns];
}
```

**BLoC:**
```dart
class CampaignBloc extends Bloc<CampaignEvent, CampaignState> {
  final GetCampaignsUseCase getCampaignsUseCase;
  
  CampaignBloc(this.getCampaignsUseCase) : super(CampaignInitial()) {
    on<LoadCampaignsEvent>(_onLoadCampaigns);
  }
  
  Future<void> _onLoadCampaigns(
    LoadCampaignsEvent event,
    Emitter<CampaignState> emit,
  ) async {
    emit(CampaignLoading());
    
    final result = await getCampaignsUseCase();
    
    result.fold(
      (failure) => emit(CampaignError(failure.message)),
      (campaigns) => emit(CampaignLoaded(campaigns)),
    );
  }
}
```

### Error Handling

**Use Either<Failure, Data> pattern:**
```dart
Future<Either<Failure, Campaign>> createCampaign(CampaignData data) async {
  try {
    final result = await remoteDataSource.createCampaign(data);
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  }
}
```

## Testing Guidelines

### Unit Tests

**Test use cases:**
```dart
void main() {
  late GetCampaignsUseCase useCase;
  late MockCampaignRepository mockRepository;
  
  setUp(() {
    mockRepository = MockCampaignRepository();
    useCase = GetCampaignsUseCase(mockRepository);
  });
  
  test('should get campaigns from repository', () async {
    // arrange
    final campaigns = [Campaign(id: '1', name: 'Test')];
    when(() => mockRepository.getCampaigns())
        .thenAnswer((_) async => Right(campaigns));
    
    // act
    final result = await useCase();
    
    // assert
    expect(result, Right(campaigns));
    verify(() => mockRepository.getCampaigns()).called(1);
  });
}
```

**Test BLoCs:**
```dart
void main() {
  late CampaignBloc bloc;
  late MockGetCampaignsUseCase mockUseCase;
  
  setUp(() {
    mockUseCase = MockGetCampaignsUseCase();
    bloc = CampaignBloc(mockUseCase);
  });
  
  blocTest<CampaignBloc, CampaignState>(
    'emits [Loading, Loaded] when campaigns are fetched successfully',
    build: () {
      when(() => mockUseCase()).thenAnswer(
        (_) async => Right([Campaign(id: '1', name: 'Test')]),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(LoadCampaignsEvent()),
    expect: () => [
      CampaignLoading(),
      CampaignLoaded([Campaign(id: '1', name: 'Test')]),
    ],
  );
}
```

### Widget Tests

```dart
void main() {
  testWidgets('displays campaign name', (tester) async {
    final campaign = Campaign(id: '1', name: 'Test Campaign');
    
    await tester.pumpWidget(
      MaterialApp(
        home: CampaignCard(campaign: campaign),
      ),
    );
    
    expect(find.text('Test Campaign'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
void main() {
  testWidgets('complete login flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Enter email
    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    
    // Enter password
    await tester.enterText(find.byType(TextField).last, 'password');
    
    // Tap login button
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    
    // Verify dashboard is shown
    expect(find.text('Good morning, Buyer!'), findsOneWidget);
  });
}
```

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

### Examples

```
feat(auth): add biometric authentication

- Implement fingerprint authentication
- Add face recognition support
- Update login flow

Closes #123
```

```
fix(campaign): resolve progress calculation error

The progress percentage was incorrect due to integer division.
Changed to use double division for accurate percentage.

Fixes #456
```

```
docs(readme): update installation instructions

Added missing Android SDK setup steps.
```

### Commit Best Practices

- Write clear, concise commit messages
- Use present tense ("add feature" not "added feature")
- Keep subject line under 50 characters
- Add detailed description in body if needed
- Reference issue numbers

## Pull Request Process

### Before Creating PR

1. ✅ Code follows style guidelines
2. ✅ Tests pass (`flutter test`)
3. ✅ Code analysis passes (`flutter analyze`)
4. ✅ Documentation updated
5. ✅ No merge conflicts
6. ✅ Branch up to date with develop

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Closes #123

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed

## Screenshots (if applicable)
Add screenshots here

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass
```

### Review Process

1. **Create PR** against `develop` branch
2. **Auto checks** must pass (CI/CD)
3. **Code review** by at least 1 team member
4. **Address feedback** and update PR
5. **Approval** required before merge
6. **Squash and merge** into develop

### Code Review Checklist

Reviewers should check:
- [ ] Code follows architecture guidelines
- [ ] Clean Architecture principles maintained
- [ ] BLoC pattern correctly implemented
- [ ] Error handling present
- [ ] Tests included and passing
- [ ] No hardcoded values (use constants)
- [ ] No sensitive data exposed
- [ ] Performance considerations
- [ ] UI/UX matches design
- [ ] Accessibility considered
- [ ] Documentation updated

## Additional Guidelines

### Performance

- Use const constructors
- Implement lazy loading
- Cache images
- Paginate large lists
- Debounce search inputs
- Dispose resources properly

### Security

- Never commit sensitive data
- Use secure storage for tokens
- Validate all inputs
- Trust server for calculations
- Use HTTPS only

### Accessibility

- Provide semantic labels
- Ensure sufficient contrast
- Support screen readers
- Test with TalkBack

### Documentation

- Comment complex logic
- Update README for major changes
- Document public APIs
- Keep CHANGELOG updated

## Questions?

If you have questions:
- Check ARCHITECTURE.md
- Check existing code
- Ask in team chat
- Create a GitHub issue

## License

By contributing, you agree that your contributions will be licensed under the project's license.

---

Thank you for contributing to Marketing Pro! 🚀
