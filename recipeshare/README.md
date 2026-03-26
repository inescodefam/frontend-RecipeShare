# RecipeShare (Flutter monorepo)

Culinary recipe-sharing frontend: **mobile app** (iOS/Android) and **web admin** (Flutter Web), sharing code from `packages/shared`.

## Folder layout

| Path | Purpose |
|------|---------|
| `apps/mobile/` | End-user app entrypoint (`main.dart`). Depends on `shared`. |
| `apps/admin/` | Admin dashboard entrypoint. Depends on `shared`. |
| `packages/shared/` | **Single source of truth** for models, JSON contract, abstract service interfaces, mock implementations, design tokens/widgets used by both apps. |

## Why a monorepo?

One repository keeps **User**, **Recipe**, and API-shaped JSON in sync. When the .NET backend is ready, you add HTTP implementations next to the mock ones and change **one** DI registration line—screens stay unchanged.

## JSON → API contract

Mock files under `packages/shared/lib/mock_data/` define the shapes your backend should return. Share these filenames with the backend team as the reference contract.

| File | Suggested REST mapping (future) |
|------|----------------------------------|
| `users.json` | `GET/POST /users`, `GET /users/:id` |
| `recipes.json` | `GET /recipes`, `GET /recipes/:id`, `POST/PATCH/DELETE /recipes/:id` |
| `categories.json` | `GET /categories` |
| `tags.json` | `GET /tags` |
| `comments.json` | `GET/POST /recipes/:id/comments` |
| `likes.json` | `POST/DELETE /recipes/:id/likes` |
| `ratings.json` | `POST /recipes/:id/ratings` |
| `collections.json` | `GET/POST /users/:id/collections` |
| `reports.json` | `GET/POST /reports`, `PATCH /reports/:id` |
| `follows.json` | `POST/DELETE /users/:id/follow` |

## Running the apps

From `apps/mobile` or `apps/admin`:

```bash
flutter pub get
flutter run
```

Admin web:

```bash
cd apps/admin
flutter run -d chrome
```

## Workspace resolution

This repo uses **path dependencies** to `packages/shared` (works on all Flutter/Dart versions). Run `flutter pub get` in each app after cloning.
