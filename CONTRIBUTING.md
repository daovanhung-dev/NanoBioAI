# Contributing to BioAI

First off, thank you for considering contributing to BioAI! 🎉

Following these guidelines helps communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Feature Requests](#feature-requests)

---

## Code of Conduct

This project adheres to a code of conduct. By participating, you are expected to uphold this code.

### Our Standards

- **Be respectful** and inclusive
- **Be collaborative** and constructive
- **Accept constructive criticism** gracefully
- **Focus on what's best** for the community

---

## Getting Started

### Prerequisites

1. **Flutter SDK** (>=3.9.2)
2. **Dart SDK** (>=3.0.0)
3. **Git**
4. Code editor (VS Code or Android Studio recommended)

### Setup Development Environment

```bash
# 1. Fork the repository on GitHub

# 2. Clone your fork
git clone https://github.com/YOUR-USERNAME/nano_app.git
cd nano_app

# 3. Add upstream remote
git remote add upstream https://github.com/original-org/nano_app.git

# 4. Install dependencies
flutter pub get

# 5. Setup environment
cp .env.example .env
# Edit .env with your API keys

# 6. Run the app
flutter run
```

---

## How to Contribute

### Types of Contributions

We welcome many types of contributions:

- 🐛 **Bug fixes**
- ✨ **New features**
- 📝 **Documentation improvements**
- 🎨 **UI/UX enhancements**
- ♿ **Accessibility improvements**
- 🧪 **Test coverage**
- 🌐 **Translations**
- 🔧 **Code refactoring**

---

## Development Workflow

### 1. Create a Branch

Always create a new branch for your work:

```bash
# For new features
git checkout -b feature/your-feature-name

# For bug fixes
git checkout -b fix/bug-description

# For documentation
git checkout -b docs/what-you-are-documenting

# For refactoring
git checkout -b refactor/what-you-are-refactoring
```

### 2. Make Your Changes

- Write clean, readable code
- Follow the [coding standards](#coding-standards)
- Add tests for new features
- Update documentation as needed

### 3. Test Your Changes

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/path/to/test_file.dart

# Check for lint errors
flutter analyze

# Format code
flutter format .

# Run the app to verify
flutter run
```

### 4. Commit Your Changes

Follow our [commit message conventions](#commit-messages):

```bash
git add .
git commit -m "feat: add user profile feature"
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## Coding Standards

### Dart Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

#### Naming Conventions

```dart
// Classes: UpperCamelCase
class UserProfile { }

// Variables, functions: lowerCamelCase
int userCount = 0;
void getUserData() { }

// Constants: lowerCamelCase
const maxRetries = 3;

// Private members: prefix with underscore
int _privateField;
void _privateMethod() { }
```

#### Code Organization

```dart
// Order of class members:
class Example {
  // 1. Static constants
  static const String constantValue = 'value';
  
  // 2. Static variables
  static int staticVar = 0;
  
  // 3. Instance variables
  final String publicField;
  int _privateField;
  
  // 4. Constructors
  const Example(this.publicField);
  
  // 5. Getters/Setters
  int get value => _privateField;
  set value(int v) => _privateField = v;
  
  // 6. Public methods
  void publicMethod() { }
  
  // 7. Private methods
  void _privateMethod() { }
}
```

#### Comments

```dart
/// Documentation comment for public APIs
/// 
/// Use triple slashes for dartdoc.
/// Explain what the function does, parameters, and return value.
int calculateBMI(double weight, double height) {
  // Regular comments for implementation details
  return (weight / (height * height)).round();
}
```

### Flutter Best Practices

#### Widget Structure

```dart
class MyWidget extends StatelessWidget {
  const MyWidget({super.key, required this.title});
  
  final String title;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // Prefer const constructors
      child: const Text('Hello'),
    );
  }
}
```

#### State Management (Riverpod)

```dart
// Provider definition
final counterProvider = StateNotifierProvider<CounterNotifier, int>(
  (ref) => CounterNotifier(),
);

// Notifier implementation
class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);
  
  void increment() => state++;
}

// Usage in widget
class CounterWidget extends ConsumerWidget {
  const CounterWidget({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

### Design System Usage

Always use design system tokens and primitives:

```dart
// ✅ GOOD - Use design system
import 'package:nano_app/core/theme/design_system.dart';

Container(
  color: AppColorTokens.surface,
  padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
  child: AppButton(
    variant: ButtonVariant.primary,
    onPressed: () {},
    child: Text('Save'),
  ),
)

// ❌ BAD - Hardcoded values
Container(
  color: Color(0xFFFFFFFF),
  padding: EdgeInsets.all(16),
  child: ElevatedButton(
    onPressed: () {},
    child: Text('Save'),
  ),
)
```

---

## Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates
- `ci`: CI/CD changes
- `revert`: Revert previous commit

### Examples

```bash
# Feature
git commit -m "feat(auth): add Google sign-in"

# Bug fix
git commit -m "fix(dashboard): resolve BMI calculation error"

# Documentation
git commit -m "docs(readme): update installation instructions"

# Refactoring
git commit -m "refactor(onboarding): extract common widgets"

# Breaking change
git commit -m "feat(api)!: change meal plan response format

BREAKING CHANGE: meal plan API now returns nested structure"
```

### Scope

Use feature names as scope:
- `auth`
- `onboarding`
- `dashboard`
- `meal-plan`
- `ai-chat`
- `design-system`

---

## Pull Request Process

### Before Submitting

- [ ] Code compiles without errors
- [ ] All tests pass (`flutter test`)
- [ ] No lint warnings (`flutter analyze`)
- [ ] Code is formatted (`flutter format .`)
- [ ] Documentation updated
- [ ] Self-reviewed the code
- [ ] Added/updated tests

### PR Title

Use the same format as commit messages:

```
feat(auth): add biometric authentication
fix(meal-plan): resolve date picker crash
docs(contributing): add PR checklist
```

### PR Description Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change)
- [ ] New feature (non-breaking change)
- [ ] Breaking change (fix or feature that breaks existing functionality)
- [ ] Documentation update

## Related Issues
Fixes #123
Closes #456

## Screenshots (if applicable)
Before | After
-------|-------
![before](url) | ![after](url)

## Testing
- [ ] Tested on Android
- [ ] Tested on iOS
- [ ] Added unit tests
- [ ] Added integration tests

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally
```

### Review Process

1. **Automated Checks**: CI/CD runs tests and lint
2. **Code Review**: Maintainers review your code
3. **Feedback**: Address review comments
4. **Approval**: Once approved, PR will be merged
5. **Merge**: Squash and merge into main branch

---

## Reporting Bugs

### Before Submitting a Bug Report

- Check if it's already reported in [Issues](https://github.com/org/nano_app/issues)
- Try to reproduce with latest version
- Collect relevant information

### Bug Report Template

```markdown
## Bug Description
Clear and concise description of the bug.

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. Scroll down to '...'
4. See error

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Screenshots
If applicable, add screenshots.

## Environment
- Device: [e.g., Pixel 6]
- OS: [e.g., Android 13]
- App Version: [e.g., 0.1.0]
- Flutter Version: [e.g., 3.9.2]

## Additional Context
Any other relevant information.

## Possible Solution (optional)
Ideas on how to fix the issue.
```

---

## Feature Requests

### Before Submitting a Feature Request

- Check if it's already requested
- Make sure it aligns with project goals
- Consider if it benefits most users

### Feature Request Template

```markdown
## Feature Description
Clear and concise description of the feature.

## Problem It Solves
What problem does this feature address?

## Proposed Solution
How should this feature work?

## Alternatives Considered
What alternative solutions did you consider?

## Additional Context
Mockups, examples, or other relevant information.

## Priority
- [ ] Critical
- [ ] High
- [ ] Medium
- [ ] Low
```

---

## Questions?

If you have questions, you can:

1. Check existing [documentation](../README.md)
2. Search [GitHub Issues](https://github.com/org/nano_app/issues)
3. Ask in [GitHub Discussions](https://github.com/org/nano_app/discussions)
4. Email: dev@bioai.com

---

## Recognition

Contributors will be recognized in:
- **README.md** - Contributors section
- **Release notes** - For significant contributions
- **Project credits** - For major features

---

Thank you for contributing to BioAI! 🙏❤️

Every contribution, no matter how small, makes a difference.
