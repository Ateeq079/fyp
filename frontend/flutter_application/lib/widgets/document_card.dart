import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/pdf_cache_service.dart';
import 'shared_ui.dart';

class DocumentCard extends StatefulWidget {
  final int index;
  final String? title;
  final String? subtitle;
  final String? downloadUrl;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DocumentCard({
    super.key,
    required this.index,
    this.title,
    this.subtitle,
    this.downloadUrl,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  /// null  = still loading, '' = failed, non-empty = local path ready
  String? _localPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchThumbnail();
  }

  @override
  void didUpdateWidget(DocumentCard old) {
    super.didUpdateWidget(old);
    if (old.downloadUrl != widget.downloadUrl) {
      setState(() {
        _localPath = null;
        _loading = true;
      });
      _fetchThumbnail();
    }
  }

  Future<void> _fetchThumbnail() async {
    if (widget.downloadUrl == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final path = await PdfCacheService().getLocalPath(widget.downloadUrl!);
    if (mounted) {
      setState(() {
        _localPath = path ?? '';
        _loading = false;
      });
    }
  }

  // ──────────────────────────────────────────────
  //  Thumbnail area
  // ──────────────────────────────────────────────

  Widget _buildThumbnail(ColorScheme colorScheme) {
    // Still downloading
    if (_loading) {
      return _ShimmerBox();
    }

    // Download succeeded — render first page from local file
    if (_localPath != null && _localPath!.isNotEmpty) {
      return AbsorbPointer(
        child: SfPdfViewer.file(
          File(_localPath!),
          canShowScrollHead: false,
          canShowScrollStatus: false,
          enableDoubleTapZooming: false,
          enableTextSelection: false,
          pageLayoutMode: PdfPageLayoutMode.single,
        ),
      );
    }

    // Failed to download — show fallback icon
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 42,
        color: colorScheme.primary.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayTitle = widget.title ?? 'Document ${widget.index + 1}';
    final displaySubtitle = widget.subtitle ?? '';

    return SoftCard(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Thumbnail ──────────────────────────────
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceTint.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: _buildThumbnail(colorScheme),
              ),
            ),
          ),
          // ── Text info ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (displaySubtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    displaySubtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
//  Animated shimmer placeholder shown while downloading
// ──────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        color: Color.lerp(base, base.withValues(alpha: 0.4), _anim.value),
        child: Center(
          child: Icon(
            Icons.picture_as_pdf_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
