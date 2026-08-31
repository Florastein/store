# Store App - Agent Architecture Guide

This document defines the mandatory architecture, conventions, and patterns for all agents working on this Flutter project.

---

## 🏗️ Core Architecture

### State Management: **Riverpod 2.x**
- **Providers**: `lib/providers/repositories.dart`
- **Pattern**: `AsyncNotifierProvider` for repositories with loading/error states
- **Consumption**: `ConsumerWidget` / `ConsumerStatefulWidget` with `WidgetRef`
- **No `context.watch` / `context.read`** - use `ref.watch` / `ref.read`

### Dependency Injection
- **Interfaces**: `lib/repositories/interfaces/*.dart`
- **Implementations**: `lib/repositories/*.dart`
- **Providers**: Single source of truth in `lib/providers/repositories.dart`
- **Constructor injection** for testability (e.g., `CacheManager` in `ProductRepositoryImpl`)

### Repository Pattern
```dart
// Interface (contract)
abstract class ProductRepository {
  List<StockItem> get products;
  Future<void> loadProducts();
  void add(StockItem item);
  // ...
}

// Implementation
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({CacheManager? cacheManager}); // injectable deps
  // ...
}
```

---

## 📁 File Structure Conventions

```
lib/
├── main.dart                    # Entry point, ProviderScope
├── providers/
│   └── repositories.dart        # All Riverpod providers
├── repositories/
│   ├── interfaces/              # Abstract contracts
│   │   ├── product_repository.dart
│   │   └── cart_repository.dart
│   ├── product_repository.dart  # Implementation
│   └── cart_repository.dart
├── services/                    # Business logic (no UI)
│   └── receipt_service.dart
├── models/
│   └── products_model.dart      # Pure data classes
├── pages/
│   ├── customer/                # Customer role UI
│   ├── shop/                    # Shop role UI (future)
│   └── auth/                    # Auth flows
├── widgets/                     # Reusable UI components
└── theme/
    └── app_colors.dart
```

---

## 🧪 Testing Requirements

### Unit Tests Location
```
test/
└── repositories/
    ├── product_repository_test.dart
    └── cart_repository_test.dart
```

### Test Patterns
- **Mock dependencies** with `mocktail`
- **Initialize binding**: `TestWidgetsFlutterBinding.ensureInitialized()`
- **Inject mocks** via constructor: `ProductRepositoryImpl(cacheManager: mockCacheManager)`
- **Test async behavior** with `async`/`await`
- **Coverage**: All public methods, edge cases, error paths

---

## 🎨 UI Conventions

### Widget Patterns
- **Stateless by default** - use `ConsumerWidget` for Riverpod
- **Extract widgets** > 50 lines into separate files
- **Const constructors** wherever possible
- **Relative imports** for `lib/` files: `import 'package:store/...'`

### Form Handling
- `GlobalKey<FormState>` + `TextFormField` validators
- `TextEditingController` + `FocusNode` with proper disposal
- Input formatters for phone/numbers

### Navigation
- `MaterialPageRoute` for standard flows
- `CupertinoPageRoute` for iOS-style transitions (login ↔ signup)
- `showModalBottomSheet` + `DraggableScrollableSheet` for pickers

---

## 🔐 Auth Architecture

### Two Role Flows
| Role | Entry | Completion Target |
|------|-------|-------------------|
| **Customer** | `CreateAccount` | `CustomerDashboard` |
| **Shop** | `CreateShopAccount` | `CreatePassword` (then shop dashboard) |

### Shared Components (DRY)
```
lib/pages/auth/
├── create_password.dart      # Shared
├── add_phone.dart            # Shared
├── verify_phone.dart         # Shared (shop imports this)
├── registration_complete.dart # Customer version
└── shop/
    ├── registration_complete.dart # Navigates to CreatePassword
    └── create_password.dart  # Shop version
```

### Auth State (Future)
- **Firebase Auth** with custom claims (`role: 'customer' | 'shop'`)
- **AuthRepository** interface for auth operations
- **Role-based routing** via `go_router`

---

## 💾 Data & Persistence

### Local Storage
- `SharedPreferences` for simple key-value (cart, products cache)
- **Keys**: `_storageKey` constants in repositories
- **JSON serialization**: `toJson()` / `fromJson()` on models

