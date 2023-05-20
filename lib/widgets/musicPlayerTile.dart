// ignore_for_file: file_names

import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:write_by_hyde/database/queries/firebase.operations.dart';
import 'package:write_by_hyde/providers/musicTileProvider.dart';
import 'package:write_by_hyde/providers/noteProvider.dart';
import 'dart:math' as math;

FirebaseFirestore db = FirebaseFirestore.instance;

FirebaseOperations fo = FirebaseOperations();

class MusicPlayerTile extends ConsumerStatefulWidget {
  // ignore: prefer_typing_uninitialized_variables
  final index;

  const MusicPlayerTile({super.key, @required this.index});

  @override
  ConsumerState<MusicPlayerTile> createState() => _MusicPlayerTileState();
}

class _MusicPlayerTileState extends ConsumerState<MusicPlayerTile> {
  static const musicIconColors = [
    Colors.green,
    Colors.blue,
    Colors.pink,
    Colors.purple,
    Colors.amber,
    Colors.white
  ];

  @override
  Widget build(BuildContext context) {
    // return a music player tile widget that will have details from the given index of the provider

    TextEditingController titleController = TextEditingController(
        text: ref.read(noteStreamProvider).value![widget.index].title);

    int index = widget.index;

    MusicTileData tileData = ref.watch(musicTileProvider)[index];
    var noteData = ref.watch(noteStreamProvider).value![index];

    bool isPlaying = ref.watch(musicTileProvider)[index].isPlaying;
    double sliderMaxValue = ref.watch(musicTileProvider)[index].sliderMaxValue;

    return Slidable(
      startActionPane: ActionPane(motion: const ScrollMotion(), children: [
        // delete button
        SlidableAction(
          onPressed: (context) {
            fo.deleteNote(noteData.id);
          },
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.red,
          icon: Icons.delete,
          label: 'Delete',
        )
      ]),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(6, 255, 255, 255)),
            color: const Color.fromARGB(35, 255, 255, 255),
            borderRadius: BorderRadius.circular(45)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 20, 20),
          child: Column(
            children: [
              // TITLE ROW

              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 15),
                          child: Icon(Icons.music_note_rounded,
                              color: musicIconColors[
                                  index % musicIconColors.length]),
                        ),

                        // TITLE
                        Expanded(
                          child: TextField(
                            decoration:
                                const InputDecoration(border: InputBorder.none),
                            style: Theme.of(context).textTheme.bodyMedium,
                            controller: titleController,
                            onSubmitted: (value) {
                              db
                                  .collection('notes')
                                  .doc(ref
                                      .read(noteStreamProvider)
                                      .value![widget.index]
                                      .id)
                                  .update({'title': value});
                            },
                          ),
                        ),

