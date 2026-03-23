# Contributing to FediSpace

Thanks for your interest in contributing to FediSpace! This guide will help you get started.

## Development Setup

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel, 3.x)
- [Android SDK](https://developer.android.com/studio) (API 21+)
- Java 17 (for Android builds)
- A Pixelfed instance account for testing

### Getting Started

```bash
# Clone the repository
git clone https://github.com/nathan-skynet/fedispace.git
cd fedispace

# Install dependencies
flutter pub get

# Run the app in debug mode
flutter run

# Build a debug APK
flutter build apk --debug
```

## Running Tests

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run a specific test file
flutter test test/models/account_test.dart

# Run static analysis
flutter analyze
```

## Code Style

FediSpace follows standard Dart conventions enforced by `flutter_lints`:

- Use `lowerCamelCase` for variables, functions, and parameters
- Use `UpperCamelCase` for classes, enums, and type parameters
- Use `lowercase_with_underscores` for file names
- Keep lines under 120 characters where reasonable
- Use trailing commas for better formatting with `dart format`
- Document public APIs with `///` doc comments

The project uses `analysis_options.yaml` at the root for lint rules. Run `flutter analyze` before submitting to catch issues early.

## Submitting Pull Requests

1. **Fork** the repository and create a feature branch from `master`:
   ```bash
   git checkout -b feat/your-feature
   ```

2. **Make your changes** following the code style above.

3. **Write tests** for new functionality in the `test/` directory.

4. **Run checks** before pushing:
   ```bash
   flutter analyze --no-fatal-infos
   flutter test
   ```

5. **Commit** with a descriptive message:
   ```bash
   git commit -m "feat: Add awesome new feature"
   ```
   Use conventional commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.

6. **Push** and open a PR against `master`.

7. **Describe** your changes in the PR using the provided template.

## Project Structure

```
lib/
  core/           # API client, auth, push notifications, logging, error handling
  l10n/           # Internationalization (16 languages)
  models/         # Data models (Account, Status, Story, etc.)
  routes/         # Pages and screens
  themes/         # Cyberpunk dark theme
  widgets/        # Reusable UI components
  main.dart       # App entry point

test/
  core/           # API, push, translation tests
  models/         # Model parsing tests

packages/         # Local packages (video player, vibrate, wakelock, etc.)
```

## Reporting Issues

Use the issue templates on GitHub:
- **Bug Report** -- include device info, steps to reproduce, and logs
- **Feature Request** -- describe the use case and expected behavior

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
