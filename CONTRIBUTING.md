# Contributing to Chimera Bridge 🦁🐍🐐

First off, thank you for considering contributing to Chimera Bridge! It's people like you that make the open-source community such a great place to build tools.

## 🧩 Project Structure

Chimera Bridge is a **Mason Brick**. Understanding how it works is key to contributing:

1. **`__brick__/`**: This contains the "blueprints." These are the templates for Kotlin, Swift, TypeScript, and Dart. We use Mustache syntax for logic.
2. **`hooks/pre_gen.dart`**: This is the "brain." It uses the `analyzer` package to parse Dart code and prepare the variables that the templates need.
3. **`brick.yaml`**: This defines the variables (like `agp_version` or `kotlin_version`) that users can pass in.

---

## 🛠️ How to Help

### Reporting Bugs

- Use the GitHub Issue Tracker.
- Provide a sample of the Dart `@ReactBridge` class that caused the issue.
- Include the error message from the native console (Logcat or Xcode).

### Feature Requests

- We are always looking to support more Dart types and complex Bridge patterns!
- Open an issue to discuss the logic before implementing it.

### Pull Requests

1. **Fork** the repo and create your branch from `main`.
2. If you change the templates in `__brick__`, ensure you update the corresponding logic in `pre_gen.dart`.
3. **Test your changes**:
    - Run `mason make chimera_bridge` against a test Dart file.
    - Verify that the generated Kotlin/Swift code compiles without manual fixes.
4. Ensure your code follows the [Dart Style Guide](https://dart.dev/guides/language/analysis-options).
5. Submit your PR with a clear description of what changed and why.

---

## 🧪 Development Workflow

To test your changes locally:

```bash
# 1. Make your changes in hooks/ or __brick__/
# 2. Navigate to your test Flutter/RN project
# 3. Run mason get (to refresh the brick)
# 4. Run mason make chimera_bridge --on-conflict overwrite
```

## 📜 Code of Conduct

By participating in this project, you agree to abide by its terms. Please be respectful and helpful to fellow contributors.

---

## ❤️ Acknowledgments

Your contributions help make Flutter and React Native work better together. Thank you to everyone who helps improve this bridge!

Maintained by **Karthik Gaddam**
