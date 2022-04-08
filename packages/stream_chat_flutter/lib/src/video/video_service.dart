import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:stream_chat_flutter/src/utils/device_segmentation.dart';
import 'package:synchronized/synchronized.dart';
import 'package:thumblr/thumblr.dart' as thumblr;
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

///
// ignore: prefer-match-file-name
class _IVideoService {
  _IVideoService._();

  /// Singleton instance of [_IVideoService]
  static final _IVideoService instance = _IVideoService._();
  final _lock = Lock();

  /// compress video from [path]
  /// compress video from [path] return [Future<MediaInfo>]
  ///
  /// you can choose its [quality] and [frameRate]
  ///
  /// ## example
  /// ```dart
  /// final info = await _flutterVideoCompress.compressVideo(
  ///   file.path,
  /// );
  /// debugPrint(info.toJson());
  /// ```
  Future<MediaInfo?> compressVideo(
    String path, {
    int frameRate = 30,
    VideoQuality quality = VideoQuality.DefaultQuality,
  }) async =>
      _lock.synchronized(
        () => VideoCompress.compressVideo(
          path,
          frameRate: frameRate,
          quality: quality,
        ),
      );

  /// Generates a thumbnail image data in memory as UInt8List,
  /// it can be easily used by Image.memory(...).
  /// The video can be a local video file, or an URL represents iOS or
  /// Android native supported video format.
  /// Specify the maximum height or width for the thumbnail or 0 for
  /// same resolution as the original video.
  /// The lower quality value creates lower quality of the thumbnail image,
  /// but it gets ignored for PNG format.
  Future<Uint8List?> generateVideoThumbnail({
    required String video,
    ImageFormat imageFormat = ImageFormat.PNG,
    int maxHeight = 0,
    int maxWidth = 0,
    int timeMs = 0,
    int quality = 10,
  }) async {
    if (isDesktopDevice) {
      try {
        final image = await thumblr.generateThumbnail(filePath: video);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final bytesList = byteData?.buffer.asUint8List() ?? Uint8List(0);
        if (bytesList.isNotEmpty) {
          return bytesList;
        } else {
          return await generatePlaceholderThumbnail();
        }
      } catch (e) {
        print(e);
        // If the thumbnail generation fails, return a placeholder image.
        // As of thumblr 0.0.2+1, thumbnails can only be generated from local
        // video files; urls are not supported yet.
        final placeholder = await generatePlaceholderThumbnail();
        return placeholder;
      }
    } else if (isMobileDevice) {
      return VideoThumbnail.thumbnailData(
        video: video,
        imageFormat: imageFormat,
        maxHeight: maxHeight,
        maxWidth: maxWidth,
        timeMs: timeMs,
        quality: quality,
      );
    }
    throw Exception('Could not generate thumbnail');
  }

  /// Generates a placeholder thumbnail by loading placeholder.png from assets.
  Future<Uint8List> generatePlaceholderThumbnail() async {
    final placeholder = await rootBundle.load('images/placeholder.png');
    return placeholder.buffer.asUint8List();
  }
}

/// Get instance of [_IVideoService]
// ignore: non_constant_identifier_names
_IVideoService get VideoService => _IVideoService.instance;