### Image Caching
- `cached_network_image` for UI display
- `flutter_cache_manager` for background precaching
- `CacheManager` injected into repository for testability

### Models
```dart
// Immutable with copyWith
class StockItem {
  const StockItem({required this.id, ...});
  final int id;
  // ...
  StockItem copyWith({int? id, ...});
  factory StockItem.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

---

## 🔧 Linting & Code Quality

### Analysis Options
- **File**: `analysis_options.yaml`
- **Strict rules enabled**: `prefer_const_constructors`, `prefer_final_fields`, `avoid_print`, etc.
- **Run before commit**: `flutter analyze`

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `product_repository.dart` |
| Classes | PascalCase | `ProductRepositoryImpl` |
| Variables/Methods | camelCase | `loadProducts()` |
| Constants | lowerCamelCase | `_storageKey` |
| Private | leading `_` | `_products` |

---

## 🚫 Forbidden Patterns

| Pattern | Reason | Alternative |
|---------|--------|-------------|
| `ChangeNotifier` + `Provider` | Replaced by Riverpod | `AsyncNotifierProvider` |
| `context.watch<T>()` | Not Riverpod | `ref.watch(provider)` |
| Direct singleton access (`Class.instance`) | Breaks DI/testability | Constructor injection via providers |
| Business logic in widgets | Untestable | Move to `services/` or repositories |
| `setState` in `ConsumerStatefulWidget` | Use Riverpod state | `ref.read(provider.notifier).method()` |
| Absolute imports for `lib/` | Breaks package resolution | `import 'package:store/...'` |

---

## 📦 Adding New Features

### New Repository
1. Create interface in `lib/repositories/interfaces/`
2. Create implementation in `lib/repositories/`
3. Add provider in `lib/providers/repositories.dart`
4. Write tests in `test/repositories/`
5. Update this AGENTS.md if new patterns emerge

### New Service
1. Create in `lib/services/`
2. Pure Dart (no Flutter deps if possible)
3. Inject dependencies via constructor
4. Consume via `ref.read(serviceProvider)` in UI

### New Page
1. Place in correct role folder: `pages/customer/` or `pages/shop/`
2. Use `ConsumerWidget` / `ConsumerStatefulWidget`
3. Access repos via `ref.read(repositoryProvider)`
4. Follow existing UI patterns (spacing, colors, fonts)

---

## 🔄 Git Workflow

### Commit Messages
```
type(scope): description

feat(auth): add shop registration flow
fix(cart): handle quantity edge case
test(repo): add cart repository tests
refactor(providers): extract cache manager injection
```

### Pre-commit Checks
```bash
flutter analyze
flutter test test/repositories/
flutter test # all tests
```

---

## 📋 Agent Checklist

When making changes, verify:
- [ ] Uses Riverpod providers (no `ChangeNotifier`)
- [ ] Interfaces for repositories/services
- [ ] Constructor injection for dependencies
- [ ] Unit tests for new logic
- [ ] `flutter analyze` passes
- [ ] Relative imports for `lib/`
- [ ] Const constructors where possible
- [ ] Proper disposal of controllers/nodes
- [ ] No business logic in widgets
- [ ] Follows existing naming conventions

---

## 🎯 Current Tech Stack

| Category | Package | Version |
|----------|---------|---------|
| State | `flutter_riverpod` | ^2.6.1 |
| DI | Built-in (providers) | - |
| Local Storage | `shared_preferences` | ^2.3.4 |
| Image Cache | `cached_network_image` + `flutter_cache_manager` | ^3.4.1 / ^3.4.1 |
| PDF | `pdf` | ^3.11.3 |
| Sharing | `share_plus` | ^13.3.0 |
| Fonts | `google_fonts` | ^8.1.0 |
| Icons | `hugeicons` | ^1.1.7 |
| Animations | `lottie` | ^3.3.3 |
| Firebase | `firebase_core`, `firebase_analytics`, `firebase_crashlytics` | ^3.15.2, ^11.4.0, ^4.3.0 |
| Testing | `mocktail` | ^1.0.4 |

---

*Update this file when architecture evolves. All agents must read this before contributing.*