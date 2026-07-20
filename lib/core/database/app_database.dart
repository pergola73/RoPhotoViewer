import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

part 'app_database.g.dart';

class Photos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fileName => text()();
  TextColumn get kdrivePath => text()();
  DateTimeColumn get dateTaken => dateTime()();
  TextColumn get localThumbnailPath => text().nullable()();
  TextColumn get localHighResPath => text().nullable()();
  TextColumn get remoteThumbnailUrl => text().nullable()();
  TextColumn get aiTags => text().map(const TagsConverter())(); // Slaat tags op als JSON string
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get locationName => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get mediaType => text().withDefault(const Constant('image'))();
  IntColumn get duration => integer().nullable()();
  TextColumn get cameraModel => text().nullable()();
  TextColumn get exposureTime => text().nullable()();
  TextColumn get fNumber => text().nullable()();
  IntColumn get iso => integer().nullable()();
  TextColumn get focalLength => text().nullable()();
  TextColumn get flash => text().nullable()();
  TextColumn get lensModel => text().nullable()();
  TextColumn get keywords => text().nullable()();
  TextColumn get people => text().nullable()(); // Namen van personen gescheiden door komma's
  TextColumn get kdriveFolderName => text().nullable()(); // NIEUW: Naam van de kDrive map
  TextColumn get kdriveFolderId => text().nullable()(); // NIEUW: ID van de kDrive map

  @override
  List<Index> get indices => [Index('idx_date_taken', 'CREATE INDEX idx_date_taken ON photos (date_taken);')];
}

class Persons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get faceSamplePath => text().nullable()(); // Pad naar een kleine uitsnede van het gezicht
}

