import '../features/notes/data/note_api.dart';
import '../features/notes/data/note_repository_impl.dart';
import '../features/reminders/data/reminder_api.dart';
import '../features/reminders/data/reminder_repository_impl.dart';
import '../features/sync/data/sync_api.dart';
import 'network/api_config.dart';
import 'network/dio_client.dart';
import 'storage/drift_db.dart';
import 'sync/sync_manager.dart';

class AppDI {
  AppDI._();

  static final db = AppDatabase();
  static final dioClient = DioClient(
    baseUrl: ApiConfig.baseUrl,
    apiPrefix: ApiConfig.apiPrefix,
    userId: ApiConfig.userId,
  );

  static final noteRepo = NoteRepositoryImpl(
    api: NoteApi(dioClient),
    db: db,
  );

  static final reminderRepo = ReminderRepositoryImpl(
    api: ReminderApi(dioClient),
    db: db,
  );

  static final syncManager = SyncManager(
    db: db,
    syncApi: SyncApi(dioClient),
  );
}
