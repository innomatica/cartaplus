import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/audiohandler.dart';
import '../../model/cartabook.dart';
import '../../shared/constants.dart';
import '../../shared/settings.dart';

//
// Progress Bar
//
StreamBuilder<Duration> buildProgressBar(CartaAudioHandler handler) {
  return StreamBuilder<Duration>(
    stream: handler.positionStream.distinct(),
    builder: (context, snapshot) {
      final total = handler.duration;
      final progress = snapshot.data ?? Duration.zero;
      return ProgressBar(
        progress: progress,
        total: total,
        onSeek: (duration) async => await handler.seek(duration),
      );
    },
  );
}

//
// Play Button
//
StreamBuilder<bool> buildPlayButton(CartaAudioHandler handler,
    {double? size, Color? color}) {
  return StreamBuilder<bool>(
    stream: handler.playbackState.map((s) => s.playing).distinct(),
    builder: (context, snapshot) => snapshot.hasData && snapshot.data == true
        ? IconButton(
            icon: Icon(Icons.pause_rounded, size: size, color: color),
            onPressed: () async => await handler.pause(),
          )
        : IconButton(
            icon: Icon(Icons.play_arrow_rounded, size: size, color: color),
            onPressed: () async => await handler.play(),
          ),
  );
}

//
// Fast Forward 30sec Button
//
IconButton buildForwardButton(CartaAudioHandler handler,
    {double? size, Color? color}) {
  return IconButton(
    icon: Icon(Icons.forward_30_rounded, size: size, color: color),
    onPressed: () async => await handler.fastForward(),
  );
}

//
// Rewind 30sec Button
//
IconButton buildRewindButton(CartaAudioHandler handler,
    {double? size, Color? color}) {
  return IconButton(
    icon: Icon(Icons.replay_30_rounded, size: size, color: color),
    onPressed: () async => await handler.rewind(),
  );
}

//
// Next Section Button
//
IconButton buildNextButton(CartaAudioHandler handler,
    {double? size, Color? color}) {
  return IconButton(
    icon: Icon(Icons.skip_next_rounded, size: size, color: color),
    onPressed: () async => await handler.skipToNext(),
  );
}

//
// Previous Section Button
//
IconButton buildPreviousButton(CartaAudioHandler handler,
    {double? size, Color? color}) {
  return IconButton(
    icon: Icon(Icons.skip_previous_rounded, size: size, color: color),
    onPressed: () async => await handler.skipToPrevious(),
  );
}

//
// Speed Selection Button
//
const speeds = [0.75, 0.85, 1.0, 1.25, 1.5, 2.0];

StreamBuilder<double> buildSpeedSelector(CartaAudioHandler handler,
    {double? size, Color? color}) {
  return StreamBuilder<double>(
    stream: handler.playbackState.map((e) => e.speed).distinct(),
    builder: (context, snapshot) {
      return DropdownButton<double>(
        value: snapshot.data ?? 1.0,
        iconSize: 0,
        isDense: true,
        onChanged: (double? value) {
          handler.setSpeed(value ?? 1.0);
        },
        items: speeds
            .map<DropdownMenuItem<double>>(
              (double value) => DropdownMenuItem<double>(
                value: value,
                child: Text('$value x'),
              ),
            )
            .toList(),
      );
    },
  );
}

//
// Book Title Widget
//
enum TitleLayout { horizontal, vertical }

class BookTitle extends StatelessWidget {
  final CartaAudioHandler handler;
  final TitleLayout? layout;
  const BookTitle(this.handler, {this.layout, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: handler.playbackState.map((e) => e.queueIndex).distinct(),
      builder: (context, snapshot) {
        final tag = handler.getCurrentTag();
        final bookTitle = tag?.album ?? 'Unknown Title';
        final sectionTitle = tag?.title ?? '';

        switch (layout) {
          case TitleLayout.horizontal:
            return Text(
              '$bookTitle $sectionTitle',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          default:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  bookTitle,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            );
        }
      },
    );
  }
}

//
// Book Cover Widget
//
class BookCover extends StatelessWidget {
  final CartaAudioHandler handler;
  final double? size;
  const BookCover(this.handler, {this.size, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: handler.playbackState.map((e) => e.queueIndex).distinct(),
      builder: (context, snapshot) {
        final tag = handler.getCurrentTag();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: tag != null && tag.artUri != null
              ? tag.artUri!.isScheme('file')
                  ? Image.file(File(tag.artUri!.toFilePath()),
                      height: size ?? 200, width: size ?? 200)
                  : Image.network(tag.artUri!.toString(),
                      height: size ?? 200, width: size ?? 200)
              : Container(),
        );
      },
    );
  }
}

class Instruction extends StatefulWidget {
  const Instruction({super.key});

  @override
  State<Instruction> createState() => _InstructionState();
}

class _InstructionState extends State<Instruction> {
  bool? _addingBooks;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary);
    const textStyle = TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400);
    return _addingBooks == true
        ? Center(
            child: Text(
              'Adding books to bookshelf ...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome to $appName', style: titleStyle),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Navigate to ', style: textStyle),
                  CartaBook.getIconBySource(
                    CartaSource.librivox,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Text(' LibriVox book pages', style: textStyle),
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('or ', style: textStyle),
                  CartaBook.getIconBySource(
                    CartaSource.archive,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const Text(' Internet Archive book pages.', style: textStyle),
                ],
              ),
              const SizedBox(height: 8.0),
              const Text('And add books to your bookshelf', style: textStyle),
              const SizedBox(height: 24.0),
              const Text('Alternatively, you can', style: textStyle),
              const SizedBox(height: 12.0),
              ElevatedButton(
                child: const Text('Start with sample books'),
                onPressed: () async {
                  Navigator.of(context).pushNamed('/selected');
                },
              ),
              TextButton(
                child: const Text('Or read Instructions'),
                onPressed: () async {
                  launchUrl(Uri.parse(urlInstruction));
                },
              )
            ],
          );
  }
}

class FirstLogin extends StatelessWidget {
  const FirstLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 160,
            child: Image(image: AssetImage(defaultAlbumImage)),
          ),
          Text(
            'Add New Books and Start Listening',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
