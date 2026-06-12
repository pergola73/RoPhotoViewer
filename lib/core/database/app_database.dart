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

class TagsConverter extends TypeConverter<List<String>, String> {
  const TagsConverter();
  @override
  List<String> fromSql(String fromDb) => fromDb.isEmpty ? [] : fromDb.split(',');
  @override
  String toSql(List<String> value) => value.join(',');
}

@DriftDatabase(tables: [Photos, Albums, AlbumPhotos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(photos, photos.isFavorite);
          await m.addColumn(photos, photos.locationName);
          await m.addColumn(photos, photos.latitude);
          await m.addColumn(photos, photos.longitude);
        }
        if (from < 3) {
          await m.createTable(albums);
          await m.createTable(albumPhotos);
        }
      },
    );
  }

  // Queries
  Future<List<Photo>> getAllPhotos() => (select(photos)..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)])).get();
  
  Stream<List<Photo>> watchAllPhotos() => (select(photos)..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)])).watch();
  
  Future<List<Photo>> searchPhotos(String query) {
    return (select(photos)
      ..where((t) => t.fileName.contains(query) | t.aiTags.contains(query) | t.locationName.contains(query))
      ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)]))
      .get();
  }

  Future<Photo?> getPhotoByKdriveId(String id) {
    return (select(photos)..where((t) => t.kdrivePath.equals(id))).getSingleOrNull();
  }

  Future<int> savePhoto(PhotosCompanion entry) async {
    final id = await into(photos).insert(entry, mode: InsertMode.insertOrReplace);
    debugPrint('Database: Foto opgeslagen met ID $id (${entry.fileName.value})');
    return id;
  }

  Future updatePhotoTags(int id, List<String> tags) {
    return (update(photos)..where((t) => t.id.equals(id))).write(
      PhotosCompanion(aiTags: Value(tags)),
    );
  }

  Future<void> clearDatabase() async {
    await delete(photos).go();
    await delete(albums).go();
    await delete(albumPhotos).go();
  }

  Future toggleFavorite(int id, bool isFavorite) {
    return (update(photos)..where((t) => t.id.equals(id))).write(
      PhotosCompanion(isFavorite: Value(isFavorite)),
    );
  }

  Future<void> deletePhoto(Photo photo) async {
    // Verwijder lokale bestanden
    if (photo.localThumbnailPath != null) {
      final file = File(photo.localThumbnailPath!);
      if (await file.exists()) await file.delete();
    }
    if (photo.localHighResPath != null) {
      final file = File(photo.localHighResPath!);
      if (await file.exists()) await file.delete();
    }

    // Verwijder uit album relaties
    await (delete(albumPhotos)..where((t) => t.photoId.equals(photo.id))).go();
    
    // Verwijder uit database
    await (delete(photos)..where((t) => t.id.equals(photo.id))).go();
    debugPrint('Database: Foto ${photo.id} verwijderd.');
  }

  Future<List<Photo>> getFavorites() {
    return (select(photos)
      ..where((t) => t.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.dateTaken, mode: OrderingMode.desc)]))
      .get();
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
