// ignore_for_file: file_names

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:write_by_hyde/providers/noteProvider.dart';

final musicTileProvider =
    StateNotifierProvider<MusicTileNotifier, List<MusicTileData>>(
        (ref) => MusicTileNotifier(ref));

class MusicTileNotifier extends StateNotifier<List<MusicTileData>> {
  final StateNotifierProviderRef ref;
  MusicTileNotifier(this.ref) : super([]);

  void openNote(index) {
    var data = state;
    data[index].openNote = !data[index].openNote;
    state = [...data];
    // state[index].openNote = !state[index].openNote;
  }

  void addTiles(List<NoteStruct> tiles) {
    // create the new musicTiles

    List<MusicTileData> newTiles = <MusicTileData>[];

    for (NoteStruct tile in tiles) {
      newTiles.add(MusicTileData(
          sliderMaxValue: 1.0,
          isPlaying: false,
          openNote: false,
          showTileOptions: false,
          assetsAudioPlayer: AssetsAudioPlayer(),
          noteController: TextEditingController(text: tile.note)));
    }

    for (int i = 0; i < newTiles.length; i++) {
      state.insert(i, newTiles[i]);
    }

    for (int i = 0; i < tiles.length; i++) {
      // ignore: unnecessary_null_comparison
      if (tiles[i].path != null && tiles[i].path != '') {
        state[i]
            .assetsAudioPlayer
            .open(
              Audio.file(tiles[i].path!, metas: Metas(title: tiles[i].title)),
              autoStart: false,
              showNotification: true,
              loopMode: LoopMode.single,
            )
            .then((value) => setSliderMaxValue(
                index: i,
                value: state[i]
                    .assetsAudioPlayer
                    .current
                    .value!
                    .audio
                    .duration
                    .inSeconds
                    .toDouble()));
      }
    }
  }

  void removeTiles(indexes) {
    // to remove the tile we will need it's index in the current state
    // index has the indexes of tiles to remove

    List<MusicTileData> tempState = [...state];
    int removedCount = 0;

    for (int index in indexes) {
      tempState[index - removedCount].assetsAudioPlayer.dispose();

      tempState.removeAt(index - removedCount);
      removedCount++;
    }

    state = [...tempState];
  }

  void togglePlaying(index) {
    var data = state;
    data[index].isPlaying = !data[index].isPlaying;
    state = [...data];
  }

  void showTileOptions(index) {
    var data = state;
    data[index].showTileOptions = true;
    state = [...data];
  }

  void hideTileOptions(index) {
    var data = state;
    data[index].showTileOptions = false;
    state = [...data];
  }

  void setSliderMaxValue({index, value}) {
    var data = state;
    data[index].sliderMaxValue = value;
    state = [...data];
  }

  void reorderTiles(oldIndex, newIndex) {
    if (newIndex > oldIndex) newIndex--;
    var temp = state[oldIndex];

    state.removeAt(oldIndex);
    state.insert(newIndex, temp);
  }
}

class MusicTileData {
  double sliderMaxValue;
  bool openNote;
  bool showTileOptions;
  bool isPlaying;
  final AssetsAudioPlayer assetsAudioPlayer;
  TextEditingController noteController;

  MusicTileData(
      {required this.sliderMaxValue,
      required this.isPlaying,
      required this.openNote,
      required this.showTileOptions,
      required this.assetsAudioPlayer,
      required this.noteController});
}
