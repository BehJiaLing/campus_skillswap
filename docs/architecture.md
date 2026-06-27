# Campus SkillSwap architecture

Campus SkillSwap uses an incremental, feature-first MVVM architecture. Existing
screens are migrated one feature at a time so active product work remains usable.

## Dependency direction

```text
View -> ViewModel -> Repository -> Service -> Firebase
```

- **Views** render state, collect input, and perform simple navigation.
- **ViewModels** validate input, coordinate user actions, and expose UI state.
- **Repositories** are the source of truth and convert backend records into typed
  application models.
- **Services** are stateless adapters around Firebase Auth, Firestore, Storage,
  Cloud Functions, notifications, or other external systems.
- **Models** are immutable typed values shared between repositories and
  ViewModels.
- **AppDependencies** is the composition root. It creates dependencies once and
  injects them into each feature.

Firebase SDK calls must not be added directly to new views.

## Project structure

```text
lib/
  app/                 # composition root, application and routing
  core/                # shared errors, result types, theme and utilities
  features/
    auth/
    profile/
    posts/
    matching/
    chat/
    ratings/
    rewards/
    admin/
      data/            # services and repositories
      models/          # immutable application models
      presentation/
        view_models/
        views/
        widgets/
```

All views now live inside their owning feature. Some legacy views still contain
Firebase access while their ViewModels and repositories are migrated; no new
Firebase calls may be added to those views.

## Core skill-exchange workflow

```text
open -> matched -> in_progress -> completed
  |          |             |
  +----------+-------------+-> cancelled
```

Only repositories or domain use-cases may perform a status transition. Views
must never update the status field directly.

The complete workflow is:

1. A student publishes a skill request.
2. Suitable helpers are ranked by skill, campus, availability, and rating.
3. Helpers offer assistance and the owner accepts one offer.
4. Acceptance creates the match and its chat atomically.
5. Participants track the exchange until completion.
6. Both participants can submit one rating and review.
7. Completion and valid ratings generate reward ledger entries.

## Rewards design

Reward balances must not be edited directly on a user document. Use an
append-only `reward_transactions` ledger and calculate or securely maintain the
balance from that ledger. Redemption creates a short-lived, single-use barcode
token. Issuing points and consuming redemption tokens should run in trusted
Cloud Functions or another server environment, not in the Flutter client.

Suggested collections:

```text
users/{userId}
posts/{postId}
posts/{postId}/offers/{offerId}
matches/{matchId}
chats/{chatId}/messages/{messageId}
ratings/{ratingId}
reward_transactions/{transactionId}
reward_redemptions/{redemptionId}
```

## Migration order

1. Posts and personal requests
2. Authentication and profile
3. Matching and offers
4. Chat
5. Ratings
6. Rewards and redemption
7. Admin features

Each migrated feature requires repository/ViewModel unit tests, widget tests for
important states, and Firebase Emulator integration tests for security rules.
