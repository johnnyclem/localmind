---
name: flutter-feature-based-architecture
description: Design, implement, refactor, and review Flutter apps that use feature-based vertical slices, handwritten Dart models/providers, componentized StatelessWidget UI, Riverpod state management, and a shared core layer. Use when adding Flutter features, organizing lib/, moving shared code, wiring repositories/providers/routes, avoiding code generation, avoiding private UI build helper methods, or checking architecture consistency in a Riverpod Flutter project.
---

# Flutter Feature-Based Architecture

Use this skill to keep Flutter code organized by product capability instead of broad technical layers. Prefer vertical feature slices under `lib/features/`, keep stable cross-feature code in `lib/core/`, use Riverpod as the state boundary between UI and data access, write models/providers by hand, and split UI into small `StatelessWidget` components.

## First Pass

Before editing a project:

1. Inspect `pubspec.yaml`, `lib/`, route setup, serialization conventions, and existing Riverpod style.
2. Preserve coherent local conventions, especially folder names such as `repository/` vs `repositories/`, `components/` vs `widgets/`, and handwritten provider organization.
3. Prefer the smallest architecture change that solves the request.
4. State any dependency assumptions if Riverpod, routing, or serialization helpers are missing.
5. Run the project-standard checks after changes, usually `flutter analyze` and relevant tests.

## Target Shape

Use this default shape for new projects or features unless the existing project already has a consistent equivalent:

```text
lib/
├── app/                         # Optional app composition: shell, router, bootstrap
├── core/                        # Shared, cross-cutting concerns
│   ├── components/              # Reusable presentational widgets
│   ├── constants/               # App-wide constants and non-secret config
│   ├── extensions/              # Shared Dart extensions
│   ├── locales/                 # Localization setup and handwritten keys
│   ├── logger/                  # App-wide logging wrapper
│   ├── models/                  # Cross-feature models only
│   ├── providers/               # App-wide Riverpod providers
│   ├── repositories/            # Shared repositories and infrastructure services
│   ├── routes/                  # Route config if the app has no app/ layer
│   ├── theme/                   # ThemeData, text styles, component themes
│   └── utils/                   # General-purpose helpers
├── features/
│   └── orders/
│       ├── data/
│       │   ├── models/
│       │   └── repositories/
│       ├── providers/
│       └── views/
│           └── components/
└── main.dart
```

### Core Layer

Move code to `core/` only when it is genuinely app-wide or shared by multiple features. Keep feature-specific models, providers, repository methods, and UI components inside the owning feature until there is a stable reason to extract them.

Place composition code carefully:

- Let `main.dart`, `app/`, or `core/routes/` import feature entry pages to wire navigation.
- Do not let one feature import another feature directly.
- Move shared contracts, route constants, data types, or UI primitives to `core/` when two features need them.

## Feature Layer

Use this internal structure for each feature:

```text
features/<feature_name>/
├── data/
│   ├── models/                 # Feature-specific data/domain models
│   └── repositories/           # API, database, cache, and persistence access
├── providers/                  # Riverpod state, controllers, and query providers
└── views/
    ├── <feature>_page.dart     # Page/screen widgets
    └── components/             # Feature-only StatelessWidget components
```

Add optional folders only when they carry real weight:

| Folder | Use for |
| --- | --- |
| `data/datasources/` | Remote/local data source adapters when repositories would become too large |
| `data/dto/` | Transport-specific objects that should not leak into UI state |
| `services/` | Stateless feature services such as validators, schedulers, or mappers |
| `utils/` | Helpers that are private to one feature |

## Dependency Rules

- Import from `core/` and the current feature only.
- Do not import from sibling features. Extract shared code to `core/` instead.
- Keep views lean. Views handle layout, gestures, animation, navigation calls, and local-only UI concerns.
- Keep business rules, async work, persistence, and mutation orchestration in Riverpod notifiers/controllers or repositories.
- Keep repositories free of widget concerns. They should expose clear async APIs and translate data-source errors into app-level failures where the project has a failure type.
- Use `setState` only for strictly local ephemeral UI state. Do not use it for business data or cross-widget state.
- Do not split UI with private helper methods such as `_buildHeader`, `_buildBody`, `_buildList`, or `_buildItem`.
- Extract UI sections into named `StatelessWidget` classes under `views/components/` instead.

## Handwritten Dart Only

Do not introduce code generation for models, providers, routes, or serialization. Avoid `freezed`, `json_serializable`, `riverpod_annotation`, `build_runner`, generated `part` files, `.g.dart`, and `.freezed.dart` files unless the user explicitly asks for generated code.

When a project already contains generated files:

- Do not delete or rewrite existing generated architecture as part of an unrelated feature.
- Do not expand the generated surface for new work.
- Interact with existing generated APIs only when needed for compatibility.
- Ask before changing generator inputs if the task cannot be completed cleanly with handwritten Dart.

For handwritten models and state classes:

