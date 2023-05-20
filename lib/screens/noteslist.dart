import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:write_by_hyde/database/queries/firebase.operations.dart';
import 'package:write_by_hyde/providers/musicTileProvider.dart';
import 'package:write_by_hyde/providers/noteProvider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:write_by_hyde/widgets/musicPlayerTile.dart';

List notes = [];

FirebaseOperations fo = FirebaseOperations();

class NotesList extends ConsumerWidget {
  const NotesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Stack(
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Helix",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),

                  // ANCHOR: ADD NOTES
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                        onPressed: () => fo.addNote(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                        icon: const Icon(
                          Icons.edit_note,
                          size: 40,
                        )),
                  )
                ],
              ),
            ),
          ),
          const Flexible(
              flex: 8,
              fit: FlexFit.tight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: ScrollableNotesList(),
              )),
        ],
      ),
    ));
  }
}

class ScrollableNotesList extends ConsumerStatefulWidget {
  const ScrollableNotesList({super.key});

  @override
  ConsumerState<ScrollableNotesList> createState() =>
      _ScrollableNotesListState();
}

class _ScrollableNotesListState extends ConsumerState<ScrollableNotesList> {
  @override
  Widget build(BuildContext context) {
    var notes = ref.watch(noteStreamProvider);
    int notesLength = (notes.hasValue) ? notes.value!.length : 0;

    if (notes.isLoading) {
      return const Center(
          child: SizedBox(
        height: 50,
        width: 50,
        child: CircularProgressIndicator.adaptive(value: null),
      ));
    }

    // Main list view
    return RefreshIndicator(
      onRefresh: () {
        notes = ref.watch(noteStreamProvider);
        return Future(() => null);
      },
      child: ReorderableListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: notesLength,
          onReorder: (oldIndex, newIndex) {
            setState(() {});
            fo.reorderItems(oldIndex, newIndex);
            ref
                .read(musicTileProvider.notifier)
                .reorderTiles(oldIndex, newIndex);
          },
          buildDefaultDragHandles: true,
          itemBuilder: (context, index) {
            // adding padding to the view
            return Padding(
              key: ValueKey(notes.value![index].id),
              padding:
                  const EdgeInsets.only(top: 15, bottom: 10, left: 5, right: 5),
              child: MusicPlayerTile(index: index),
            );
          }),
    );
  }

  Future<File> saveFileToAppDirectory(PlatformFile file) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final newFile = File('${appStorage.path}/${file.name}');

    return File(file.path!).copy(newFile.path);
  }
}
