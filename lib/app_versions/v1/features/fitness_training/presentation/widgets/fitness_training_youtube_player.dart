import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class FitnessTrainingYoutubePlayer extends StatefulWidget {
  const FitnessTrainingYoutubePlayer({required this.videoId, super.key});

  final String videoId;

  @override
  State<FitnessTrainingYoutubePlayer> createState() =>
      _FitnessTrainingYoutubePlayerState();
}

class _FitnessTrainingYoutubePlayerState
    extends State<FitnessTrainingYoutubePlayer> {
  late final YoutubePlayerController _controller =
      YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
  );
}
