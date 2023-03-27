// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:platform_device_id/platform_device_id.dart';
import 'package:write_by_hyde/providers/musicTileProvider.dart';

FirebaseFirestore database = FirebaseFirestore.instance;

final noteStreamProvider = StreamProvider<List<NoteStruct>>((ref) {
  final noteRef = database.collection('notes');

  List<NoteStruct> prev = [];

  String? deviceId;

  PlatformDeviceId.getDeviceId.then((value) => deviceId = value);

  final data = noteRef.snapshots().map((e) {
    List<NoteStruct> noteList = <NoteStruct>[];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> noteSnapshots = e.docs;
    for (var noteSnapshot in noteSnapshots) {
      noteList.add(NoteStruct(
          noteSnapshot.get('index'),
          noteSnapshot.id,
          noteSnapshot.get('note'),
          noteSnapshot.get('title'),
          noteSnapshot.data().containsKey('path')
              ? noteSnapshot.get('path')[deviceId]
              : null));
    }

    noteList.sort(((a, b) => a.index - b.index));

    if (noteList.length != prev.length) {
      if (noteList.length < prev.length) {
        // CASE: element deleted

        List<int> deletedIndexes = <int>[];

        for (int i = 0; i < prev.length; i++) {
          if (!noteList.any((e) => e.id == prev[i].id)) {
            deletedIndexes.add(i);
          }
        }

        // handle elements deleted

        ref.read(musicTileProvider.notifier).removeTiles(deletedIndexes);
      } else {
        //CASE: element added

        List<NoteStruct> addedElements = [];

        for (NoteStruct noteInstance in noteList) {
          if (!prev.any((e) => e.id == noteInstance.id)) {
            addedElements.add(noteInstance);
          }
        }

        // handle elements added

        ref.read(musicTileProvider.notifier).addTiles(addedElements);
      }
    }

    prev = noteList;

    return noteList;
  });

  return data;
});

class NoteStruct {
  int index;
  String id;
  String note;
  String title;
  String path;

  NoteStruct(this.index, this.id, this.note, this.title, this.path);
}
