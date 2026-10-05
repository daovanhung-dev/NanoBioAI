import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/entities/fitness_training_catalog.dart';

class FitnessCatalogImage extends StatefulWidget {
  const FitnessCatalogImage({
    required this.catalog,
    required this.illustration,
    this.width = 112,
    this.height = 84,
    this.borderRadius = 14,
    super.key,
  });

  final FitnessTrainingCatalog catalog;
  final FitnessIllustration illustration;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<FitnessCatalogImage> createState() => _FitnessCatalogImageState();
}

class _FitnessCatalogImageState extends State<FitnessCatalogImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _imageInfo;
  FitnessAtlas? _atlas;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant FitnessCatalogImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.illustration.atlasId != widget.illustration.atlasId) {
      _resolveImage();
    }
  }

  void _resolveImage() {
    final atlas = widget.catalog.atlasFor(widget.illustration);
    _atlas = atlas;
    if (atlas == null) return;
    final nextStream = AssetImage(
      atlas.assetPath,
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == nextStream.key && _imageInfo != null) return;
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = nextStream;
    _listener = ImageStreamListener(
      (info, _) {
        if (!mounted) return;
        setState(() => _imageInfo = info);
      },
      onError: (_, __) {
        if (mounted) setState(() => _imageInfo = null);
      },
    );
    nextStream.addListener(_listener!);
  }

  @override
  void dispose() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.borderRadius),
    child: SizedBox(
      width: widget.width,
      height: widget.height,
      child: _imageInfo == null || _atlas == null
          ? ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.fitness_center_rounded),
            )
          : CustomPaint(
              painter: _FitnessAtlasCellPainter(
                image: _imageInfo!.image,
                columns: _atlas!.columns,
                rows: _atlas!.rows,
                cellIndex: widget.illustration.cellIndex,
              ),
            ),
    ),
  );
}

class _FitnessAtlasCellPainter extends CustomPainter {
  const _FitnessAtlasCellPainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.cellIndex,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final int cellIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (columns < 1 ||
        rows < 1 ||
        cellIndex < 1 ||
        cellIndex > columns * rows) {
      return;
    }
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final index = cellIndex - 1;
    final column = index % columns;
    final row = index ~/ columns;
    final insetX = cellWidth * .035;
    final insetY = cellHeight * .035;
    final source = Rect.fromLTWH(
      column * cellWidth + insetX,
      row * cellHeight + insetY,
      cellWidth - insetX * 2,
      cellHeight - insetY * 2,
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, source, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _FitnessAtlasCellPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.cellIndex != cellIndex ||
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows;
}
