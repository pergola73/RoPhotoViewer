// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kdrivePathMeta = const VerificationMeta(
    'kdrivePath',
  );
  @override
  late final GeneratedColumn<String> kdrivePath = GeneratedColumn<String>(
    'kdrive_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateTakenMeta = const VerificationMeta(
    'dateTaken',
  );
  @override
  late final GeneratedColumn<DateTime> dateTaken = GeneratedColumn<DateTime>(
    'date_taken',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localThumbnailPathMeta =
      const VerificationMeta('localThumbnailPath');
  @override
  late final GeneratedColumn<String> localThumbnailPath =
      GeneratedColumn<String>(
        'local_thumbnail_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localHighResPathMeta = const VerificationMeta(
    'localHighResPath',
  );
  @override
  late final GeneratedColumn<String> localHighResPath = GeneratedColumn<String>(
    'local_high_res_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteThumbnailUrlMeta =
      const VerificationMeta('remoteThumbnailUrl');
  @override
  late final GeneratedColumn<String> remoteThumbnailUrl =
      GeneratedColumn<String>(
        'remote_thumbnail_url',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> aiTags =
      GeneratedColumn<String>(
        'ai_tags',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<List<String>>($PhotosTable.$converteraiTags);
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('image'),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cameraModelMeta = const VerificationMeta(
    'cameraModel',
  );
  @override
  late final GeneratedColumn<String> cameraModel = GeneratedColumn<String>(
    'camera_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exposureTimeMeta = const VerificationMeta(
    'exposureTime',
  );
  @override
  late final GeneratedColumn<String> exposureTime = GeneratedColumn<String>(
    'exposure_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fNumberMeta = const VerificationMeta(
    'fNumber',
  );
  @override
  late final GeneratedColumn<String> fNumber = GeneratedColumn<String>(
    'f_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isoMeta = const VerificationMeta('iso');
  @override
  late final GeneratedColumn<int> iso = GeneratedColumn<int>(
    'iso',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _focalLengthMeta = const VerificationMeta(
    'focalLength',
  );
  @override
  late final GeneratedColumn<String> focalLength = GeneratedColumn<String>(
    'focal_length',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flashMeta = const VerificationMeta('flash');
  @override
  late final GeneratedColumn<String> flash = GeneratedColumn<String>(
    'flash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lensModelMeta = const VerificationMeta(
    'lensModel',
  );
  @override
  late final GeneratedColumn<String> lensModel = GeneratedColumn<String>(
    'lens_model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keywordsMeta = const VerificationMeta(
    'keywords',
  );
  @override
  late final GeneratedColumn<String> keywords = GeneratedColumn<String>(
    'keywords',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _textOCRMeta = const VerificationMeta(
    'textOCR',
  );
  @override
  late final GeneratedColumn<String> textOCR = GeneratedColumn<String>(
    'text_o_c_r',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _peopleMeta = const VerificationMeta('people');
  @override
  late final GeneratedColumn<String> people = GeneratedColumn<String>(
    'people',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kdriveFolderNameMeta = const VerificationMeta(
    'kdriveFolderName',
  );
  @override
  late final GeneratedColumn<String> kdriveFolderName = GeneratedColumn<String>(
    'kdrive_folder_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kdriveFolderIdMeta = const VerificationMeta(
    'kdriveFolderId',
  );
  @override
  late final GeneratedColumn<String> kdriveFolderId = GeneratedColumn<String>(
    'kdrive_folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fileName,
    kdrivePath,
    dateTaken,
    localThumbnailPath,
    localHighResPath,
    remoteThumbnailUrl,
    aiTags,
    isFavorite,
    locationName,
    latitude,
    longitude,
    mediaType,
    duration,
    cameraModel,
    exposureTime,
    fNumber,
    iso,
    focalLength,
    flash,
    lensModel,
    keywords,
    textOCR,
    people,
    kdriveFolderName,
    kdriveFolderId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('kdrive_path')) {
      context.handle(
        _kdrivePathMeta,
        kdrivePath.isAcceptableOrUnknown(data['kdrive_path']!, _kdrivePathMeta),
      );
    } else if (isInserting) {
      context.missing(_kdrivePathMeta);
    }
    if (data.containsKey('date_taken')) {
      context.handle(
        _dateTakenMeta,
        dateTaken.isAcceptableOrUnknown(data['date_taken']!, _dateTakenMeta),
      );
    } else if (isInserting) {
      context.missing(_dateTakenMeta);
    }
    if (data.containsKey('local_thumbnail_path')) {
      context.handle(
        _localThumbnailPathMeta,
        localThumbnailPath.isAcceptableOrUnknown(
          data['local_thumbnail_path']!,
          _localThumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('local_high_res_path')) {
      context.handle(
        _localHighResPathMeta,
        localHighResPath.isAcceptableOrUnknown(
          data['local_high_res_path']!,
          _localHighResPathMeta,
        ),
      );
    }
    if (data.containsKey('remote_thumbnail_url')) {
      context.handle(
        _remoteThumbnailUrlMeta,
        remoteThumbnailUrl.isAcceptableOrUnknown(
          data['remote_thumbnail_url']!,
          _remoteThumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('camera_model')) {
      context.handle(
        _cameraModelMeta,
        cameraModel.isAcceptableOrUnknown(
          data['camera_model']!,
          _cameraModelMeta,
        ),
      );
    }
    if (data.containsKey('exposure_time')) {
      context.handle(
        _exposureTimeMeta,
        exposureTime.isAcceptableOrUnknown(
          data['exposure_time']!,
          _exposureTimeMeta,
        ),
      );
    }
    if (data.containsKey('f_number')) {
      context.handle(
        _fNumberMeta,
        fNumber.isAcceptableOrUnknown(data['f_number']!, _fNumberMeta),
      );
    }
    if (data.containsKey('iso')) {
      context.handle(
        _isoMeta,
        iso.isAcceptableOrUnknown(data['iso']!, _isoMeta),
      );
    }
    if (data.containsKey('focal_length')) {
      context.handle(
        _focalLengthMeta,
        focalLength.isAcceptableOrUnknown(
          data['focal_length']!,
          _focalLengthMeta,
        ),
      );
    }
    if (data.containsKey('flash')) {
      context.handle(
        _flashMeta,
        flash.isAcceptableOrUnknown(data['flash']!, _flashMeta),
      );
    }
    if (data.containsKey('lens_model')) {
      context.handle(
        _lensModelMeta,
        lensModel.isAcceptableOrUnknown(data['lens_model']!, _lensModelMeta),
      );
    }
    if (data.containsKey('keywords')) {
      context.handle(
        _keywordsMeta,
        keywords.isAcceptableOrUnknown(data['keywords']!, _keywordsMeta),
      );
    }
    if (data.containsKey('text_o_c_r')) {
      context.handle(
        _textOCRMeta,
        textOCR.isAcceptableOrUnknown(data['text_o_c_r']!, _textOCRMeta),
      );
    }
    if (data.containsKey('people')) {
      context.handle(
        _peopleMeta,
        people.isAcceptableOrUnknown(data['people']!, _peopleMeta),
      );
    }
    if (data.containsKey('kdrive_folder_name')) {
      context.handle(
        _kdriveFolderNameMeta,
        kdriveFolderName.isAcceptableOrUnknown(
          data['kdrive_folder_name']!,
          _kdriveFolderNameMeta,
        ),
      );
    }
    if (data.containsKey('kdrive_folder_id')) {
      context.handle(
        _kdriveFolderIdMeta,
        kdriveFolderId.isAcceptableOrUnknown(
          data['kdrive_folder_id']!,
          _kdriveFolderIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      kdrivePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kdrive_path'],
      )!,
      dateTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date_taken'],
      )!,
      localThumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_thumbnail_path'],
      ),
      localHighResPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_high_res_path'],
      ),
      remoteThumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_thumbnail_url'],
      ),
      aiTags: $PhotosTable.$converteraiTags.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}ai_tags'],
        )!,
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration'],
      ),
      cameraModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}camera_model'],
      ),
      exposureTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exposure_time'],
      ),
      fNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}f_number'],
      ),
      iso: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iso'],
      ),
      focalLength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}focal_length'],
      ),
      flash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flash'],
      ),
      lensModel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lens_model'],
      ),
      keywords: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keywords'],
      ),
      textOCR: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_o_c_r'],
      ),
      people: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}people'],
      ),
      kdriveFolderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kdrive_folder_name'],
      ),
      kdriveFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kdrive_folder_id'],
      ),
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converteraiTags =
      const TagsConverter();
}