                        // MUSIC SELECT BUTTON
                        Padding(
                          padding: const EdgeInsets.only(right: 3.0),
                          child: IconButton(
                              splashColor: Colors.black12,
                              icon: const Icon(Icons.library_music_rounded,
                                  size: 20),
                              onPressed: () async {
                                // open file system and select a file
                                try {
                                  FilePickerResult? result =
                                      await FilePicker.platform.pickFiles(
                                    dialogTitle: 'Select an audio file',
                                    type: FileType.audio,
                                    allowMultiple: false,
                                  );

                                  if (result != null) {
                                    // perma save the file

                                    File file = await saveFileToAppDirectory(
                                        result.files.first);

                                    await tileData.assetsAudioPlayer.open(
                                      Audio.file(result.paths.first!,
                                          metas: Metas(
                                              title: result.files.first.name
                                                  .substring(
                                                      0,
                                                      result.files.first.name
                                                              .length -
                                                          result
                                                              .files
                                                              .first
                                                              .extension!
                                                              .length -
                                                          1))),
                                      autoStart: false,
                                      showNotification: true,
                                    );

                                    fo.updatePath(
                                        path: file.path,
                                        docId: ref
                                            .read(noteStreamProvider)
                                            .value![index]
                                            .id);

                                    // db
                                    //     .collection('notes')
                                    //     .doc(ref
                                    //         .read(noteStreamProvider)
                                    //         .value![widget.index]
                                    //         .id)
                                    //     .set(
                                    //   {
                                    //     'path': file.path,
                                    //   },
                                    //   SetOptions(merge: true),
                                    // );

                                    ref
                                        .read(musicTileProvider.notifier)
                                        .setSliderMaxValue(
                                            index: index,
                                            value: tileData
                                                .assetsAudioPlayer
                                                .current
                                                .value!
                                                .audio
                                                .duration
                                                .inSeconds
                                                .toDouble());
                                  }
                                } catch (err) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor: Colors.red[600],
                                          content: Text(err.toString())));
                                }
                              }),
                        )
                      ],
                    )),
              ),
              // Player Row
              Padding(
                  padding:
                      const EdgeInsets.only(right: 15, bottom: 8, left: 10),
                  child: Row(
                    children: [
                      // Play Button
                      GestureDetector(
                          onTap: () async {
                            ref
                                .read(musicTileProvider.notifier)
                                .togglePlaying(index);

                            (!isPlaying)
                                ? tileData.assetsAudioPlayer.play()
                                : tileData.assetsAudioPlayer.pause();
                          },
                          child: Icon(
                            (!isPlaying) ? Icons.play_arrow : Icons.pause,
                            color: !isPlaying ? Colors.white : Colors.white,
                          )),

                      // Player
                      PlayerBuilder.currentPosition(
                        player: tileData.assetsAudioPlayer,
                        builder: (context, duration) => Expanded(
                          child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                SfSlider(
                                  value: duration.inSeconds.toDouble(),
                                  max: ref
                                      .watch(musicTileProvider)[index]
                                      .sliderMaxValue,
                                  onChanged: (val) {
                                    setState(() {});
                                    tileData.assetsAudioPlayer
                                        .seek(Duration(seconds: val.toInt()));
                                  },

                                  activeColor:
                                      const Color.fromARGB(222, 255, 255, 255),
                                  inactiveColor:
                                      const Color.fromARGB(97, 217, 0, 255),
                                  // inactiveColor:
                                  //     const Color.fromARGB(82, 255, 255, 255),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: Text(
                                    (sliderMaxValue != 1.0)
                                        ? '${duration.inSeconds ~/ 60}:${(duration.inSeconds % 60).toInt()} / ${sliderMaxValue ~/ 60}:${(sliderMaxValue % 60).toInt()}'
                                        : '',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                )
                              ]),
                        ),
                      ),

                      // Note Icon
                      GestureDetector(
                        onTap: () {
                          ref.read(musicTileProvider.notifier).openNote(index);
                        },
                        child: const Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Icon(Icons.notes),
                          ),
                        ),
                      ),
                    ],
                  )),

              (tileData.openNote)
                  ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:

                              // The Save and Revert Buttons

                              (tileData.showTileOptions)
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              tileData.noteController.text =
                                                  noteData.note;
                                            },
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Text(
                                                    'Revert',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                  Icon(
                                                    Icons.undo,
                                                    color: Colors.white,
                                                  )
                                                ]),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              // db call to store the data in the note

                                              db
                                                  .collection('notes')
                                                  .doc(ref
                                                      .read(noteStreamProvider)
                                                      .value![index]
                                                      .id)
                                                  .update({
                                                'note': tileData
                                                    .noteController.text,
                                              });

                                              ref
                                                  .read(musicTileProvider
                                                      .notifier)
                                                  .hideTileOptions(index);
                                            },
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  Text(
                                                    'Save',
                                                    style: TextStyle(
                                                        color: Colors.green),
                                                  ),
                                                  Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                  )
                                                ]),
                                          ),
                                        )
                                      ],
                                    )
                                  : Container(),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 15.0),

                              // Notes text field
                              child: TextField(
                                  expands: true,
                                  maxLines: null,
                                  minLines: null,
                                  textAlignVertical: TextAlignVertical.top,
                                  controller: tileData.noteController,
                                  onChanged: (value) {
                                    if (noteData.note != value) {
                                      ref
                                          .read(musicTileProvider.notifier)
                                          .showTileOptions(index);
                                    } else {
                                      ref
                                          .read(musicTileProvider.notifier)
                                          .hideTileOptions(index);
                                    }
                                  },
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  keyboardType: TextInputType.multiline),
                            )),
                      ],
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}

Future<File> saveFileToAppDirectory(PlatformFile file) async {
  final appStorage = await getApplicationDocumentsDirectory();
  final newFile = File('${appStorage.path}/${file.name}');

  return File(file.path!).copy(newFile.path);
}
