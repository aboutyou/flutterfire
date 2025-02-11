// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import '../interop/firestore.dart' as firestore_interop;
import '../interop/firestore_interop.dart'
    hide GetOptions, SetOptions, FieldPath;
import '../utils/decode_utility.dart';

const _kChangeTypeAdded = 'added';
const _kChangeTypeModified = 'modified';
const _kChangeTypeRemoved = 'removed';

String getServerTimestampBehaviorString(
  ServerTimestampBehavior serverTimestampBehavior,
) {
  switch (serverTimestampBehavior) {
    case ServerTimestampBehavior.none:
      return 'none';
    case ServerTimestampBehavior.estimate:
      return 'estimate';
    case ServerTimestampBehavior.previous:
      return 'previous';
  }
}

/// Converts a [web.QuerySnapshot] to a [QuerySnapshotPlatform].
QuerySnapshotPlatform convertWebQuerySnapshot(
    FirebaseFirestorePlatform firestore,
    firestore_interop.QuerySnapshot webQuerySnapshot,
    ServerTimestampBehavior serverTimestampBehavior) {
  return QuerySnapshotPlatform(
    webQuerySnapshot.docs
        .map((webDocumentSnapshot) => convertWebDocumentSnapshot(
              firestore,
              webDocumentSnapshot!,
              serverTimestampBehavior,
            ))
        .toList(),
    webQuerySnapshot
        .docChanges()
        .map((webDocumentChange) => convertWebDocumentChange(
              firestore,
              webDocumentChange,
              serverTimestampBehavior,
            ))
        .toList(),
    convertWebSnapshotMetadata(webQuerySnapshot.metadata),
  );
}

/// Converts a [web.DocumentSnapshot] to a [DocumentSnapshotPlatform].
DocumentSnapshotPlatform convertWebDocumentSnapshot(
  FirebaseFirestorePlatform firestore,
  firestore_interop.DocumentSnapshot webSnapshot,
  ServerTimestampBehavior serverTimestampBehavior,
) {
  return DocumentSnapshotPlatform(
    firestore,
    webSnapshot.ref!.path,
    DecodeUtility.decodeMapData(
      webSnapshot.data(SnapshotOptions(
        serverTimestamps:
            getServerTimestampBehaviorString(serverTimestampBehavior).toJS,
      )),
      firestore,
    ),
    PigeonSnapshotMetadata(
      hasPendingWrites: webSnapshot.metadata.hasPendingWrites.toDart,
      isFromCache: webSnapshot.metadata.fromCache.toDart,
    ),
  );
}

/// Converts a [web.DocumentChange] to a [DocumentChangePlatform].
DocumentChangePlatform convertWebDocumentChange(
  FirebaseFirestorePlatform firestore,
  firestore_interop.DocumentChange webDocumentChange,
  ServerTimestampBehavior serverTimestampBehavior,
) {
  return DocumentChangePlatform(
      convertWebDocumentChangeType(webDocumentChange.type),
      webDocumentChange.oldIndex as int,
      webDocumentChange.newIndex as int,
      convertWebDocumentSnapshot(
        firestore,
        webDocumentChange.doc!,
        serverTimestampBehavior,
      ));
}

/// Converts a [web.DocumentChange] type into a [DocumentChangeType].
DocumentChangeType convertWebDocumentChangeType(String changeType) {
  switch (changeType.toLowerCase()) {
    case _kChangeTypeAdded:
      return DocumentChangeType.added;
    case _kChangeTypeModified:
      return DocumentChangeType.modified;
    case _kChangeTypeRemoved:
      return DocumentChangeType.removed;
    default:
      throw UnsupportedError('Unknown DocumentChangeType: $changeType.');
  }
}

/// Converts a [web.SnapshotMetadata] to a [SnapshotMetadataPlatform].
SnapshotMetadataPlatform convertWebSnapshotMetadata(
    firestore_interop.SnapshotMetadata webSnapshotMetadata) {
  return SnapshotMetadataPlatform(webSnapshotMetadata.hasPendingWrites.toDart,
      webSnapshotMetadata.fromCache.toDart);
}

/// Converts a [GetOptions] to a [web.GetOptions].
firestore_interop.GetOptions? convertGetOptions(GetOptions? options) {
  if (options == null) return null;

  String? source;

  switch (options.source) {
    case Source.serverAndCache:
      source = 'default';
      break;
    case Source.cache:
      source = 'cache';
      break;
    case Source.server:
      source = 'server';
      break;
    default:
      source = 'default';
      break;
  }

  return firestore_interop.GetOptions(source: source.toJS);
}

/// Converts a [SetOptions] to a [web.SetOptions].
firestore_interop.SetOptions? convertSetOptions(SetOptions? options) {
  if (options == null) return null;

  firestore_interop.SetOptions? parsedOptions;
  if (options.merge != null) {
    parsedOptions = firestore_interop.SetOptions(merge: options.merge?.toJS);
  } else if (options.mergeFields != null) {
    parsedOptions = firestore_interop.SetOptions(
        mergeFields: options.mergeFields!
            .map((e) => e.components.toList().join('.').toJS)
            .toList()
            .toJSBox as JSArray);
  }

  return parsedOptions;
}

/// Converts a [FieldPath] to a [web.FieldPath].
firestore_interop.FieldPath convertFieldPath(FieldPath fieldPath) {
  return firestore_interop.FieldPath(
      fieldPath.components.toList().join('.').toJS);
}
