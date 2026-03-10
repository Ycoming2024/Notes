# notes_bridge

Flutter client for Notes backend.

## API config

Default API base URL:

`https://ycoming.top`

Default API prefix:

`/notes-api/v1`

You can override it at runtime with dart-define:

- `API_BASE_URL`
- `API_PREFIX`
- `API_USER_ID`

Example:

```bash
flutter run -d windows --dart-define=API_BASE_URL=https://ycoming.top --dart-define=API_PREFIX=/notes-api/v1 --dart-define=API_USER_ID=demo-user-id
```

## Run commands

Windows:

```bash
flutter run -d windows --dart-define=API_BASE_URL=https://ycoming.top
```

Android:

```bash
flutter run -d android --dart-define=API_BASE_URL=https://ycoming.top
```

Release APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://ycoming.top
```
