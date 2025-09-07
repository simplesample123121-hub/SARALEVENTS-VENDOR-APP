import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppImages {
	// Standard asset image with calculated cacheWidth and stable playback
	static Widget asset(
		String assetPath, {
		required double targetLogicalWidth,
		double? aspectRatio,
		BoxFit fit = BoxFit.cover,
		FilterQuality filterQuality = FilterQuality.medium,
	}) {
		return LayoutBuilder(
			builder: (context, constraints) {
				final dpr = MediaQuery.of(context).devicePixelRatio;
				final cacheWidth = (targetLogicalWidth * dpr).round();
				Widget img = Image.asset(
					assetPath,
					fit: fit,
					gaplessPlayback: true,
					filterQuality: filterQuality,
					cacheWidth: cacheWidth > 0 ? cacheWidth : null,
				);
				if (aspectRatio != null) {
					img = AspectRatio(aspectRatio: aspectRatio, child: img);
				}
				return img;
			},
		);
	}

	// Standard network image with caching, placeholder and error handling
	static Widget network(
		String url, {
		BoxFit fit = BoxFit.cover,
		Widget? placeholder,
		Widget? error,
		BorderRadius? borderRadius,
	}) {
		Widget image = CachedNetworkImage(
			imageUrl: url,
			fit: fit,
			placeholder: (context, _) => placeholder ?? Container(color: Colors.black12.withOpacity(0.06)),
			errorWidget: (context, _, __) => error ?? Container(color: Colors.black12.withOpacity(0.06)),
		);
		if (borderRadius != null) {
			image = ClipRRect(borderRadius: borderRadius, child: image);
		}
		return image;
	}

	// Precache a list of asset images (call after first frame)
	static Future<void> precacheAssets(BuildContext context, List<String> assetPaths) async {
		for (final path in assetPaths) {
			try {
				await precacheImage(AssetImage(path), context);
			} catch (_) {}
		}
	}
}
