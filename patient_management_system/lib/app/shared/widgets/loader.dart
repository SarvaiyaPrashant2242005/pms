import 'package:flutter/widgets.dart';

class AppLoader extends StatelessWidget {
  final double? size;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  const AppLoader({
    super.key,
    this.size,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/gifs/loader_stethoscope.gif',
      width: size,
      height: size,
      fit: fit,
      alignment: alignment,
      gaplessPlayback: true,
    );
    return Center(child: image);
  }
}