- Use immutable classes with `final` fields and `const` constructors where possible.
- Add `factory Model.fromJson(Map<String, dynamic> json)`, `Map<String, dynamic> toJson()`, and `copyWith()`.
- Add `==` and `hashCode` manually when value equality affects provider rebuilds, tests, collections, or state comparison.
- Keep parsing and serialization defensive enough for the app's data source.

## Riverpod Defaults

Prefer the project's existing Riverpod style when it is internally consistent. For new handwritten Riverpod code, prefer current Riverpod primitives:

| Need | Default |
| --- | --- |
| Repository/service dependency | `Provider<T>` |
| Simple local filter/toggle/query text | `StateProvider<T>` |
| Read-only one-shot async query | `FutureProvider<T>` |
| Read-only realtime data | `StreamProvider<T>` |
| Synchronous controller with mutable state | `NotifierProvider<Notifier, State>` |
| Async controller with loading/error/data state | `AsyncNotifierProvider<Notifier, State>` |
| Parameterized provider | `.family` |
| Screen-scoped state | `.autoDispose` |

Use `StateNotifierProvider` only when the project already standardizes on `StateNotifier` or dependency constraints require it.

### Provider Organization

In a feature's provider file, use this order:

1. Repository/service providers.
2. Simple filter or UI-state providers.
3. Query providers or notifier classes.
4. Provider declarations for controllers/notifiers.

Split a provider file when it becomes hard to scan, not just because a second provider exists. Prefer names that read naturally at call sites: `orderRepositoryProvider`, `orderSearchQueryProvider`, `orderListProvider`, `orderControllerProvider`.

### Async UI Rules

- Use `AsyncValue.when`, pattern matching, or project-standard helpers to render loading/error/data states.
- Use `ref.watch()` for reactive state in `build`.
- Use `ref.read()` for event handlers and one-shot actions.
- Use `ref.listen()` for side effects such as snackbars, dialogs, and redirects.
- Do not start network fetches, mutations, navigation, or provider invalidation from `build`, `itemBuilder`, or other repeatedly-called render callbacks.

## UI Composition

Use page widgets as thin state connectors. Prefer `ConsumerWidget` pages when Riverpod state is needed, and use `ConsumerStatefulWidget` only for unavoidable local lifecycle concerns such as controllers, focus nodes, or animations. Extracted UI sections should be `StatelessWidget` components by default.

Follow these rules:

- Keep each required widget `build` override focused on composing named widgets.
- Do not create private methods that return widgets for page sections.
- Move page sections, cards, list rows, empty states, form sections, buttons groups, and reusable layout pieces into `views/components/`.
- Pass plain data and callbacks into components instead of reading providers inside every component.
- Use `ConsumerWidget` in a component only when passing data/callbacks would create worse coupling or excessive plumbing.
- Promote a feature component to `core/components/` only after it is reused by multiple features.

## Feature Implementation Workflow

When adding a feature:

1. Create `lib/features/<feature_name>/` with `data/models/`, `data/repositories/`, `providers/`, and `views/`.
2. Define handwritten models with `fromJson`, `toJson`, `copyWith`, and manual equality when needed.
3. Implement the repository. Inject shared clients from `core/providers/` or `core/repositories/`; do not instantiate global dependencies deep in views.
4. Add Riverpod providers. Start with repository providers, then query/controller providers.
5. Implement views as thin `ConsumerWidget` shells, using `ConsumerStatefulWidget` only for unavoidable local lifecycle state, then extract UI sections into `StatelessWidget` files under `views/components/`.
6. Wire navigation in the existing composition layer.
7. Extract shared code to `core/` only after confirming it is cross-feature or app-wide.
8. Run formatting, static analysis, and focused tests.

## Naming

| Item | Convention | Example |
| --- | --- | --- |
| Feature directory | `snake_case` | `order_history/` |
| Model file | `snake_case` | `order_model.dart` |
| Repository file | `<feature>_repository.dart` | `orders_repository.dart` |
| Provider file | `<feature>_providers.dart` | `orders_providers.dart` |
| Page file | `<feature>_page.dart` or specific screen name | `orders_page.dart`, `order_details_page.dart` |
| Component file | `<component_name>.dart` | `orders_list.dart`, `order_summary_card.dart` |
| Component class | `PascalCase` widget name | `OrdersList`, `OrderSummaryCard` |
| Notifier/controller class | `PascalCase` + `Notifier` or `Controller` | `OrdersNotifier`, `OrderFormController` |
| State class | `PascalCase` + `State` | `OrdersState`, `OrderFormState` |
| Provider variable | `camelCase` + `Provider` | `ordersProvider`, `orderRepositoryProvider` |
| Barrel file | Directory summary name | `models.dart`, `components.dart` |

## Reference Files

Load reference files only when useful for the current task:

- Read [references/handwritten-feature-example.md](references/handwritten-feature-example.md) when implementing a concrete feature or when a full handwritten model, repository, provider, page, and component example would reduce ambiguity.
- Read [references/pagination-state-notifier-example.md](references/pagination-state-notifier-example.md) when implementing page-number pagination in a project that already uses `StateNotifierProvider`, or when the user asks for an indexed pagination controller pattern.