class DetectedFaces extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get photoId => integer().references(Photos, #id)();
  IntColumn get personId => integer().nullable().references(Persons, #id)();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  TextColumn get faceThumbnailPath => text().nullable()();
  TextColumn get embedding => text().nullable()(); // JSON array van doubles
}

class Albums extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get coverPhotoId => integer().nullable().references(Photos, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class AlbumPhotos extends Table {
  IntColumn get albumId => integer().references(Albums, #id)();
  IntColumn get photoId => integer().references(Photos, #id)();
  
  @override
  Set<Column> get primaryKey => {albumId, photoId};
}

class FolderSync extends Table {
  TextColumn get folderId => text()();
  DateTimeColumn get lastSync => dateTime()();
  
  @override
  Set<Column> get primaryKey => {folderId};
}

class TagsConverter extends TypeConverter<List<String>, String> {
  const TagsConverter();
  @override
  List<String> fromSql(String fromDb) => fromDb.isEmpty ? [] : fromDb.split(',');
  @override
  String toSql(List<String> value) => value.join(',');
}

@DriftDatabase(tables: [Photos, Albums, AlbumPhotos, Persons, DetectedFaces, FolderSync])
class AppDatabase extends _$AppDatabase {
  // Singleton pattern om dubbele verbindingen te voorkomen
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  AppDatabase._internal() : super(_openConnection());

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // ... (bestaande stappen)
        if (from < 12) {
          await m.addColumn(photos, photos.kdriveFolderName);
          await m.addColumn(photos, photos.kdriveFolderId);
        }
        if (from < 13) {
          await m.createTable(folderSync);
        }
      },
    );
  }

  // Folder Sync Helper
  Future<DateTime?> getLastSyncForFolder(String folderId) async {
    final record = await (select(folderSync)..where((t) => t.folderId.equals(folderId))).getSingleOrNull();
    return record?.lastSync;
  }

  Future<void> updateLastSyncForFolder(String folderId) async {
    await into(folderSync).insert(
      FolderSyncCompanion.insert(folderId: folderId, lastSync: DateTime.now()),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> getPhotoCountForFolder(String folderId) {
    final countExp = photos.id.count();
    final query = selectOnly(photos)..addColumns([countExp]);
    query.where(photos.kdriveFolderId.equals(folderId));
    return query.map((row) => row.read(countExp)!).getSingle();
  }

  // Queries
  Future<int> getTotalPhotoCount({bool onlyFavorites = false}) {
    final countExp = photos.id.count();
    final query = selectOnly(photos)..addColumns([countExp]);
    if (onlyFavorites) {
      query.where(photos.isFavorite.equals(true));
    }
    return query.map((row) => row.read(countExp)! ).getSingle();
  }

  Future<List<Photo>> getAllPhotos() => (select(photos)..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)])).get();

  Future<Set<String>> getAllKdrivePaths() async {
    final query = selectOnly(photos)..addColumns([photos.kdrivePath]);
    final results = await query.map((row) => row.read(photos.kdrivePath)!).get();
    return results.toSet();
  }

  Future<List<Photo>> getPhotosWithoutThumbnails() {
    return (select(photos)..where((t) => t.localThumbnailPath.isNull())).get();
  }
  
  Future<List<Photo>> getPhotosPaged(int limit, int offset, {bool onlyFavorites = false}) {
    final query = select(photos);
    if (onlyFavorites) {
      query.where((t) => t.isFavorite.equals(true));
    }
    return (query
      ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)])
      ..limit(limit, offset: offset))
      .get();
  }

  Stream<List<Photo>> watchAllPhotos() => (select(photos)..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)])).watch();
  
  Future<List<Photo>> searchPhotos(String query) {
    final lowerQuery = query.toLowerCase();
    debugPrint('Database: Zoeken naar "$lowerQuery"...');
    return (select(photos)
      ..where((t) => 
        t.fileName.lower().contains(lowerQuery) | 
        t.aiTags.lower().contains(lowerQuery) | 
        t.locationName.lower().contains(lowerQuery) |
        t.keywords.lower().contains(lowerQuery) |
        t.people.lower().contains(lowerQuery)
      )
      ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)]))
      .get().then((results) {
        debugPrint('Database: ${results.length} resultaten gevonden voor "$lowerQuery"');
        return results;
      });
  }

  Future<Photo?> getPhotoByKdriveId(String id) {
    return (select(photos)..where((t) => t.kdrivePath.equals(id))).getSingleOrNull();
  }

  Future<int> savePhoto(PhotosCompanion entry) async {
    final id = await into(photos).insert(entry, mode: InsertMode.insertOrReplace);
    debugPrint('Database: Foto opgeslagen met ID $id (${entry.fileName.value})');
    return id;
  }

  Future updatePhotoTags(int id, List<String> tags) async {
    final photo = await (select(photos)..where((t) => t.id.equals(id))).getSingleOrNull();
    final Set<String> allTags = photo != null ? Set<String>.from(photo.aiTags) : {};
    allTags.addAll(tags.map((t) => t.trim().toLowerCase()).where((t) => t.length > 1));
    return (update(photos)..where((t) => t.id.equals(id))).write(
      PhotosCompanion(aiTags: Value(allTags.toList())),
    );
  }

  Future<void> clearDatabase() async {
    await delete(photos).go();
    await delete(albums).go();
    await delete(albumPhotos).go();
    await delete(persons).go();
    await delete(detectedFaces).go();
  }

  Future toggleFavorite(int id, bool isFavorite) {
    return (update(photos)..where((t) => t.id.equals(id))).write(
      PhotosCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future updatePhotoMetadata(int id, {DateTime? date, String? keywords}) {
    return (update(photos)..where((t) => t.id.equals(id))).write(
      PhotosCompanion(
        dateTaken: date != null ? Value(date) : const Value.absent(),
        keywords: keywords != null ? Value(keywords) : const Value.absent(),
      ),
    );
  }

  Future<void> deletePhoto(Photo photo) async {
    if (photo.localThumbnailPath != null) {
      final file = File(photo.localThumbnailPath!);
      if (await file.exists()) await file.delete();
    }
    if (photo.localHighResPath != null) {
      final file = File(photo.localHighResPath!);
      if (await file.exists()) await file.delete();
    }
    await (delete(albumPhotos)..where((t) => t.photoId.equals(photo.id))).go();
    await (delete(detectedFaces)..where((t) => t.photoId.equals(photo.id))).go();
    await (delete(photos)..where((t) => t.id.equals(photo.id))).go();
    debugPrint('Database: Foto ${photo.id} verwijderd.');
  }

  Future<List<Photo>> getFavorites() {
    return (select(photos)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)]))
      .get();
  }

  // Person & Face methods
  Future<int> getOrCreatePerson(String name, {String? faceSamplePath}) async {
    final existing = await (select(persons)..where((t) => t.name.equals(name))).getSingleOrNull();
    if (existing != null) return existing.id;

    return into(persons).insert(PersonsCompanion.insert(
      name: name,
      faceSamplePath: Value(faceSamplePath),
    ));
  }

  Future<List<Person>> getAllPersons() => select(persons).get();

  Future<void> addDetectedFace(DetectedFacesCompanion face) => into(detectedFaces).insert(face);

  Future<List<DetectedFace>> getFacesForPhoto(int photoId) {
    return (select(detectedFaces)..where((t) => t.photoId.equals(photoId))).get();
  }

  Future<void> assignPersonToFace(int faceId, int personId) {
    return (update(detectedFaces)..where((t) => t.id.equals(faceId))).write(
      DetectedFacesCompanion(personId: Value(personId)),
    );
  }

  Future<List<Photo>> getPhotosForPerson(int personId) async {
    final query = select(photos).join([
      innerJoin(detectedFaces, detectedFaces.photoId.equalsExp(photos.id)),
    ]) ..where(detectedFaces.personId.equals(personId));
    
    final rows = await query.get();
    return rows.map((row) => row.readTable(photos)).toList();
  }

  // Album methods
  Future<int> createAlbum(String name, {int? coverPhotoId}) {
    return into(albums).insert(AlbumsCompanion.insert(
      name: name,
      coverPhotoId: Value(coverPhotoId),
    ));
  }

  Future addPhotoToAlbum(int albumId, int photoId) {
    return into(albumPhotos).insert(AlbumPhotosCompanion(
      albumId: Value(albumId),
      photoId: Value(photoId),
    ), mode: InsertMode.insertOrIgnore);
  }

  Future<List<Album>> getAllAlbums() => select(albums).get();

  Stream<List<Album>> watchAllAlbums() => select(albums).watch();

  Future<List<Photo>> getPhotosInAlbum(int albumId) async {
    final query = select(photos).join([
      innerJoin(albumPhotos, albumPhotos.photoId.equalsExp(photos.id)),
    ]) ..where(albumPhotos.albumId.equals(albumId));
    
    final rows = await query.get();
    return rows.map((row) => row.readTable(photos)).toList();
  }

  Future deleteAlbum(int id) async {
    await (delete(albumPhotos)..where((t) => t.albumId.equals(id))).go();
    return (delete(albums)..where((t) => t.id.equals(id))).go();
  }

  Future removePhotoFromAlbum(int albumId, int photoId) {
    return (delete(albumPhotos)
      ..where((t) => t.albumId.equals(albumId) & t.photoId.equals(photoId)))
      .go();
  }

  Future updateAlbum(int id, String name, int? coverPhotoId) {
    return (update(albums)..where((t) => t.id.equals(id))).write(
      AlbumsCompanion(
        name: Value(name),
        coverPhotoId: Value(coverPhotoId),
      ),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
