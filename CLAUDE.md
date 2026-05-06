# yust
Firebase integration library for Dart/Flutter. Type-safe, reactive Firestore access with multi-tenancy, offline persistence, and platform abstraction (Flutter client + Dart server).

## Structure
`lib/src/models/` (YustDoc, YustDocSetup, YustFilter, YustUser, YustFile), `lib/src/services/` (database, auth, file, push — each with interface + platform-specific implementations), `lib/src/util/` (helpers, transforms, exceptions).

## Core Abstractions
- **YustDoc** — Base document class. Auto-tracks timestamps, audit trail, multi-tenancy (`envId`), change detection (`updateMask`).
- **YustDocSetup\<T\>** — Collection config: `collectionName`, `fromJson`, `forEnvironment`, `hasOwner`, `hasAuthor`, `onInit`, `onSave`.
- **YustFilter** — Query conditions: 12 comparators (equal, arrayContains, inList, etc.), nested field paths, client-side evaluation.
- **IYustDatabaseService** — Full CRUD + streams + transactions + aggregations + chunked reads.

## Platform Implementations
| Platform | Class | Backend |
|----------|-------|---------|
| Flutter | `YustDatabaseServiceFlutter` | `cloud_firestore` (FlutterFire) |
| Dart server/CLI | `YustDatabaseServiceDart` | `googleapis/firestore` REST API |
| Testing | `YustDatabaseServiceMocked` | In-memory `Map` |

Conditional import selects implementation automatically.

## Key Features
- **Multi-tenancy**: `forEnvironment: true` → subcollections per `envId`
- **Transactions**: `runTransactionForDocument()` with auto-retry (max 200 tries)
- **Field transforms**: Atomic increment, server timestamp, array operations
- **Aggregations**: `count()`, `sum()`, `avg()` via Firestore Aggregation API
- **Chunked streaming**: `getListChunked()` for memory-efficient large dataset processing
- **Caching**: Flutter has native offline persistence; `getFromCache()` vs `getFromDB()`
- **Database logging**: `dbLogCallback` for performance tracking
- **onChange hook**: Global document change handler

## Built-In Models
`YustUser` (auth + workspaces), `YustAddress`, `YustFile` (storage path + thumbnails), `YustImage`, `YustGeoLocation`, `YustNotification`.

## Initialization
```dart
final yust = Yust(forUI: true/false, useSubcollections: true, envCollectionName: 'workspaces');
await yust.initialize(projectId: '...', firebaseOptions/pathToServiceAccountJson: ...);
```

## Dependencies
`cloud_firestore`, `firebase_auth`, `firebase_storage`, `googleapis`, `googleapis_auth`, `firebase_core`, `json_annotation`, `collection`, `intl`, `crypto`.
