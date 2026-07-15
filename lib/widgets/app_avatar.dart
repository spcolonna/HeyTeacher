import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Cached, fallback-safe avatar. Replaces raw `Image.network` /
/// `CircleAvatar(backgroundImage: NetworkImage(...))` usages: images are
/// disk-cached and a missing/failed URL falls back to initials.
class AppAvatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;

  const AppAvatar({
    super.key,
    required this.url,
    required this.name,
    this.radius = 24,
  });

  String get _initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = radius * 2;

    final fallback = Container(
      width: size,
      height: size,
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.75,
        ),
      ),
    );

    return ClipOval(
      child: (url == null || url!.isEmpty)
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                width: size,
                height: size,
                color: scheme.surfaceContainerHigh,
              ),
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}
