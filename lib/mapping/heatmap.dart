/*import 'package:flutter/material.dart';



@override
  Widget build(BuildContext context) {
    final viewer = _buildViewer(context);

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: viewer);
    }
    return viewer;
  }

  void _fitToScreen() => _resetView();

  void _rotateQuarter() {
    setState(() {
      _rotationTurns = (_rotationTurns + 0.25) % 1.0;
    });
  }

  Widget _buildViewer(BuildContext context) {
    if (_selected == null) {
      if (_projects.isEmpty) {
        return const _EmptyPane(
          title: 'No site maps found',
          details: '',
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    final topBar = widget.showControls
        ? _TopControls(
            projects: _projects,
            selected: _selected!,
            onChanged: _onProjectChanged,
            onReset: _resetView,
            onFit: _fitToScreen,
            onRotate: _rotateQuarter,
          )
        : const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showControls) topBar,
        Expanded(
          child: FutureBuilder<_ResolvedImage>(
            future: _imageFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorPane(
                  title: 'Failed to load site map',
                  details: snap.error.toString(),
                );
              }
              final resolved = snap.data!;
              if (resolved.kind == _ImageKind.missing) {
                return _MissingPane(
                  project: _selected!,
                  triedFiles: resolved.triedFiles,
                  triedAssets: resolved.triedAssets,
                );
              }

              // Figure out base image provider
              final ImageProvider provider =
                  (resolved.kind == _ImageKind.file)
                      ? FileImage(resolved.file!)
                      : AssetImage(resolved.assetPath!) as ImageProvider;

              // We need actual pixel size to size our overlay correctly
              return FutureBuilder<Size>(
                future: _imageSizeFromProvider(provider),
                builder: (context, sizeSnap) {
                  if (sizeSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final imgSize = sizeSnap.data ?? const Size(0, 0);
                  if (imgSize.width == 0 || imgSize.height == 0) {
                    return const Center(
                      child: Text('Could not read image size.'),
                    );
                  }

                  // 1. Load sample points for this project
                  final samplePoints =
                      _loadSamplePointsForProject(_selected!);

                  // 2. Generate the heat grid from those points
                  final cfg = HeatmapConfig(
                    gridSize: 100,
                    maxValue: 100.0,
                    stampRadius: 3.5,
                    neighborFalloff: 0.8,
                    minPropagationCutoff: 0.10,
                    includeDiagonals: true,
                  );
                  final heatResult = generateHeatmap(
                    samples: samplePoints,
                    config: cfg,
                  );

                  // 3. Base image widget sized to its intrinsic dimensions
                  final imgWidget = (resolved.kind == _ImageKind.file)
                      ? Image.file(
                          resolved.file!,
                          filterQuality: FilterQuality.medium,
                          width: imgSize.width,
                          height: imgSize.height,
                          fit: BoxFit.fill,
                        )
                      : Image.asset(
                          resolved.assetPath!,
                          filterQuality: FilterQuality.medium,
                          width: imgSize.width,
                          height: imgSize.height,
                          fit: BoxFit.fill,
                        );

                  // 4. Heat overlay painted at same size
                  final heatOverlay = CustomPaint(
                    painter: HeatmapPainter(
                      heat: heatResult.heat,
                      maxVal: cfg.maxValue,
                      debugGridLines: false,
                    ),
                    size: imgSize,
                  );

                  // 5. Combine and allow zoom/rotate
                  final content = RotatedBox(
                    quarterTurns: (_rotationTurns * 4).round() % 4,
                    child: Center(
                      child: SizedBox(
                        width: imgSize.width,
                        height: imgSize.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            imgWidget,
                            IgnorePointer(child: heatOverlay),
                          ],
                        ),
                      ),
                    ),
                  );

                  return Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Stack(
                      children: [
                        const _GridBackground(),
                        InteractiveViewer(
                          minScale: 0.25,
                          maxScale: 8.0,
                          boundaryMargin: const EdgeInsets.all(256),
                          transformationController: _tc,
                          child: content,
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _ScaleChip(controller: _tc),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}*/