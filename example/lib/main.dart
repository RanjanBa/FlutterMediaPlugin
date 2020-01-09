import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_media_plugin/exo_player_listener.dart';
import 'package:flutter_media_plugin/flutter_media_plugin.dart';
import 'package:flutter_media_plugin/playlist.dart';
import 'package:flutter_media_plugin_example/songs.dart';
import 'package:flutter_media_plugin/audio_player.dart';
import 'package:flutter_media_plugin/download_manager.dart';
import 'package:flutter_media_plugin/video_player.dart';

AudioPlayer _audioPlayer;
VideoPlayer _videoPlayer;
DownloadManager _downloadManager;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterMediaPlugin();

  _audioPlayer = FlutterMediaPlugin.audioPlayer;
  _videoPlayer = FlutterMediaPlugin.videoPlayer;
  _downloadManager = FlutterMediaPlugin.downloadManager;

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _position = 0, _audioLength = 0, _percent = 0;
  String _message = "";

  IconData _iconData;
  Function _function;

  Widget _bufferingWidget;

  ExoPlayerListener _exoPlayerListener;
  DownloadListener _downloadListener;
  VideoExoPlayerListener _videoExoPlayerListener;
  Playlist playlist;

//  String _assetUri = "assets/videos/birwiBirwi.mp4";
  String _uri =
      "https://firebasestorage.googleapis.com/v0/b/bodoentertainment-224710.appspot.com/o/videos%2FBaidisina.mp4?alt=media&token=afd3ca71-6f49-4fd5-926c-b8a053c85d27";

  int _textureId;
  int _repeatMode = 0;
  bool _shuffleModeEnabled = false;

  @override
  void initState() {
    super.initState();
    //flutterMediaPlugin.videoPlayer.initialize(TypeOfPlace.asset, null);
    _audioPlayer.playWhenReady
        ? _iconData = Icons.pause
        : _iconData = Icons.play_arrow;

    _exoPlayerListener = ExoPlayerListener(
      onPlayerStateChanged: _onPlayerStateChanged,
      onPlaybackUpdate: _onPlaybackUpdate,
      onBufferedUpdate: _onBufferedUpdate,
      onMediaPeriodCreated: _onMediaPeriodCreated,
      onPlayerStatus: _onPlayerStatus,
      onRepeatModeChanged: _onRepeatModeChanged,
      onShuffleModeEnabledChanged: _onShuffleModeEnabledChanged,
    );
    _audioPlayer.addExoPlayerListener(
      _exoPlayerListener,
    );

    _downloadListener = DownloadListener(onDownloadChanged: (state, id) {
      print('Flutter main $state $id');
    });

    _downloadManager.addDownloadListener(_downloadListener);

    _videoExoPlayerListener =
        VideoExoPlayerListener(onVideoInitialize: _onVideoInitialized);
    _videoPlayer.addVideoExoPlayer(_videoExoPlayerListener);

    _setIcons();
    _bufferingWidget = SizedBox(
      height: 0,
      width: 0,
    );

    playlist = new Playlist("New Playlist");

    for (Song s in Samples.songs) {
      playlist.addSong(s);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.removeExoPlayerListener(_exoPlayerListener);
    if (_downloadManager != null) {
      _downloadManager.removeDownloadListener(_downloadListener);
    }
    _videoPlayer.removeVideoExoPlayer(_videoExoPlayerListener);
//    print("Main dispose");
  }

  void addAndPlay() {
    _videoPlayer.addAndPlay(TypeOfPlace.network, _uri);
  }

  void _setIcons() {
    if (_audioPlayer.playWhenReady) {
      _iconData = Icons.pause;
      _function = _audioPlayer.pause;
    } else {
      _iconData = Icons.play_arrow;
      _function = _audioPlayer.play;
    }
  }

  void _onVideoInitialized(int textureId) {
    _textureId = textureId;
    print("Texture id $_textureId");
    setState(() {});
  }

  void _onPlayerStatus(String message) {
    _message = message;
    if (!mounted) return;

    setState(() {});
  }

  void _onPlayerStateChanged(bool playWhenReady, int playbackState) {
    if (!mounted) return;

    setState(() {
      if (playbackState == C.STATE_BUFFERING) {
        _bufferingWidget = Center(
          child: CircularProgressIndicator(),
        );
      } else {
        _bufferingWidget = SizedBox(
          height: 0,
          width: 0,
        );
      }
      _setIcons();
    });
  }

  void _onPlaybackUpdate(int position, int audioLength) {
    _position = position;
    _audioLength = audioLength;

    if (!mounted) return;

    setState(() {});
  }

  void _onBufferedUpdate(int percent) {
    _percent = percent;

    if (!mounted) return;

    setState(() {});
  }

  String currentlyPlayingSongTitle = "";

  void _onMediaPeriodCreated(int windowIndex) {
    print("window index : $windowIndex");
    if (!mounted) return;
    _audioLength = 0;
    _position = 0;
    setCurrentSong(windowIndex);
  }

  void _onRepeatModeChanged(int repeatMode) {
    setState(() {
      _repeatMode = repeatMode;
    });
  }

  void _onShuffleModeEnabledChanged(bool shuffleModeEnabled) {
    setState(() {
      _shuffleModeEnabled = shuffleModeEnabled;
    });
  }

  void setCurrentSong(int windowIndex) async {
    Playlist playlist = await _audioPlayer.getPlaylist();
//    print("length ${playlist.getSize()}");
    Song song = playlist.getSongAtIndex(windowIndex);
    if (song == null)
      currentlyPlayingSongTitle = "No Song";
    else
      currentlyPlayingSongTitle = song.title;
    setState(() {});
  }

  void _seekTo(double percent) {
    int position = (percent * _audioLength).toInt();
    _audioPlayer.seekTo(position);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                _videoPlayer.initSetTexture();
                //_audioPlayer.setPlaylistAndSongIndex(playlist, 0);
              },
            ),
            IconButton(
              icon: Icon(Icons.playlist_add),
              onPressed: () {
                addAndPlay();
                //_audioPlayer.setPlaylistAndSongIndex(playlist, 0);
              },
            ),
          ],
        ),
        body: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                children: <Widget>[
                  Text(
                    "${(_position ~/ 1000) ~/ 60}:${(_position ~/ 1000) % 60}",
                    textAlign: TextAlign.center,
                  ),
                  Expanded(
                    flex: 4,
                    child: Slider(
                      value: _audioLength != 0
                          ? (_position / _audioLength)
                              .toDouble()
                              .clamp(0.0, 1.0)
                          : 0.0,
                      onChanged: (_value) => _seekTo(_value),
                    ),
                  ),
                  Text(
                    "${(_audioLength ~/ 1000) ~/ 60}:${(_audioLength ~/ 1000) % 60}",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _bufferingWidget,
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    child: Icon(Icons.skip_previous),
                    onPressed: () {
                      _audioPlayer.skipToPrevious();
                    },
                  ),
                  RaisedButton(
                      child: Icon(_iconData),
                      onPressed: () {
                        _function();
                      }),
                  RaisedButton(
                      child: Icon(Icons.skip_next),
                      onPressed: () {
                        _audioPlayer.skipToNext();
                      }),
                ],
              ),
            ),
            Center(
              child: Text(currentlyPlayingSongTitle),
            ),
            Center(
              child: RaisedButton(
                onPressed: () async {
                  int cMode = await _audioPlayer.getRepeatMode();
                  _audioPlayer.setRepeatMode((cMode + 1) % 3);
                },
                child: Text("RepeatMode Change"),
              ),
            ),
            Center(child: Text("repeat mode : $_repeatMode")),
            Center(
              child: RaisedButton(
                onPressed: () async {
                  bool cShuffle = await _audioPlayer.getShuffleModeEnabled();
                  _audioPlayer.setShuffleModeEnabled(!cShuffle);
                },
                child: Text("ShuffleMode Change"),
              ),
            ),
            Center(child: Text("shuffle mode : $_shuffleModeEnabled")),
            ListView.builder(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    '${Samples.songs[index].title}',
                  ),
                  onTap: () async {
                    await _audioPlayer.setPlaylist(playlist);
                    _audioPlayer.skipToIndex(index);
                  },
                  onLongPress: () {
                    _audioPlayer.addAndPlay(Samples.songs[index]);
                  },
                  trailing: FutureBuilder<bool>(
                    future: _downloadManager.isDownloaded(
                        Samples.songs[index].url),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
//                        print('data ${snapshot.data}');
                        if (snapshot.data == false)
                          return IconButton(
                            icon: Icon(Icons.file_download),
                            onPressed: () {
                              _downloadManager.download(
                                  Samples.songs[index].url);
                            },
                          );
                        else {
                          return IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _downloadManager.downloadRemove(
                                  Samples.songs[index].url);
                            },
                          );
                        }
                      } else {
                        return CircularProgressIndicator();
                      }
                    },
                  ),
                );
              },
              itemCount: Samples.songs.length,
            ),
            Container(
              child: Text(_message),
            ),
            Container(
              height: 600,
              width: 50,
              color: Colors.red,
              child: _textureId != null
                  ? AspectRatio(
                      aspectRatio: _videoPlayer.aspectRatio,
                      child: Texture(textureId: _textureId),
                    )
                  : Container(
                      color: Colors.blue,
                    ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Icon(Icons.play_arrow),
                  onPressed: () {
                    _videoPlayer.play();
                  },
                ),
                RaisedButton(
                  child: Icon(Icons.pause),
                  onPressed: () {
                    _videoPlayer.pause();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
