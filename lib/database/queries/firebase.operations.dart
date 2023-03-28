import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

class FirebaseOperations {
  final noteRef = db.collection('notes');
  Future<void> addNote() async {
    QuerySnapshot docsToUpdate = await noteRef.get();

    FieldValue increment = FieldValue.increment(1);

    WriteBatch batch = db.batch();

    for (var doc in docsToUpdate.docs) {
      batch.set(
          noteRef.doc(doc.id), {'index': increment}, SetOptions(merge: true));
    }

    await batch.commit();

    await noteRef.add({
      'title': 'Enter title here',
      'note': '',
      'index': 0,
    });
  }

  Future<void> deleteNote(id) async {
    DocumentSnapshot currentDoc = await noteRef.doc(id).get();

    int index = currentDoc.get('index');

    // decrement all documents above the current

    QuerySnapshot documentsToBeDecremented =
        await noteRef.where('index', isGreaterThan: index).get();

    // batch the higher indexes to be decremented

    FieldValue decrement = FieldValue.increment(-1);

    WriteBatch batch = db.batch();

    SetOptions opt = SetOptions(merge: true);

    for (var doc in documentsToBeDecremented.docs) {
      batch.set(noteRef.doc(doc.id), {"index": decrement}, opt);
    }

    batch.delete(noteRef.doc(id));

    await batch.commit();
  }

  void reorderItems(oldIndex, newIndex) async {
    bool forward = false;

    if (newIndex > oldIndex) {
      newIndex--;

      forward = true;
    }

    if (forward) {
      // oldIndex to newIndex will be decremented

      FieldValue decrement = FieldValue.increment(-1);

      QuerySnapshot docsToUpdate = await noteRef
          .where('index',
              isGreaterThan: oldIndex, isLessThanOrEqualTo: newIndex)
          .get();

      QuerySnapshot currentDoc =
          await noteRef.where('index', isEqualTo: oldIndex).get();

      WriteBatch batch = db.batch();

      for (var doc in docsToUpdate.docs) {
        batch.set(
            noteRef.doc(doc.id), {'index': decrement}, SetOptions(merge: true));
      }

      batch.set(noteRef.doc(currentDoc.docs.first.id), {'index': newIndex},
          SetOptions(merge: true));

      await batch.commit();
    } else if (oldIndex > newIndex) {
      // newIndex to oldIndex-1 will be incremented

      FieldValue increment = FieldValue.increment(1);

      QuerySnapshot docsToUpdate = await noteRef
          .where('index',
              isGreaterThanOrEqualTo: newIndex, isLessThan: oldIndex)
          .get();

      QuerySnapshot currentDoc =
          await noteRef.where('index', isEqualTo: oldIndex).get();

      WriteBatch batch = db.batch();

      for (var doc in docsToUpdate.docs) {
        batch.set(
            noteRef.doc(doc.id), {'index': increment}, SetOptions(merge: true));
      }

      batch.set(noteRef.doc(currentDoc.docs.first.id), {'index': newIndex},
          SetOptions(merge: true));

      await batch.commit();
    }
  }

  Future<void> updatePath({path, docId}) async {
    String? deviceId;
    final DeviceInfoPlugin info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await info.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await info.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    } else if (Platform.isMacOS) {
      MacOsDeviceInfo macInfo = await info.macOsInfo;
      deviceId = macInfo.hostName;
    }

    if (deviceId != null && deviceId.isNotEmpty) {
      noteRef.doc(docId).set({
        'path': {deviceId: path}
      }, SetOptions(merge: true));
    }
  }
}