class Photo extends DataClass implements Insertable<Photo> {
  final int id;
  final String fileName;
  final String kdrivePath;
  final DateTime dateTaken;
  final String? localThumbnailPath;
  final String? localHighResPath;
  final String? remoteThumbnailUrl;
  final List<String> aiTags;
  final bool isFavorite;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final String mediaType;
  final int? duration;
  final String? cameraModel;
  final String? exposureTime;
  final String? fNumber;
  final int? iso;
  final String? focalLength;
  final String? flash;
  final String? lensModel;
  final String? keywords;
  final String? textOCR;
  final String? people;
  final String? kdriveFolderName;
  final String? kdriveFolderId;
  const Photo({
    required this.id,
    required this.fileName,
    required this.kdrivePath,
    required this.dateTaken,
    this.localThumbnailPath,
    this.localHighResPath,
    this.remoteThumbnailUrl,
    required this.aiTags,
    required this.isFavorite,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.mediaType,
    this.duration,
    this.cameraModel,
    this.exposureTime,
    this.fNumber,
    this.iso,
    this.focalLength,
    this.flash,
    this.lensModel,
    this.keywords,
    this.textOCR,
    this.people,
    this.kdriveFolderName,
    this.kdriveFolderId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['file_name'] = Variable<String>(fileName);
    map['kdrive_path'] = Variable<String>(kdrivePath);
    map['date_taken'] = Variable<DateTime>(dateTaken);
    if (!nullToAbsent || localThumbnailPath != null) {
      map['local_thumbnail_path'] = Variable<String>(localThumbnailPath);
    }
    if (!nullToAbsent || localHighResPath != null) {
      map['local_high_res_path'] = Variable<String>(localHighResPath);
    }
    if (!nullToAbsent || remoteThumbnailUrl != null) {
      map['remote_thumbnail_url'] = Variable<String>(remoteThumbnailUrl);
    }
    {
      map['ai_tags'] = Variable<String>(
        $PhotosTable.$converteraiTags.toSql(aiTags),
      );
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['media_type'] = Variable<String>(mediaType);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || cameraModel != null) {
      map['camera_model'] = Variable<String>(cameraModel);
    }
    if (!nullToAbsent || exposureTime != null) {
      map['exposure_time'] = Variable<String>(exposureTime);
    }
    if (!nullToAbsent || fNumber != null) {
      map['f_number'] = Variable<String>(fNumber);
    }
    if (!nullToAbsent || iso != null) {
      map['iso'] = Variable<int>(iso);
    }
    if (!nullToAbsent || focalLength != null) {
      map['focal_length'] = Variable<String>(focalLength);
    }
    if (!nullToAbsent || flash != null) {
      map['flash'] = Variable<String>(flash);
    }
    if (!nullToAbsent || lensModel != null) {
      map['lens_model'] = Variable<String>(lensModel);
    }
    if (!nullToAbsent || keywords != null) {
      map['keywords'] = Variable<String>(keywords);
    }
    if (!nullToAbsent || textOCR != null) {
      map['text_o_c_r'] = Variable<String>(textOCR);
    }
    if (!nullToAbsent || people != null) {
      map['people'] = Variable<String>(people);
    }
    if (!nullToAbsent || kdriveFolderName != null) {
      map['kdrive_folder_name'] = Variable<String>(kdriveFolderName);
    }
    if (!nullToAbsent || kdriveFolderId != null) {
      map['kdrive_folder_id'] = Variable<String>(kdriveFolderId);
    }
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      fileName: Value(fileName),
      kdrivePath: Value(kdrivePath),
      dateTaken: Value(dateTaken),
      localThumbnailPath: localThumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localThumbnailPath),
      localHighResPath: localHighResPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localHighResPath),
      remoteThumbnailUrl: remoteThumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteThumbnailUrl),
      aiTags: Value(aiTags),
      isFavorite: Value(isFavorite),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      mediaType: Value(mediaType),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      cameraModel: cameraModel == null && nullToAbsent
          ? const Value.absent()
          : Value(cameraModel),
      exposureTime: exposureTime == null && nullToAbsent
          ? const Value.absent()
          : Value(exposureTime),
      fNumber: fNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(fNumber),
      iso: iso == null && nullToAbsent ? const Value.absent() : Value(iso),
      focalLength: focalLength == null && nullToAbsent
          ? const Value.absent()
          : Value(focalLength),
      flash: flash == null && nullToAbsent
          ? const Value.absent()
          : Value(flash),
      lensModel: lensModel == null && nullToAbsent
          ? const Value.absent()
          : Value(lensModel),
      keywords: keywords == null && nullToAbsent
          ? const Value.absent()
          : Value(keywords),
      textOCR: textOCR == null && nullToAbsent
          ? const Value.absent()
          : Value(textOCR),
      people: people == null && nullToAbsent
          ? const Value.absent()
          : Value(people),
      kdriveFolderName: kdriveFolderName == null && nullToAbsent
          ? const Value.absent()
          : Value(kdriveFolderName),
      kdriveFolderId: kdriveFolderId == null && nullToAbsent
          ? const Value.absent()
          : Value(kdriveFolderId),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<int>(json['id']),
      fileName: serializer.fromJson<String>(json['fileName']),
      kdrivePath: serializer.fromJson<String>(json['kdrivePath']),
      dateTaken: serializer.fromJson<DateTime>(json['dateTaken']),
      localThumbnailPath: serializer.fromJson<String?>(
        json['localThumbnailPath'],
      ),
      localHighResPath: serializer.fromJson<String?>(json['localHighResPath']),
      remoteThumbnailUrl: serializer.fromJson<String?>(
        json['remoteThumbnailUrl'],
      ),
      aiTags: serializer.fromJson<List<String>>(json['aiTags']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      duration: serializer.fromJson<int?>(json['duration']),
      cameraModel: serializer.fromJson<String?>(json['cameraModel']),
      exposureTime: serializer.fromJson<String?>(json['exposureTime']),
      fNumber: serializer.fromJson<String?>(json['fNumber']),
      iso: serializer.fromJson<int?>(json['iso']),
      focalLength: serializer.fromJson<String?>(json['focalLength']),
      flash: serializer.fromJson<String?>(json['flash']),
      lensModel: serializer.fromJson<String?>(json['lensModel']),
      keywords: serializer.fromJson<String?>(json['keywords']),
      textOCR: serializer.fromJson<String?>(json['textOCR']),
      people: serializer.fromJson<String?>(json['people']),
      kdriveFolderName: serializer.fromJson<String?>(json['kdriveFolderName']),
      kdriveFolderId: serializer.fromJson<String?>(json['kdriveFolderId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fileName': serializer.toJson<String>(fileName),
      'kdrivePath': serializer.toJson<String>(kdrivePath),
      'dateTaken': serializer.toJson<DateTime>(dateTaken),
      'localThumbnailPath': serializer.toJson<String?>(localThumbnailPath),
      'localHighResPath': serializer.toJson<String?>(localHighResPath),
      'remoteThumbnailUrl': serializer.toJson<String?>(remoteThumbnailUrl),
      'aiTags': serializer.toJson<List<String>>(aiTags),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'locationName': serializer.toJson<String?>(locationName),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'mediaType': serializer.toJson<String>(mediaType),
      'duration': serializer.toJson<int?>(duration),
      'cameraModel': serializer.toJson<String?>(cameraModel),
      'exposureTime': serializer.toJson<String?>(exposureTime),
      'fNumber': serializer.toJson<String?>(fNumber),
      'iso': serializer.toJson<int?>(iso),
      'focalLength': serializer.toJson<String?>(focalLength),
      'flash': serializer.toJson<String?>(flash),
      'lensModel': serializer.toJson<String?>(lensModel),
      'keywords': serializer.toJson<String?>(keywords),
      'textOCR': serializer.toJson<String?>(textOCR),
      'people': serializer.toJson<String?>(people),
      'kdriveFolderName': serializer.toJson<String?>(kdriveFolderName),
      'kdriveFolderId': serializer.toJson<String?>(kdriveFolderId),
    };
  }

  Photo copyWith({
    int? id,
    String? fileName,
    String? kdrivePath,
    DateTime? dateTaken,
    Value<String?> localThumbnailPath = const Value.absent(),
    Value<String?> localHighResPath = const Value.absent(),
    Value<String?> remoteThumbnailUrl = const Value.absent(),
    List<String>? aiTags,
    bool? isFavorite,
    Value<String?> locationName = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    String? mediaType,
    Value<int?> duration = const Value.absent(),
    Value<String?> cameraModel = const Value.absent(),
    Value<String?> exposureTime = const Value.absent(),
    Value<String?> fNumber = const Value.absent(),
    Value<int?> iso = const Value.absent(),
    Value<String?> focalLength = const Value.absent(),
    Value<String?> flash = const Value.absent(),
    Value<String?> lensModel = const Value.absent(),
    Value<String?> keywords = const Value.absent(),
    Value<String?> textOCR = const Value.absent(),
    Value<String?> people = const Value.absent(),
    Value<String?> kdriveFolderName = const Value.absent(),
    Value<String?> kdriveFolderId = const Value.absent(),
  }) => Photo(
    id: id ?? this.id,
    fileName: fileName ?? this.fileName,
    kdrivePath: kdrivePath ?? this.kdrivePath,
    dateTaken: dateTaken ?? this.dateTaken,
    localThumbnailPath: localThumbnailPath.present
        ? localThumbnailPath.value
        : this.localThumbnailPath,
    localHighResPath: localHighResPath.present
        ? localHighResPath.value
        : this.localHighResPath,
    remoteThumbnailUrl: remoteThumbnailUrl.present
        ? remoteThumbnailUrl.value
        : this.remoteThumbnailUrl,
    aiTags: aiTags ?? this.aiTags,
    isFavorite: isFavorite ?? this.isFavorite,
    locationName: locationName.present ? locationName.value : this.locationName,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    mediaType: mediaType ?? this.mediaType,
    duration: duration.present ? duration.value : this.duration,
    cameraModel: cameraModel.present ? cameraModel.value : this.cameraModel,
    exposureTime: exposureTime.present ? exposureTime.value : this.exposureTime,
    fNumber: fNumber.present ? fNumber.value : this.fNumber,
    iso: iso.present ? iso.value : this.iso,
    focalLength: focalLength.present ? focalLength.value : this.focalLength,
    flash: flash.present ? flash.value : this.flash,
    lensModel: lensModel.present ? lensModel.value : this.lensModel,
    keywords: keywords.present ? keywords.value : this.keywords,
    textOCR: textOCR.present ? textOCR.value : this.textOCR,
    people: people.present ? people.value : this.people,
    kdriveFolderName: kdriveFolderName.present
        ? kdriveFolderName.value
        : this.kdriveFolderName,
    kdriveFolderId: kdriveFolderId.present
        ? kdriveFolderId.value
        : this.kdriveFolderId,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      kdrivePath: data.kdrivePath.present
          ? data.kdrivePath.value
          : this.kdrivePath,
      dateTaken: data.dateTaken.present ? data.dateTaken.value : this.dateTaken,
      localThumbnailPath: data.localThumbnailPath.present
          ? data.localThumbnailPath.value
          : this.localThumbnailPath,
      localHighResPath: data.localHighResPath.present
          ? data.localHighResPath.value
          : this.localHighResPath,
      remoteThumbnailUrl: data.remoteThumbnailUrl.present
          ? data.remoteThumbnailUrl.value
          : this.remoteThumbnailUrl,
      aiTags: data.aiTags.present ? data.aiTags.value : this.aiTags,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      duration: data.duration.present ? data.duration.value : this.duration,
      cameraModel: data.cameraModel.present
          ? data.cameraModel.value
          : this.cameraModel,
      exposureTime: data.exposureTime.present
          ? data.exposureTime.value
          : this.exposureTime,
      fNumber: data.fNumber.present ? data.fNumber.value : this.fNumber,
      iso: data.iso.present ? data.iso.value : this.iso,
      focalLength: data.focalLength.present
          ? data.focalLength.value
          : this.focalLength,
      flash: data.flash.present ? data.flash.value : this.flash,
      lensModel: data.lensModel.present ? data.lensModel.value : this.lensModel,
      keywords: data.keywords.present ? data.keywords.value : this.keywords,
      textOCR: data.textOCR.present ? data.textOCR.value : this.textOCR,
      people: data.people.present ? data.people.value : this.people,
      kdriveFolderName: data.kdriveFolderName.present
          ? data.kdriveFolderName.value
          : this.kdriveFolderName,
      kdriveFolderId: data.kdriveFolderId.present
          ? data.kdriveFolderId.value
          : this.kdriveFolderId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('kdrivePath: $kdrivePath, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('localThumbnailPath: $localThumbnailPath, ')
          ..write('localHighResPath: $localHighResPath, ')
          ..write('remoteThumbnailUrl: $remoteThumbnailUrl, ')
          ..write('aiTags: $aiTags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('locationName: $locationName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('mediaType: $mediaType, ')
          ..write('duration: $duration, ')
          ..write('cameraModel: $cameraModel, ')
          ..write('exposureTime: $exposureTime, ')
          ..write('fNumber: $fNumber, ')
          ..write('iso: $iso, ')
          ..write('focalLength: $focalLength, ')
          ..write('flash: $flash, ')
          ..write('lensModel: $lensModel, ')
          ..write('keywords: $keywords, ')
          ..write('textOCR: $textOCR, ')
          ..write('people: $people, ')
          ..write('kdriveFolderName: $kdriveFolderName, ')
          ..write('kdriveFolderId: $kdriveFolderId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    fileName,
    kdrivePath,
    dateTaken,
    localThumbnailPath,
    localHighResPath,
    remoteThumbnailUrl,
    aiTags,
    isFavorite,
    locationName,
    latitude,
    longitude,
    mediaType,
    duration,
    cameraModel,
    exposureTime,
    fNumber,
    iso,
    focalLength,
    flash,
    lensModel,
    keywords,
    textOCR,
    people,
    kdriveFolderName,
    kdriveFolderId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.fileName == this.fileName &&
          other.kdrivePath == this.kdrivePath &&
          other.dateTaken == this.dateTaken &&
          other.localThumbnailPath == this.localThumbnailPath &&
          other.localHighResPath == this.localHighResPath &&
          other.remoteThumbnailUrl == this.remoteThumbnailUrl &&
          other.aiTags == this.aiTags &&
          other.isFavorite == this.isFavorite &&
          other.locationName == this.locationName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.mediaType == this.mediaType &&
          other.duration == this.duration &&
          other.cameraModel == this.cameraModel &&
          other.exposureTime == this.exposureTime &&
          other.fNumber == this.fNumber &&
          other.iso == this.iso &&
          other.focalLength == this.focalLength &&
          other.flash == this.flash &&
          other.lensModel == this.lensModel &&
          other.keywords == this.keywords &&
          other.textOCR == this.textOCR &&
          other.people == this.people &&
          other.kdriveFolderName == this.kdriveFolderName &&
          other.kdriveFolderId == this.kdriveFolderId);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<int> id;
  final Value<String> fileName;
  final Value<String> kdrivePath;
  final Value<DateTime> dateTaken;
  final Value<String?> localThumbnailPath;
  final Value<String?> localHighResPath;
  final Value<String?> remoteThumbnailUrl;
  final Value<List<String>> aiTags;
  final Value<bool> isFavorite;
  final Value<String?> locationName;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String> mediaType;
  final Value<int?> duration;
  final Value<String?> cameraModel;
  final Value<String?> exposureTime;
  final Value<String?> fNumber;
  final Value<int?> iso;
  final Value<String?> focalLength;
  final Value<String?> flash;
  final Value<String?> lensModel;
  final Value<String?> keywords;
  final Value<String?> textOCR;
  final Value<String?> people;
  final Value<String?> kdriveFolderName;
  final Value<String?> kdriveFolderId;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.fileName = const Value.absent(),
    this.kdrivePath = const Value.absent(),
    this.dateTaken = const Value.absent(),
    this.localThumbnailPath = const Value.absent(),
    this.localHighResPath = const Value.absent(),
    this.remoteThumbnailUrl = const Value.absent(),
    this.aiTags = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.locationName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.duration = const Value.absent(),
    this.cameraModel = const Value.absent(),
    this.exposureTime = const Value.absent(),
    this.fNumber = const Value.absent(),
    this.iso = const Value.absent(),
    this.focalLength = const Value.absent(),
    this.flash = const Value.absent(),
    this.lensModel = const Value.absent(),
    this.keywords = const Value.absent(),
    this.textOCR = const Value.absent(),
    this.people = const Value.absent(),
    this.kdriveFolderName = const Value.absent(),
    this.kdriveFolderId = const Value.absent(),
  });
  PhotosCompanion.insert({
    this.id = const Value.absent(),
    required String fileName,
    required String kdrivePath,
    required DateTime dateTaken,
    this.localThumbnailPath = const Value.absent(),
    this.localHighResPath = const Value.absent(),
    this.remoteThumbnailUrl = const Value.absent(),
    required List<String> aiTags,
    this.isFavorite = const Value.absent(),
    this.locationName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.duration = const Value.absent(),
    this.cameraModel = const Value.absent(),
    this.exposureTime = const Value.absent(),
    this.fNumber = const Value.absent(),
    this.iso = const Value.absent(),
    this.focalLength = const Value.absent(),
    this.flash = const Value.absent(),
    this.lensModel = const Value.absent(),
    this.keywords = const Value.absent(),
    this.textOCR = const Value.absent(),
    this.people = const Value.absent(),
    this.kdriveFolderName = const Value.absent(),
    this.kdriveFolderId = const Value.absent(),
  }) : fileName = Value(fileName),
       kdrivePath = Value(kdrivePath),
       dateTaken = Value(dateTaken),
       aiTags = Value(aiTags);
  static Insertable<Photo> custom({
    Expression<int>? id,
    Expression<String>? fileName,
    Expression<String>? kdrivePath,
    Expression<DateTime>? dateTaken,
    Expression<String>? localThumbnailPath,
    Expression<String>? localHighResPath,
    Expression<String>? remoteThumbnailUrl,
    Expression<String>? aiTags,
    Expression<bool>? isFavorite,
    Expression<String>? locationName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? mediaType,
    Expression<int>? duration,
    Expression<String>? cameraModel,
    Expression<String>? exposureTime,
    Expression<String>? fNumber,
    Expression<int>? iso,
    Expression<String>? focalLength,
    Expression<String>? flash,
    Expression<String>? lensModel,
    Expression<String>? keywords,
    Expression<String>? textOCR,
    Expression<String>? people,
    Expression<String>? kdriveFolderName,
    Expression<String>? kdriveFolderId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fileName != null) 'file_name': fileName,
      if (kdrivePath != null) 'kdrive_path': kdrivePath,
      if (dateTaken != null) 'date_taken': dateTaken,
      if (localThumbnailPath != null)
        'local_thumbnail_path': localThumbnailPath,
      if (localHighResPath != null) 'local_high_res_path': localHighResPath,
      if (remoteThumbnailUrl != null)
        'remote_thumbnail_url': remoteThumbnailUrl,
      if (aiTags != null) 'ai_tags': aiTags,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (locationName != null) 'location_name': locationName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (mediaType != null) 'media_type': mediaType,
      if (duration != null) 'duration': duration,
      if (cameraModel != null) 'camera_model': cameraModel,
      if (exposureTime != null) 'exposure_time': exposureTime,
      if (fNumber != null) 'f_number': fNumber,
      if (iso != null) 'iso': iso,
      if (focalLength != null) 'focal_length': focalLength,
      if (flash != null) 'flash': flash,
      if (lensModel != null) 'lens_model': lensModel,
      if (keywords != null) 'keywords': keywords,
      if (textOCR != null) 'text_o_c_r': textOCR,
      if (people != null) 'people': people,
      if (kdriveFolderName != null) 'kdrive_folder_name': kdriveFolderName,
      if (kdriveFolderId != null) 'kdrive_folder_id': kdriveFolderId,
    });
  }

  PhotosCompanion copyWith({
    Value<int>? id,
    Value<String>? fileName,
    Value<String>? kdrivePath,
    Value<DateTime>? dateTaken,
    Value<String?>? localThumbnailPath,
    Value<String?>? localHighResPath,
    Value<String?>? remoteThumbnailUrl,
    Value<List<String>>? aiTags,
    Value<bool>? isFavorite,
    Value<String?>? locationName,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String>? mediaType,
    Value<int?>? duration,
    Value<String?>? cameraModel,
    Value<String?>? exposureTime,
    Value<String?>? fNumber,
    Value<int?>? iso,
    Value<String?>? focalLength,
    Value<String?>? flash,
    Value<String?>? lensModel,
    Value<String?>? keywords,
    Value<String?>? textOCR,
    Value<String?>? people,
    Value<String?>? kdriveFolderName,
    Value<String?>? kdriveFolderId,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      kdrivePath: kdrivePath ?? this.kdrivePath,
      dateTaken: dateTaken ?? this.dateTaken,
      localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath,
      localHighResPath: localHighResPath ?? this.localHighResPath,
      remoteThumbnailUrl: remoteThumbnailUrl ?? this.remoteThumbnailUrl,
      aiTags: aiTags ?? this.aiTags,
      isFavorite: isFavorite ?? this.isFavorite,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      mediaType: mediaType ?? this.mediaType,
      duration: duration ?? this.duration,
      cameraModel: cameraModel ?? this.cameraModel,
      exposureTime: exposureTime ?? this.exposureTime,
      fNumber: fNumber ?? this.fNumber,
      iso: iso ?? this.iso,
      focalLength: focalLength ?? this.focalLength,
      flash: flash ?? this.flash,
      lensModel: lensModel ?? this.lensModel,
      keywords: keywords ?? this.keywords,
      textOCR: textOCR ?? this.textOCR,
      people: people ?? this.people,
      kdriveFolderName: kdriveFolderName ?? this.kdriveFolderName,
      kdriveFolderId: kdriveFolderId ?? this.kdriveFolderId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (kdrivePath.present) {
      map['kdrive_path'] = Variable<String>(kdrivePath.value);
    }
    if (dateTaken.present) {
      map['date_taken'] = Variable<DateTime>(dateTaken.value);
    }
    if (localThumbnailPath.present) {
      map['local_thumbnail_path'] = Variable<String>(localThumbnailPath.value);
    }
    if (localHighResPath.present) {
      map['local_high_res_path'] = Variable<String>(localHighResPath.value);
    }
    if (remoteThumbnailUrl.present) {
      map['remote_thumbnail_url'] = Variable<String>(remoteThumbnailUrl.value);
    }
    if (aiTags.present) {
      map['ai_tags'] = Variable<String>(
        $PhotosTable.$converteraiTags.toSql(aiTags.value),
      );
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (cameraModel.present) {
      map['camera_model'] = Variable<String>(cameraModel.value);
    }
    if (exposureTime.present) {
      map['exposure_time'] = Variable<String>(exposureTime.value);
    }
    if (fNumber.present) {
      map['f_number'] = Variable<String>(fNumber.value);
    }
    if (iso.present) {
      map['iso'] = Variable<int>(iso.value);
    }
    if (focalLength.present) {
      map['focal_length'] = Variable<String>(focalLength.value);
    }
    if (flash.present) {
      map['flash'] = Variable<String>(flash.value);
    }
    if (lensModel.present) {
      map['lens_model'] = Variable<String>(lensModel.value);
    }
    if (keywords.present) {
      map['keywords'] = Variable<String>(keywords.value);
    }
    if (textOCR.present) {
      map['text_o_c_r'] = Variable<String>(textOCR.value);
    }
    if (people.present) {
      map['people'] = Variable<String>(people.value);
    }
    if (kdriveFolderName.present) {
      map['kdrive_folder_name'] = Variable<String>(kdriveFolderName.value);
    }
    if (kdriveFolderId.present) {
      map['kdrive_folder_id'] = Variable<String>(kdriveFolderId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('fileName: $fileName, ')
          ..write('kdrivePath: $kdrivePath, ')
          ..write('dateTaken: $dateTaken, ')
          ..write('localThumbnailPath: $localThumbnailPath, ')
          ..write('localHighResPath: $localHighResPath, ')
          ..write('remoteThumbnailUrl: $remoteThumbnailUrl, ')
          ..write('aiTags: $aiTags, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('locationName: $locationName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('mediaType: $mediaType, ')
          ..write('duration: $duration, ')
          ..write('cameraModel: $cameraModel, ')
          ..write('exposureTime: $exposureTime, ')
          ..write('fNumber: $fNumber, ')
          ..write('iso: $iso, ')
          ..write('focalLength: $focalLength, ')
          ..write('flash: $flash, ')
          ..write('lensModel: $lensModel, ')
          ..write('keywords: $keywords, ')
          ..write('textOCR: $textOCR, ')
          ..write('people: $people, ')
          ..write('kdriveFolderName: $kdriveFolderName, ')
          ..write('kdriveFolderId: $kdriveFolderId')
          ..write(')'))
        .toString();
  }
}

class $AlbumsTable extends Albums with TableInfo<$AlbumsTable, Album> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverPhotoIdMeta = const VerificationMeta(
    'coverPhotoId',
  );
  @override
  late final GeneratedColumn<int> coverPhotoId = GeneratedColumn<int>(
    'cover_photo_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, coverPhotoId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<Album> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('cover_photo_id')) {
      context.handle(
        _coverPhotoIdMeta,
        coverPhotoId.isAcceptableOrUnknown(
          data['cover_photo_id']!,
          _coverPhotoIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Album map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Album(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      coverPhotoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_photo_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AlbumsTable createAlias(String alias) {
    return $AlbumsTable(attachedDatabase, alias);
  }
}

class Album extends DataClass implements Insertable<Album> {
  final int id;
  final String name;
  final int? coverPhotoId;
  final DateTime createdAt;
  const Album({
    required this.id,
    required this.name,
    this.coverPhotoId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || coverPhotoId != null) {
      map['cover_photo_id'] = Variable<int>(coverPhotoId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AlbumsCompanion toCompanion(bool nullToAbsent) {
    return AlbumsCompanion(
      id: Value(id),
      name: Value(name),
      coverPhotoId: coverPhotoId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPhotoId),
      createdAt: Value(createdAt),
    );
  }

  factory Album.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Album(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      coverPhotoId: serializer.fromJson<int?>(json['coverPhotoId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'coverPhotoId': serializer.toJson<int?>(coverPhotoId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Album copyWith({
    int? id,
    String? name,
    Value<int?> coverPhotoId = const Value.absent(),
    DateTime? createdAt,
  }) => Album(
    id: id ?? this.id,
    name: name ?? this.name,
    coverPhotoId: coverPhotoId.present ? coverPhotoId.value : this.coverPhotoId,
    createdAt: createdAt ?? this.createdAt,
  );
  Album copyWithCompanion(AlbumsCompanion data) {
    return Album(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      coverPhotoId: data.coverPhotoId.present
          ? data.coverPhotoId.value
          : this.coverPhotoId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Album(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPhotoId: $coverPhotoId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, coverPhotoId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Album &&
          other.id == this.id &&
          other.name == this.name &&
          other.coverPhotoId == this.coverPhotoId &&
          other.createdAt == this.createdAt);
}

class AlbumsCompanion extends UpdateCompanion<Album> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> coverPhotoId;
  final Value<DateTime> createdAt;
  const AlbumsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.coverPhotoId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AlbumsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.coverPhotoId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Album> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? coverPhotoId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (coverPhotoId != null) 'cover_photo_id': coverPhotoId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AlbumsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int?>? coverPhotoId,
    Value<DateTime>? createdAt,
  }) {
    return AlbumsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      coverPhotoId: coverPhotoId ?? this.coverPhotoId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (coverPhotoId.present) {
      map['cover_photo_id'] = Variable<int>(coverPhotoId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('coverPhotoId: $coverPhotoId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AlbumPhotosTable extends AlbumPhotos
    with TableInfo<$AlbumPhotosTable, AlbumPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlbumPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<int> albumId = GeneratedColumn<int>(
    'album_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES albums (id)',
    ),
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<int> photoId = GeneratedColumn<int>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [albumId, photoId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'album_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<AlbumPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    } else if (isInserting) {
      context.missing(_albumIdMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {albumId, photoId};
  @override
  AlbumPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AlbumPhoto(
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}album_id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_id'],
      )!,
    );
  }

  @override
  $AlbumPhotosTable createAlias(String alias) {
    return $AlbumPhotosTable(attachedDatabase, alias);
  }
}

class AlbumPhoto extends DataClass implements Insertable<AlbumPhoto> {
  final int albumId;
  final int photoId;
  const AlbumPhoto({required this.albumId, required this.photoId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['album_id'] = Variable<int>(albumId);
    map['photo_id'] = Variable<int>(photoId);
    return map;
  }

  AlbumPhotosCompanion toCompanion(bool nullToAbsent) {
    return AlbumPhotosCompanion(
      albumId: Value(albumId),
      photoId: Value(photoId),
    );
  }

  factory AlbumPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AlbumPhoto(
      albumId: serializer.fromJson<int>(json['albumId']),
      photoId: serializer.fromJson<int>(json['photoId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'albumId': serializer.toJson<int>(albumId),
      'photoId': serializer.toJson<int>(photoId),
    };
  }

  AlbumPhoto copyWith({int? albumId, int? photoId}) => AlbumPhoto(
    albumId: albumId ?? this.albumId,
    photoId: photoId ?? this.photoId,
  );
  AlbumPhoto copyWithCompanion(AlbumPhotosCompanion data) {
    return AlbumPhoto(
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AlbumPhoto(')
          ..write('albumId: $albumId, ')
          ..write('photoId: $photoId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(albumId, photoId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlbumPhoto &&
          other.albumId == this.albumId &&
          other.photoId == this.photoId);
}

class AlbumPhotosCompanion extends UpdateCompanion<AlbumPhoto> {
  final Value<int> albumId;
  final Value<int> photoId;
  final Value<int> rowid;
  const AlbumPhotosCompanion({
    this.albumId = const Value.absent(),
    this.photoId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlbumPhotosCompanion.insert({
    required int albumId,
    required int photoId,
    this.rowid = const Value.absent(),
  }) : albumId = Value(albumId),
       photoId = Value(photoId);
  static Insertable<AlbumPhoto> custom({
    Expression<int>? albumId,
    Expression<int>? photoId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (albumId != null) 'album_id': albumId,
      if (photoId != null) 'photo_id': photoId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlbumPhotosCompanion copyWith({
    Value<int>? albumId,
    Value<int>? photoId,
    Value<int>? rowid,
  }) {
    return AlbumPhotosCompanion(
      albumId: albumId ?? this.albumId,
      photoId: photoId ?? this.photoId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (albumId.present) {
      map['album_id'] = Variable<int>(albumId.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<int>(photoId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlbumPhotosCompanion(')
          ..write('albumId: $albumId, ')
          ..write('photoId: $photoId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PersonsTable extends Persons with TableInfo<$PersonsTable, Person> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceSamplePathMeta = const VerificationMeta(
    'faceSamplePath',
  );
  @override
  late final GeneratedColumn<String> faceSamplePath = GeneratedColumn<String>(
    'face_sample_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, faceSamplePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persons';
  @override
  VerificationContext validateIntegrity(
    Insertable<Person> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('face_sample_path')) {
      context.handle(
        _faceSamplePathMeta,
        faceSamplePath.isAcceptableOrUnknown(
          data['face_sample_path']!,
          _faceSamplePathMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Person map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Person(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      faceSamplePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_sample_path'],
      ),
    );
  }

  @override
  $PersonsTable createAlias(String alias) {
    return $PersonsTable(attachedDatabase, alias);
  }
}

class Person extends DataClass implements Insertable<Person> {
  final int id;
  final String name;
  final String? faceSamplePath;
  const Person({required this.id, required this.name, this.faceSamplePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || faceSamplePath != null) {
      map['face_sample_path'] = Variable<String>(faceSamplePath);
    }
    return map;
  }

  PersonsCompanion toCompanion(bool nullToAbsent) {
    return PersonsCompanion(
      id: Value(id),
      name: Value(name),
      faceSamplePath: faceSamplePath == null && nullToAbsent
          ? const Value.absent()
          : Value(faceSamplePath),
    );
  }

  factory Person.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Person(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      faceSamplePath: serializer.fromJson<String?>(json['faceSamplePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'faceSamplePath': serializer.toJson<String?>(faceSamplePath),
    };
  }

  Person copyWith({
    int? id,
    String? name,
    Value<String?> faceSamplePath = const Value.absent(),
  }) => Person(
    id: id ?? this.id,
    name: name ?? this.name,
    faceSamplePath: faceSamplePath.present
        ? faceSamplePath.value
        : this.faceSamplePath,
  );
  Person copyWithCompanion(PersonsCompanion data) {
    return Person(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      faceSamplePath: data.faceSamplePath.present
          ? data.faceSamplePath.value
          : this.faceSamplePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Person(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('faceSamplePath: $faceSamplePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, faceSamplePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Person &&
          other.id == this.id &&
          other.name == this.name &&
          other.faceSamplePath == this.faceSamplePath);
}

class PersonsCompanion extends UpdateCompanion<Person> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> faceSamplePath;
  const PersonsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.faceSamplePath = const Value.absent(),
  });
  PersonsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.faceSamplePath = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Person> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? faceSamplePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (faceSamplePath != null) 'face_sample_path': faceSamplePath,
    });
  }

  PersonsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? faceSamplePath,
  }) {
    return PersonsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      faceSamplePath: faceSamplePath ?? this.faceSamplePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (faceSamplePath.present) {
      map['face_sample_path'] = Variable<String>(faceSamplePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersonsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('faceSamplePath: $faceSamplePath')
          ..write(')'))
        .toString();
  }
}

class $DetectedFacesTable extends DetectedFaces
    with TableInfo<$DetectedFacesTable, DetectedFace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectedFacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<int> photoId = GeneratedColumn<int>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES photos (id)',
    ),
  );
  static const VerificationMeta _personIdMeta = const VerificationMeta(
    'personId',
  );
  @override
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES persons (id)',
    ),
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _faceThumbnailPathMeta = const VerificationMeta(
    'faceThumbnailPath',
  );
  @override
  late final GeneratedColumn<String> faceThumbnailPath =
      GeneratedColumn<String>(
        'face_thumbnail_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _embeddingMeta = const VerificationMeta(
    'embedding',
  );
  @override
  late final GeneratedColumn<String> embedding = GeneratedColumn<String>(
    'embedding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    photoId,
    personId,
    x,
    y,
    width,
    height,
    faceThumbnailPath,
    embedding,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detected_faces';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetectedFace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('person_id')) {
      context.handle(
        _personIdMeta,
        personId.isAcceptableOrUnknown(data['person_id']!, _personIdMeta),
      );
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    } else if (isInserting) {
      context.missing(_xMeta);
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    } else if (isInserting) {
      context.missing(_yMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('face_thumbnail_path')) {
      context.handle(
        _faceThumbnailPathMeta,
        faceThumbnailPath.isAcceptableOrUnknown(
          data['face_thumbnail_path']!,
          _faceThumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('embedding')) {
      context.handle(
        _embeddingMeta,
        embedding.isAcceptableOrUnknown(data['embedding']!, _embeddingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DetectedFace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectedFace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}photo_id'],
      )!,
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      ),
      x: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}x'],
      )!,
      y: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}y'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      faceThumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}face_thumbnail_path'],
      ),
      embedding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}embedding'],
      ),
    );
  }

  @override
  $DetectedFacesTable createAlias(String alias) {
    return $DetectedFacesTable(attachedDatabase, alias);
  }
}

class DetectedFace extends DataClass implements Insertable<DetectedFace> {
  final int id;
  final int photoId;
  final int? personId;
  final double x;
  final double y;
  final double width;
  final double height;
  final String? faceThumbnailPath;
  final String? embedding;
  const DetectedFace({
    required this.id,
    required this.photoId,
    this.personId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.faceThumbnailPath,
    this.embedding,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['photo_id'] = Variable<int>(photoId);
    if (!nullToAbsent || personId != null) {
      map['person_id'] = Variable<int>(personId);
    }
    map['x'] = Variable<double>(x);
    map['y'] = Variable<double>(y);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    if (!nullToAbsent || faceThumbnailPath != null) {
      map['face_thumbnail_path'] = Variable<String>(faceThumbnailPath);
    }
    if (!nullToAbsent || embedding != null) {
      map['embedding'] = Variable<String>(embedding);
    }
    return map;
  }

  DetectedFacesCompanion toCompanion(bool nullToAbsent) {
    return DetectedFacesCompanion(
      id: Value(id),
      photoId: Value(photoId),
      personId: personId == null && nullToAbsent
          ? const Value.absent()
          : Value(personId),
      x: Value(x),
      y: Value(y),
      width: Value(width),
      height: Value(height),
      faceThumbnailPath: faceThumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(faceThumbnailPath),
      embedding: embedding == null && nullToAbsent
          ? const Value.absent()
          : Value(embedding),
    );
  }

  factory DetectedFace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectedFace(
      id: serializer.fromJson<int>(json['id']),
      photoId: serializer.fromJson<int>(json['photoId']),
      personId: serializer.fromJson<int?>(json['personId']),
      x: serializer.fromJson<double>(json['x']),
      y: serializer.fromJson<double>(json['y']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      faceThumbnailPath: serializer.fromJson<String?>(
        json['faceThumbnailPath'],
      ),
      embedding: serializer.fromJson<String?>(json['embedding']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'photoId': serializer.toJson<int>(photoId),
      'personId': serializer.toJson<int?>(personId),
      'x': serializer.toJson<double>(x),
      'y': serializer.toJson<double>(y),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'faceThumbnailPath': serializer.toJson<String?>(faceThumbnailPath),
      'embedding': serializer.toJson<String?>(embedding),
    };
  }

  DetectedFace copyWith({
    int? id,
    int? photoId,
    Value<int?> personId = const Value.absent(),
    double? x,
    double? y,
    double? width,
    double? height,
    Value<String?> faceThumbnailPath = const Value.absent(),
    Value<String?> embedding = const Value.absent(),
  }) => DetectedFace(
    id: id ?? this.id,
    photoId: photoId ?? this.photoId,
    personId: personId.present ? personId.value : this.personId,
    x: x ?? this.x,
    y: y ?? this.y,
    width: width ?? this.width,
    height: height ?? this.height,
    faceThumbnailPath: faceThumbnailPath.present
        ? faceThumbnailPath.value
        : this.faceThumbnailPath,
    embedding: embedding.present ? embedding.value : this.embedding,
  );
  DetectedFace copyWithCompanion(DetectedFacesCompanion data) {
    return DetectedFace(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      personId: data.personId.present ? data.personId.value : this.personId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      faceThumbnailPath: data.faceThumbnailPath.present
          ? data.faceThumbnailPath.value
          : this.faceThumbnailPath,
      embedding: data.embedding.present ? data.embedding.value : this.embedding,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectedFace(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('personId: $personId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('faceThumbnailPath: $faceThumbnailPath, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    photoId,
    personId,
    x,
    y,
    width,
    height,
    faceThumbnailPath,
    embedding,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectedFace &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.personId == this.personId &&
          other.x == this.x &&
          other.y == this.y &&
          other.width == this.width &&
          other.height == this.height &&
          other.faceThumbnailPath == this.faceThumbnailPath &&
          other.embedding == this.embedding);
}

class DetectedFacesCompanion extends UpdateCompanion<DetectedFace> {
  final Value<int> id;
  final Value<int> photoId;
  final Value<int?> personId;
  final Value<double> x;
  final Value<double> y;
  final Value<double> width;
  final Value<double> height;
  final Value<String?> faceThumbnailPath;
  final Value<String?> embedding;
  const DetectedFacesCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.personId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.faceThumbnailPath = const Value.absent(),
    this.embedding = const Value.absent(),
  });
  DetectedFacesCompanion.insert({
    this.id = const Value.absent(),
    required int photoId,
    this.personId = const Value.absent(),
    required double x,
    required double y,
    required double width,
    required double height,
    this.faceThumbnailPath = const Value.absent(),
    this.embedding = const Value.absent(),
  }) : photoId = Value(photoId),
       x = Value(x),
       y = Value(y),
       width = Value(width),
       height = Value(height);
  static Insertable<DetectedFace> custom({
    Expression<int>? id,
    Expression<int>? photoId,
    Expression<int>? personId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<double>? width,
    Expression<double>? height,
    Expression<String>? faceThumbnailPath,
    Expression<String>? embedding,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (personId != null) 'person_id': personId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (faceThumbnailPath != null) 'face_thumbnail_path': faceThumbnailPath,
      if (embedding != null) 'embedding': embedding,
    });
  }

  DetectedFacesCompanion copyWith({
    Value<int>? id,
    Value<int>? photoId,
    Value<int?>? personId,
    Value<double>? x,
    Value<double>? y,
    Value<double>? width,
    Value<double>? height,
    Value<String?>? faceThumbnailPath,
    Value<String?>? embedding,
  }) {
    return DetectedFacesCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      personId: personId ?? this.personId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      faceThumbnailPath: faceThumbnailPath ?? this.faceThumbnailPath,
      embedding: embedding ?? this.embedding,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<int>(photoId.value);
    }
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (faceThumbnailPath.present) {
      map['face_thumbnail_path'] = Variable<String>(faceThumbnailPath.value);
    }
    if (embedding.present) {
      map['embedding'] = Variable<String>(embedding.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectedFacesCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('personId: $personId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('faceThumbnailPath: $faceThumbnailPath, ')
          ..write('embedding: $embedding')
          ..write(')'))
        .toString();
  }
}

class $FolderSyncTable extends FolderSync
    with TableInfo<$FolderSyncTable, FolderSyncData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncMeta = const VerificationMeta(
    'lastSync',
  );
  @override
  late final GeneratedColumn<DateTime> lastSync = GeneratedColumn<DateTime>(
    'last_sync',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [folderId, lastSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderSyncData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('last_sync')) {
      context.handle(
        _lastSyncMeta,
        lastSync.isAcceptableOrUnknown(data['last_sync']!, _lastSyncMeta),
      );
    } else if (isInserting) {
      context.missing(_lastSyncMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {folderId};
  @override
  FolderSyncData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderSyncData(
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      lastSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync'],
      )!,
    );
  }

  @override
  $FolderSyncTable createAlias(String alias) {
    return $FolderSyncTable(attachedDatabase, alias);
  }
}

class FolderSyncData extends DataClass implements Insertable<FolderSyncData> {
  final String folderId;
  final DateTime lastSync;
  const FolderSyncData({required this.folderId, required this.lastSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['folder_id'] = Variable<String>(folderId);
    map['last_sync'] = Variable<DateTime>(lastSync);
    return map;
  }

  FolderSyncCompanion toCompanion(bool nullToAbsent) {
    return FolderSyncCompanion(
      folderId: Value(folderId),
      lastSync: Value(lastSync),
    );
  }

  factory FolderSyncData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderSyncData(
      folderId: serializer.fromJson<String>(json['folderId']),
      lastSync: serializer.fromJson<DateTime>(json['lastSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'folderId': serializer.toJson<String>(folderId),
      'lastSync': serializer.toJson<DateTime>(lastSync),
    };
  }

  FolderSyncData copyWith({String? folderId, DateTime? lastSync}) =>
      FolderSyncData(
        folderId: folderId ?? this.folderId,
        lastSync: lastSync ?? this.lastSync,
      );
  FolderSyncData copyWithCompanion(FolderSyncCompanion data) {
    return FolderSyncData(
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      lastSync: data.lastSync.present ? data.lastSync.value : this.lastSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderSyncData(')
          ..write('folderId: $folderId, ')
          ..write('lastSync: $lastSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(folderId, lastSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderSyncData &&
          other.folderId == this.folderId &&
          other.lastSync == this.lastSync);
}

class FolderSyncCompanion extends UpdateCompanion<FolderSyncData> {
  final Value<String> folderId;
  final Value<DateTime> lastSync;
  final Value<int> rowid;
  const FolderSyncCompanion({
    this.folderId = const Value.absent(),
    this.lastSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderSyncCompanion.insert({
    required String folderId,
    required DateTime lastSync,
    this.rowid = const Value.absent(),
  }) : folderId = Value(folderId),
       lastSync = Value(lastSync);
  static Insertable<FolderSyncData> custom({
    Expression<String>? folderId,
    Expression<DateTime>? lastSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (folderId != null) 'folder_id': folderId,
      if (lastSync != null) 'last_sync': lastSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderSyncCompanion copyWith({
    Value<String>? folderId,
    Value<DateTime>? lastSync,
    Value<int>? rowid,
  }) {
    return FolderSyncCompanion(
      folderId: folderId ?? this.folderId,
      lastSync: lastSync ?? this.lastSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (lastSync.present) {
      map['last_sync'] = Variable<DateTime>(lastSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderSyncCompanion(')
          ..write('folderId: $folderId, ')
          ..write('lastSync: $lastSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $AlbumsTable albums = $AlbumsTable(this);
  late final $AlbumPhotosTable albumPhotos = $AlbumPhotosTable(this);
  late final $PersonsTable persons = $PersonsTable(this);
  late final $DetectedFacesTable detectedFaces = $DetectedFacesTable(this);
  late final $FolderSyncTable folderSync = $FolderSyncTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    photos,
    albums,
    albumPhotos,
    persons,
    detectedFaces,
    folderSync,
  ];
}

typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      Value<int> id,
      required String fileName,
      required String kdrivePath,
      required DateTime dateTaken,
      Value<String?> localThumbnailPath,
      Value<String?> localHighResPath,
      Value<String?> remoteThumbnailUrl,
      required List<String> aiTags,
      Value<bool> isFavorite,
      Value<String?> locationName,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String> mediaType,
      Value<int?> duration,
      Value<String?> cameraModel,
      Value<String?> exposureTime,
      Value<String?> fNumber,
      Value<int?> iso,
      Value<String?> focalLength,
      Value<String?> flash,
      Value<String?> lensModel,
      Value<String?> keywords,
      Value<String?> textOCR,
      Value<String?> people,
      Value<String?> kdriveFolderName,
      Value<String?> kdriveFolderId,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<int> id,
      Value<String> fileName,
      Value<String> kdrivePath,
      Value<DateTime> dateTaken,
      Value<String?> localThumbnailPath,
      Value<String?> localHighResPath,
      Value<String?> remoteThumbnailUrl,
      Value<List<String>> aiTags,
      Value<bool> isFavorite,
      Value<String?> locationName,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String> mediaType,
      Value<int?> duration,
      Value<String?> cameraModel,
      Value<String?> exposureTime,
      Value<String?> fNumber,
      Value<int?> iso,
      Value<String?> focalLength,
      Value<String?> flash,
      Value<String?> lensModel,
      Value<String?> keywords,
      Value<String?> textOCR,
      Value<String?> people,
      Value<String?> kdriveFolderName,
      Value<String?> kdriveFolderId,
    });

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, Photo> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AlbumsTable, List<Album>> _albumsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.albums,
    aliasName: 'photos__id__albums__cover_photo_id',
  );

  $$AlbumsTableProcessedTableManager get albumsRefs {
    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.coverPhotoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_albumsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AlbumPhotosTable, List<AlbumPhoto>>
  _albumPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.albumPhotos,
    aliasName: 'photos__id__album_photos__photo_id',
  );

  $$AlbumPhotosTableProcessedTableManager get albumPhotosRefs {
    final manager = $$AlbumPhotosTableTableManager(
      $_db,
      $_db.albumPhotos,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_albumPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DetectedFacesTable, List<DetectedFace>>
  _detectedFacesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detectedFaces,
    aliasName: 'photos__id__detected_faces__photo_id',
  );

  $$DetectedFacesTableProcessedTableManager get detectedFacesRefs {
    final manager = $$DetectedFacesTableTableManager(
      $_db,
      $_db.detectedFaces,
    ).filter((f) => f.photoId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_detectedFacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kdrivePath => $composableBuilder(
    column: $table.kdrivePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localThumbnailPath => $composableBuilder(
    column: $table.localThumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localHighResPath => $composableBuilder(
    column: $table.localHighResPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteThumbnailUrl => $composableBuilder(
    column: $table.remoteThumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
  get aiTags => $composableBuilder(
    column: $table.aiTags,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cameraModel => $composableBuilder(
    column: $table.cameraModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exposureTime => $composableBuilder(
    column: $table.exposureTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fNumber => $composableBuilder(
    column: $table.fNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iso => $composableBuilder(
    column: $table.iso,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get focalLength => $composableBuilder(
    column: $table.focalLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flash => $composableBuilder(
    column: $table.flash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lensModel => $composableBuilder(
    column: $table.lensModel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textOCR => $composableBuilder(
    column: $table.textOCR,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get people => $composableBuilder(
    column: $table.people,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kdriveFolderName => $composableBuilder(
    column: $table.kdriveFolderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kdriveFolderId => $composableBuilder(
    column: $table.kdriveFolderId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> albumsRefs(
    Expression<bool> Function($$AlbumsTableFilterComposer f) f,
  ) {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.coverPhotoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> albumPhotosRefs(
    Expression<bool> Function($$AlbumPhotosTableFilterComposer f) f,
  ) {
    final $$AlbumPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumPhotos,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumPhotosTableFilterComposer(
            $db: $db,
            $table: $db.albumPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> detectedFacesRefs(
    Expression<bool> Function($$DetectedFacesTableFilterComposer f) f,
  ) {
    final $$DetectedFacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detectedFaces,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectedFacesTableFilterComposer(
            $db: $db,
            $table: $db.detectedFaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kdrivePath => $composableBuilder(
    column: $table.kdrivePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dateTaken => $composableBuilder(
    column: $table.dateTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localThumbnailPath => $composableBuilder(
    column: $table.localThumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localHighResPath => $composableBuilder(
    column: $table.localHighResPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteThumbnailUrl => $composableBuilder(
    column: $table.remoteThumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aiTags => $composableBuilder(
    column: $table.aiTags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cameraModel => $composableBuilder(
    column: $table.cameraModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exposureTime => $composableBuilder(
    column: $table.exposureTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fNumber => $composableBuilder(
    column: $table.fNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iso => $composableBuilder(
    column: $table.iso,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get focalLength => $composableBuilder(
    column: $table.focalLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flash => $composableBuilder(
    column: $table.flash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lensModel => $composableBuilder(
    column: $table.lensModel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keywords => $composableBuilder(
    column: $table.keywords,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textOCR => $composableBuilder(
    column: $table.textOCR,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get people => $composableBuilder(
    column: $table.people,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kdriveFolderName => $composableBuilder(
    column: $table.kdriveFolderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kdriveFolderId => $composableBuilder(
    column: $table.kdriveFolderId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get kdrivePath => $composableBuilder(
    column: $table.kdrivePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dateTaken =>
      $composableBuilder(column: $table.dateTaken, builder: (column) => column);

  GeneratedColumn<String> get localThumbnailPath => $composableBuilder(
    column: $table.localThumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localHighResPath => $composableBuilder(
    column: $table.localHighResPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteThumbnailUrl => $composableBuilder(
    column: $table.remoteThumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<String>, String> get aiTags =>
      $composableBuilder(column: $table.aiTags, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get cameraModel => $composableBuilder(
    column: $table.cameraModel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exposureTime => $composableBuilder(
    column: $table.exposureTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fNumber =>
      $composableBuilder(column: $table.fNumber, builder: (column) => column);

  GeneratedColumn<int> get iso =>
      $composableBuilder(column: $table.iso, builder: (column) => column);

  GeneratedColumn<String> get focalLength => $composableBuilder(
    column: $table.focalLength,
    builder: (column) => column,
  );

  GeneratedColumn<String> get flash =>
      $composableBuilder(column: $table.flash, builder: (column) => column);

  GeneratedColumn<String> get lensModel =>
      $composableBuilder(column: $table.lensModel, builder: (column) => column);

  GeneratedColumn<String> get keywords =>
      $composableBuilder(column: $table.keywords, builder: (column) => column);

  GeneratedColumn<String> get textOCR =>
      $composableBuilder(column: $table.textOCR, builder: (column) => column);

  GeneratedColumn<String> get people =>
      $composableBuilder(column: $table.people, builder: (column) => column);

  GeneratedColumn<String> get kdriveFolderName => $composableBuilder(
    column: $table.kdriveFolderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kdriveFolderId => $composableBuilder(
    column: $table.kdriveFolderId,
    builder: (column) => column,
  );

  Expression<T> albumsRefs<T extends Object>(
    Expression<T> Function($$AlbumsTableAnnotationComposer a) f,
  ) {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.coverPhotoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> albumPhotosRefs<T extends Object>(
    Expression<T> Function($$AlbumPhotosTableAnnotationComposer a) f,
  ) {
    final $$AlbumPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumPhotos,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.albumPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> detectedFacesRefs<T extends Object>(
    Expression<T> Function($$DetectedFacesTableAnnotationComposer a) f,
  ) {
    final $$DetectedFacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detectedFaces,
      getReferencedColumn: (t) => t.photoId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectedFacesTableAnnotationComposer(
            $db: $db,
            $table: $db.detectedFaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, $$PhotosTableReferences),
          Photo,
          PrefetchHooks Function({
            bool albumsRefs,
            bool albumPhotosRefs,
            bool detectedFacesRefs,
          })
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> kdrivePath = const Value.absent(),
                Value<DateTime> dateTaken = const Value.absent(),
                Value<String?> localThumbnailPath = const Value.absent(),
                Value<String?> localHighResPath = const Value.absent(),
                Value<String?> remoteThumbnailUrl = const Value.absent(),
                Value<List<String>> aiTags = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<String?> cameraModel = const Value.absent(),
                Value<String?> exposureTime = const Value.absent(),
                Value<String?> fNumber = const Value.absent(),
                Value<int?> iso = const Value.absent(),
                Value<String?> focalLength = const Value.absent(),
                Value<String?> flash = const Value.absent(),
                Value<String?> lensModel = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
                Value<String?> textOCR = const Value.absent(),
                Value<String?> people = const Value.absent(),
                Value<String?> kdriveFolderName = const Value.absent(),
                Value<String?> kdriveFolderId = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                fileName: fileName,
                kdrivePath: kdrivePath,
                dateTaken: dateTaken,
                localThumbnailPath: localThumbnailPath,
                localHighResPath: localHighResPath,
                remoteThumbnailUrl: remoteThumbnailUrl,
                aiTags: aiTags,
                isFavorite: isFavorite,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                mediaType: mediaType,
                duration: duration,
                cameraModel: cameraModel,
                exposureTime: exposureTime,
                fNumber: fNumber,
                iso: iso,
                focalLength: focalLength,
                flash: flash,
                lensModel: lensModel,
                keywords: keywords,
                textOCR: textOCR,
                people: people,
                kdriveFolderName: kdriveFolderName,
                kdriveFolderId: kdriveFolderId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String fileName,
                required String kdrivePath,
                required DateTime dateTaken,
                Value<String?> localThumbnailPath = const Value.absent(),
                Value<String?> localHighResPath = const Value.absent(),
                Value<String?> remoteThumbnailUrl = const Value.absent(),
                required List<String> aiTags,
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<int?> duration = const Value.absent(),
                Value<String?> cameraModel = const Value.absent(),
                Value<String?> exposureTime = const Value.absent(),
                Value<String?> fNumber = const Value.absent(),
                Value<int?> iso = const Value.absent(),
                Value<String?> focalLength = const Value.absent(),
                Value<String?> flash = const Value.absent(),
                Value<String?> lensModel = const Value.absent(),
                Value<String?> keywords = const Value.absent(),
                Value<String?> textOCR = const Value.absent(),
                Value<String?> people = const Value.absent(),
                Value<String?> kdriveFolderName = const Value.absent(),
                Value<String?> kdriveFolderId = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                fileName: fileName,
                kdrivePath: kdrivePath,
                dateTaken: dateTaken,
                localThumbnailPath: localThumbnailPath,
                localHighResPath: localHighResPath,
                remoteThumbnailUrl: remoteThumbnailUrl,
                aiTags: aiTags,
                isFavorite: isFavorite,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                mediaType: mediaType,
                duration: duration,
                cameraModel: cameraModel,
                exposureTime: exposureTime,
                fNumber: fNumber,
                iso: iso,
                focalLength: focalLength,
                flash: flash,
                lensModel: lensModel,
                keywords: keywords,
                textOCR: textOCR,
                people: people,
                kdriveFolderName: kdriveFolderName,
                kdriveFolderId: kdriveFolderId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PhotosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                albumsRefs = false,
                albumPhotosRefs = false,
                detectedFacesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (albumsRefs) db.albums,
                    if (albumPhotosRefs) db.albumPhotos,
                    if (detectedFacesRefs) db.detectedFaces,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (albumsRefs)
                        await $_getPrefetchedData<Photo, $PhotosTable, Album>(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._albumsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(db, table, p0).albumsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.coverPhotoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (albumPhotosRefs)
                        await $_getPrefetchedData<
                          Photo,
                          $PhotosTable,
                          AlbumPhoto
                        >(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._albumPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).albumPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.photoId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (detectedFacesRefs)
                        await $_getPrefetchedData<
                          Photo,
                          $PhotosTable,
                          DetectedFace
                        >(
                          currentTable: table,
                          referencedTable: $$PhotosTableReferences
                              ._detectedFacesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PhotosTableReferences(
                                db,
                                table,
                                p0,
                              ).detectedFacesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.photoId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, $$PhotosTableReferences),
      Photo,
      PrefetchHooks Function({
        bool albumsRefs,
        bool albumPhotosRefs,
        bool detectedFacesRefs,
      })
    >;
typedef $$AlbumsTableCreateCompanionBuilder =
    AlbumsCompanion Function({
      Value<int> id,
      required String name,
      Value<int?> coverPhotoId,
      Value<DateTime> createdAt,
    });
typedef $$AlbumsTableUpdateCompanionBuilder =
    AlbumsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<int?> coverPhotoId,
      Value<DateTime> createdAt,
    });

final class $$AlbumsTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumsTable, Album> {
  $$AlbumsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PhotosTable _coverPhotoIdTable(_$AppDatabase db) =>
      db.photos.createAlias('albums__cover_photo_id__photos__id');

  $$PhotosTableProcessedTableManager? get coverPhotoId {
    final $_column = $_itemColumn<int>('cover_photo_id');
    if ($_column == null) return null;
    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_coverPhotoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AlbumPhotosTable, List<AlbumPhoto>>
  _albumPhotosRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.albumPhotos,
    aliasName: 'albums__id__album_photos__album_id',
  );

  $$AlbumPhotosTableProcessedTableManager get albumPhotosRefs {
    final manager = $$AlbumPhotosTableTableManager(
      $_db,
      $_db.albumPhotos,
    ).filter((f) => f.albumId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_albumPhotosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AlbumsTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PhotosTableFilterComposer get coverPhotoId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverPhotoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> albumPhotosRefs(
    Expression<bool> Function($$AlbumPhotosTableFilterComposer f) f,
  ) {
    final $$AlbumPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumPhotos,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumPhotosTableFilterComposer(
            $db: $db,
            $table: $db.albumPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PhotosTableOrderingComposer get coverPhotoId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverPhotoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumsTable> {
  $$AlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$PhotosTableAnnotationComposer get coverPhotoId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.coverPhotoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> albumPhotosRefs<T extends Object>(
    Expression<T> Function($$AlbumPhotosTableAnnotationComposer a) f,
  ) {
    final $$AlbumPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.albumPhotos,
      getReferencedColumn: (t) => t.albumId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.albumPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AlbumsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumsTable,
          Album,
          $$AlbumsTableFilterComposer,
          $$AlbumsTableOrderingComposer,
          $$AlbumsTableAnnotationComposer,
          $$AlbumsTableCreateCompanionBuilder,
          $$AlbumsTableUpdateCompanionBuilder,
          (Album, $$AlbumsTableReferences),
          Album,
          PrefetchHooks Function({bool coverPhotoId, bool albumPhotosRefs})
        > {
  $$AlbumsTableTableManager(_$AppDatabase db, $AlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> coverPhotoId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AlbumsCompanion(
                id: id,
                name: name,
                coverPhotoId: coverPhotoId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int?> coverPhotoId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => AlbumsCompanion.insert(
                id: id,
                name: name,
                coverPhotoId: coverPhotoId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AlbumsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({coverPhotoId = false, albumPhotosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (albumPhotosRefs) db.albumPhotos,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (coverPhotoId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.coverPhotoId,
                                    referencedTable: $$AlbumsTableReferences
                                        ._coverPhotoIdTable(db),
                                    referencedColumn: $$AlbumsTableReferences
                                        ._coverPhotoIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (albumPhotosRefs)
                        await $_getPrefetchedData<
                          Album,
                          $AlbumsTable,
                          AlbumPhoto
                        >(
                          currentTable: table,
                          referencedTable: $$AlbumsTableReferences
                              ._albumPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AlbumsTableReferences(
                                db,
                                table,
                                p0,
                              ).albumPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.albumId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumsTable,
      Album,
      $$AlbumsTableFilterComposer,
      $$AlbumsTableOrderingComposer,
      $$AlbumsTableAnnotationComposer,
      $$AlbumsTableCreateCompanionBuilder,
      $$AlbumsTableUpdateCompanionBuilder,
      (Album, $$AlbumsTableReferences),
      Album,
      PrefetchHooks Function({bool coverPhotoId, bool albumPhotosRefs})
    >;
typedef $$AlbumPhotosTableCreateCompanionBuilder =
    AlbumPhotosCompanion Function({
      required int albumId,
      required int photoId,
      Value<int> rowid,
    });
typedef $$AlbumPhotosTableUpdateCompanionBuilder =
    AlbumPhotosCompanion Function({
      Value<int> albumId,
      Value<int> photoId,
      Value<int> rowid,
    });

final class $$AlbumPhotosTableReferences
    extends BaseReferences<_$AppDatabase, $AlbumPhotosTable, AlbumPhoto> {
  $$AlbumPhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AlbumsTable _albumIdTable(_$AppDatabase db) =>
      db.albums.createAlias('album_photos__album_id__albums__id');

  $$AlbumsTableProcessedTableManager get albumId {
    final $_column = $_itemColumn<int>('album_id')!;

    final manager = $$AlbumsTableTableManager(
      $_db,
      $_db.albums,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_albumIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PhotosTable _photoIdTable(_$AppDatabase db) =>
      db.photos.createAlias('album_photos__photo_id__photos__id');

  $$PhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<int>('photo_id')!;

    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AlbumPhotosTableFilterComposer
    extends Composer<_$AppDatabase, $AlbumPhotosTable> {
  $$AlbumPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AlbumsTableFilterComposer get albumId {
    final $$AlbumsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableFilterComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableFilterComposer get photoId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumPhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $AlbumPhotosTable> {
  $$AlbumPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AlbumsTableOrderingComposer get albumId {
    final $$AlbumsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableOrderingComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableOrderingComposer get photoId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumPhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlbumPhotosTable> {
  $$AlbumPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$AlbumsTableAnnotationComposer get albumId {
    final $$AlbumsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.albumId,
      referencedTable: $db.albums,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AlbumsTableAnnotationComposer(
            $db: $db,
            $table: $db.albums,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhotosTableAnnotationComposer get photoId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AlbumPhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlbumPhotosTable,
          AlbumPhoto,
          $$AlbumPhotosTableFilterComposer,
          $$AlbumPhotosTableOrderingComposer,
          $$AlbumPhotosTableAnnotationComposer,
          $$AlbumPhotosTableCreateCompanionBuilder,
          $$AlbumPhotosTableUpdateCompanionBuilder,
          (AlbumPhoto, $$AlbumPhotosTableReferences),
          AlbumPhoto,
          PrefetchHooks Function({bool albumId, bool photoId})
        > {
  $$AlbumPhotosTableTableManager(_$AppDatabase db, $AlbumPhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlbumPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlbumPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlbumPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> albumId = const Value.absent(),
                Value<int> photoId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlbumPhotosCompanion(
                albumId: albumId,
                photoId: photoId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int albumId,
                required int photoId,
                Value<int> rowid = const Value.absent(),
              }) => AlbumPhotosCompanion.insert(
                albumId: albumId,
                photoId: photoId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AlbumPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({albumId = false, photoId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (albumId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.albumId,
                                referencedTable: $$AlbumPhotosTableReferences
                                    ._albumIdTable(db),
                                referencedColumn: $$AlbumPhotosTableReferences
                                    ._albumIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (photoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.photoId,
                                referencedTable: $$AlbumPhotosTableReferences
                                    ._photoIdTable(db),
                                referencedColumn: $$AlbumPhotosTableReferences
                                    ._photoIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AlbumPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlbumPhotosTable,
      AlbumPhoto,
      $$AlbumPhotosTableFilterComposer,
      $$AlbumPhotosTableOrderingComposer,
      $$AlbumPhotosTableAnnotationComposer,
      $$AlbumPhotosTableCreateCompanionBuilder,
      $$AlbumPhotosTableUpdateCompanionBuilder,
      (AlbumPhoto, $$AlbumPhotosTableReferences),
      AlbumPhoto,
      PrefetchHooks Function({bool albumId, bool photoId})
    >;
typedef $$PersonsTableCreateCompanionBuilder =
    PersonsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> faceSamplePath,
    });
typedef $$PersonsTableUpdateCompanionBuilder =
    PersonsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> faceSamplePath,
    });

final class $$PersonsTableReferences
    extends BaseReferences<_$AppDatabase, $PersonsTable, Person> {
  $$PersonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DetectedFacesTable, List<DetectedFace>>
  _detectedFacesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.detectedFaces,
    aliasName: 'persons__id__detected_faces__person_id',
  );

  $$DetectedFacesTableProcessedTableManager get detectedFacesRefs {
    final manager = $$DetectedFacesTableTableManager(
      $_db,
      $_db.detectedFaces,
    ).filter((f) => f.personId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_detectedFacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PersonsTableFilterComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faceSamplePath => $composableBuilder(
    column: $table.faceSamplePath,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> detectedFacesRefs(
    Expression<bool> Function($$DetectedFacesTableFilterComposer f) f,
  ) {
    final $$DetectedFacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detectedFaces,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectedFacesTableFilterComposer(
            $db: $db,
            $table: $db.detectedFaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonsTableOrderingComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faceSamplePath => $composableBuilder(
    column: $table.faceSamplePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersonsTable> {
  $$PersonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get faceSamplePath => $composableBuilder(
    column: $table.faceSamplePath,
    builder: (column) => column,
  );

  Expression<T> detectedFacesRefs<T extends Object>(
    Expression<T> Function($$DetectedFacesTableAnnotationComposer a) f,
  ) {
    final $$DetectedFacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.detectedFaces,
      getReferencedColumn: (t) => t.personId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DetectedFacesTableAnnotationComposer(
            $db: $db,
            $table: $db.detectedFaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PersonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersonsTable,
          Person,
          $$PersonsTableFilterComposer,
          $$PersonsTableOrderingComposer,
          $$PersonsTableAnnotationComposer,
          $$PersonsTableCreateCompanionBuilder,
          $$PersonsTableUpdateCompanionBuilder,
          (Person, $$PersonsTableReferences),
          Person,
          PrefetchHooks Function({bool detectedFacesRefs})
        > {
  $$PersonsTableTableManager(_$AppDatabase db, $PersonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PersonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> faceSamplePath = const Value.absent(),
              }) => PersonsCompanion(
                id: id,
                name: name,
                faceSamplePath: faceSamplePath,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> faceSamplePath = const Value.absent(),
              }) => PersonsCompanion.insert(
                id: id,
                name: name,
                faceSamplePath: faceSamplePath,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PersonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({detectedFacesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (detectedFacesRefs) db.detectedFaces,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (detectedFacesRefs)
                    await $_getPrefetchedData<
                      Person,
                      $PersonsTable,
                      DetectedFace
                    >(
                      currentTable: table,
                      referencedTable: $$PersonsTableReferences
                          ._detectedFacesRefsTable(db),
                      managerFromTypedResult: (p0) => $$PersonsTableReferences(
                        db,
                        table,
                        p0,
                      ).detectedFacesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.personId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PersonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersonsTable,
      Person,
      $$PersonsTableFilterComposer,
      $$PersonsTableOrderingComposer,
      $$PersonsTableAnnotationComposer,
      $$PersonsTableCreateCompanionBuilder,
      $$PersonsTableUpdateCompanionBuilder,
      (Person, $$PersonsTableReferences),
      Person,
      PrefetchHooks Function({bool detectedFacesRefs})
    >;
typedef $$DetectedFacesTableCreateCompanionBuilder =
    DetectedFacesCompanion Function({
      Value<int> id,
      required int photoId,
      Value<int?> personId,
      required double x,
      required double y,
      required double width,
      required double height,
      Value<String?> faceThumbnailPath,
      Value<String?> embedding,
    });
typedef $$DetectedFacesTableUpdateCompanionBuilder =
    DetectedFacesCompanion Function({
      Value<int> id,
      Value<int> photoId,
      Value<int?> personId,
      Value<double> x,
      Value<double> y,
      Value<double> width,
      Value<double> height,
      Value<String?> faceThumbnailPath,
      Value<String?> embedding,
    });

final class $$DetectedFacesTableReferences
    extends BaseReferences<_$AppDatabase, $DetectedFacesTable, DetectedFace> {
  $$DetectedFacesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PhotosTable _photoIdTable(_$AppDatabase db) =>
      db.photos.createAlias('detected_faces__photo_id__photos__id');

  $$PhotosTableProcessedTableManager get photoId {
    final $_column = $_itemColumn<int>('photo_id')!;

    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_photoIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PersonsTable _personIdTable(_$AppDatabase db) =>
      db.persons.createAlias('detected_faces__person_id__persons__id');

  $$PersonsTableProcessedTableManager? get personId {
    final $_column = $_itemColumn<int>('person_id');
    if ($_column == null) return null;
    final manager = $$PersonsTableTableManager(
      $_db,
      $_db.persons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_personIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DetectedFacesTableFilterComposer
    extends Composer<_$AppDatabase, $DetectedFacesTable> {
  $$DetectedFacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faceThumbnailPath => $composableBuilder(
    column: $table.faceThumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnFilters(column),
  );

  $$PhotosTableFilterComposer get photoId {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableFilterComposer get personId {
    final $$PersonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableFilterComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectedFacesTableOrderingComposer
    extends Composer<_$AppDatabase, $DetectedFacesTable> {
  $$DetectedFacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get x => $composableBuilder(
    column: $table.x,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get y => $composableBuilder(
    column: $table.y,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faceThumbnailPath => $composableBuilder(
    column: $table.faceThumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get embedding => $composableBuilder(
    column: $table.embedding,
    builder: (column) => ColumnOrderings(column),
  );

  $$PhotosTableOrderingComposer get photoId {
    final $$PhotosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableOrderingComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableOrderingComposer get personId {
    final $$PersonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableOrderingComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectedFacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetectedFacesTable> {
  $$DetectedFacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get x =>
      $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y =>
      $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get faceThumbnailPath => $composableBuilder(
    column: $table.faceThumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get embedding =>
      $composableBuilder(column: $table.embedding, builder: (column) => column);

  $$PhotosTableAnnotationComposer get photoId {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.photoId,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PersonsTableAnnotationComposer get personId {
    final $$PersonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.personId,
      referencedTable: $db.persons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PersonsTableAnnotationComposer(
            $db: $db,
            $table: $db.persons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DetectedFacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DetectedFacesTable,
          DetectedFace,
          $$DetectedFacesTableFilterComposer,
          $$DetectedFacesTableOrderingComposer,
          $$DetectedFacesTableAnnotationComposer,
          $$DetectedFacesTableCreateCompanionBuilder,
          $$DetectedFacesTableUpdateCompanionBuilder,
          (DetectedFace, $$DetectedFacesTableReferences),
          DetectedFace,
          PrefetchHooks Function({bool photoId, bool personId})
        > {
  $$DetectedFacesTableTableManager(_$AppDatabase db, $DetectedFacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectedFacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectedFacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectedFacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> photoId = const Value.absent(),
                Value<int?> personId = const Value.absent(),
                Value<double> x = const Value.absent(),
                Value<double> y = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<String?> faceThumbnailPath = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
              }) => DetectedFacesCompanion(
                id: id,
                photoId: photoId,
                personId: personId,
                x: x,
                y: y,
                width: width,
                height: height,
                faceThumbnailPath: faceThumbnailPath,
                embedding: embedding,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int photoId,
                Value<int?> personId = const Value.absent(),
                required double x,
                required double y,
                required double width,
                required double height,
                Value<String?> faceThumbnailPath = const Value.absent(),
                Value<String?> embedding = const Value.absent(),
              }) => DetectedFacesCompanion.insert(
                id: id,
                photoId: photoId,
                personId: personId,
                x: x,
                y: y,
                width: width,
                height: height,
                faceThumbnailPath: faceThumbnailPath,
                embedding: embedding,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DetectedFacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({photoId = false, personId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (photoId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.photoId,
                                referencedTable: $$DetectedFacesTableReferences
                                    ._photoIdTable(db),
                                referencedColumn: $$DetectedFacesTableReferences
                                    ._photoIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (personId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.personId,
                                referencedTable: $$DetectedFacesTableReferences
                                    ._personIdTable(db),
                                referencedColumn: $$DetectedFacesTableReferences
                                    ._personIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DetectedFacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DetectedFacesTable,
      DetectedFace,
      $$DetectedFacesTableFilterComposer,
      $$DetectedFacesTableOrderingComposer,
      $$DetectedFacesTableAnnotationComposer,
      $$DetectedFacesTableCreateCompanionBuilder,
      $$DetectedFacesTableUpdateCompanionBuilder,
      (DetectedFace, $$DetectedFacesTableReferences),
      DetectedFace,
      PrefetchHooks Function({bool photoId, bool personId})
    >;
typedef $$FolderSyncTableCreateCompanionBuilder =
    FolderSyncCompanion Function({
      required String folderId,
      required DateTime lastSync,
      Value<int> rowid,
    });
typedef $$FolderSyncTableUpdateCompanionBuilder =
    FolderSyncCompanion Function({
      Value<String> folderId,
      Value<DateTime> lastSync,
      Value<int> rowid,
    });

class $$FolderSyncTableFilterComposer
    extends Composer<_$AppDatabase, $FolderSyncTable> {
  $$FolderSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderSyncTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderSyncTable> {
  $$FolderSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get folderId => $composableBuilder(
    column: $table.folderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSync => $composableBuilder(
    column: $table.lastSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderSyncTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderSyncTable> {
  $$FolderSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get folderId =>
      $composableBuilder(column: $table.folderId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSync =>
      $composableBuilder(column: $table.lastSync, builder: (column) => column);
}

class $$FolderSyncTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FolderSyncTable,
          FolderSyncData,
          $$FolderSyncTableFilterComposer,
          $$FolderSyncTableOrderingComposer,
          $$FolderSyncTableAnnotationComposer,
          $$FolderSyncTableCreateCompanionBuilder,
          $$FolderSyncTableUpdateCompanionBuilder,
          (
            FolderSyncData,
            BaseReferences<_$AppDatabase, $FolderSyncTable, FolderSyncData>,
          ),
          FolderSyncData,
          PrefetchHooks Function()
        > {
  $$FolderSyncTableTableManager(_$AppDatabase db, $FolderSyncTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> folderId = const Value.absent(),
                Value<DateTime> lastSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderSyncCompanion(
                folderId: folderId,
                lastSync: lastSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String folderId,
                required DateTime lastSync,
                Value<int> rowid = const Value.absent(),
              }) => FolderSyncCompanion.insert(
                folderId: folderId,
                lastSync: lastSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FolderSyncTable,
      FolderSyncData,
      $$FolderSyncTableFilterComposer,
      $$FolderSyncTableOrderingComposer,
      $$FolderSyncTableAnnotationComposer,
      $$FolderSyncTableCreateCompanionBuilder,
      $$FolderSyncTableUpdateCompanionBuilder,
      (
        FolderSyncData,
        BaseReferences<_$AppDatabase, $FolderSyncTable, FolderSyncData>,
      ),
      FolderSyncData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$AlbumsTableTableManager get albums =>
      $$AlbumsTableTableManager(_db, _db.albums);
  $$AlbumPhotosTableTableManager get albumPhotos =>
      $$AlbumPhotosTableTableManager(_db, _db.albumPhotos);
  $$PersonsTableTableManager get persons =>
      $$PersonsTableTableManager(_db, _db.persons);
  $$DetectedFacesTableTableManager get detectedFaces =>
      $$DetectedFacesTableTableManager(_db, _db.detectedFaces);
  $$FolderSyncTableTableManager get folderSync =>
      $$FolderSyncTableTableManager(_db, _db.folderSync);
}
