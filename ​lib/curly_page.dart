import 'dart:math' as math;
import 'package:flutter/material.dart';

class CurlyPage extends StatefulWidget {
  final Widget currentPage;
  final Widget nextPage;
  final double progress; // 0.0 (めくる前) 〜 1.0 (めくり完了)

  const CurlyPage({
    super.key,
    required this.currentPage,
    required this.nextPage,
    required this.progress,
  });

  @override
  State<CurlyPage> createState() => _CurlyPageState();
}

class _CurlyPageState extends State<CurlyPage> {
  @override
  Widget build(BuildContext context) {
    final progress = widget.progress.clamp(0.001, 0.999);
    
    return Stack(
      children: [
        // 下層：次に現れるページ
        Positioned.fill(child: widget.nextPage),

        // 上層：筒状に捲れ上がる現在のページ
        Positioned.fill(
          child: CustomPaint(
            painter: PageCurlPainter(
              progress: progress,
              childWidget: widget.currentPage,
            ),
            child: ClipPath(
              clipper: PageClipper(progress: progress),
              child: widget.currentPage,
            ),
          ),
        ),
      ],
    );
  }
}

class PageClipper extends CustomClipper<Path> {
  final double progress;
  PageClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final path = Path();
    final edgeX = size.width * (1.0 - progress);
    path.lineTo(edgeX, 0);
    path.lineTo(edgeX, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant PageClipper oldDelegate) => oldDelegate.progress != progress;
}

class PageCurlPainter extends CustomPainter {
  final double progress;
  final Widget childWidget;

  PageCurlPainter({required this.progress, required this.childWidget});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final width = size.width;
    final height = size.height;
    final foldX = width * (1.0 - progress);
    
    // シリンダー（円筒状のめくれ上がり）の幅
    final cylinderWidth = width * 0.15 * math.sin(progress * math.pi);

    // 1. 下層ページに落とす影（ドロップシャドウ）
    final shadowPath = Path()
      ..moveTo(foldX, 0)
      ..lineTo(foldX + cylinderWidth * 1.5, 0)
      ..lineTo(foldX + cylinderWidth * 1.5, height)
      ..lineTo(foldX, height)
      ..close();

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.black.withOpacity(0.5 * (1.0 - progress)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(foldX, 0, cylinderWidth * 1.5, height));

    canvas.drawPath(shadowPath, shadowPaint);

    // 2. めくれ上がった紙の裏面（透過＋反転グラデーション）
    final backFoldPath = Path();
    backFoldPath.moveTo(foldX, 0);
    
    // 立体的な弧を描く（ベジェ曲線）
    backFoldPath.cubicTo(
      foldX + cylinderWidth, height * 0.1,
      foldX + cylinderWidth, height * 0.9,
      foldX, height,
    );
    backFoldPath.lineTo(math.max(0.0, foldX - cylinderWidth * 0.8), height);
    backFoldPath.cubicTo(
      foldX, height * 0.9,
      foldX, height * 0.1,
      math.max(0.0, foldX - cylinderWidth * 0.8), 0,
    );
    backFoldPath.close();

    // 紙のシリンダー反射ハイライト＆影
    final backPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.grey.shade300.withOpacity(0.7),
          Colors.black.withOpacity(0.3),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(foldX - cylinderWidth, 0, cylinderWidth * 2, height));

    canvas.drawPath(backFoldPath, backPaint);
  }

  @override
  bool shouldRepaint(covariant PageCurlPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
