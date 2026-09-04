import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

void main() => runApp(const QuranTracingApp());

class QuranTracingApp extends StatelessWidget {
  const QuranTracingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نسخ القرآن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Arial'),
      home: const TracingPage(),
    );
  }
}

class TracingPage extends StatefulWidget {
  const TracingPage({super.key});

  @override
  State<TracingPage> createState() => _TracingPageState();
}

class _TracingPageState extends State<TracingPage> {
  final List<List<PointVector>> _strokes = [];
  List<PointVector>? _current;
  double _score = 0;

  void _onPanStart(DragStartDetails d) {
    _current = [PointVector(d.localPosition.dx, d.localPosition.dy, 0.5)];
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _current?.add(PointVector(d.localPosition.dx, d.localPosition.dy, 0.5));
    setState(() {});
  }

  void _onPanEnd(DragEndDetails _) {
    if (_current != null && _current!.length > 1) {
      _strokes.add(_current!);
    }
    _current = null;
    setState(() {});
  }

  void _clear() => setState(() {
        _strokes.clear();
        _score = 0;
      });

  void _evaluate() {
    final total = _strokes.fold<int>(0, (s, st) => s + st.length);
    setState(() => _score = (total / 200).clamp(0, 1) * 100);
  }

  Path _strokePath(List<PointVector> points) {
    final outline = getStroke(
      points,
      options: StrokeOptions(
        size: 14,
        thinning: 0.7,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: true,
        start: const StrokeEndOptions(cap: true, taperEnabled: true),
        end: const StrokeEndOptions(cap: true, taperEnabled: true),
      ),
    );
    final path = Path();
    if (outline.isEmpty) return path;
    path.moveTo(outline.first.dx, outline.first.dy);
    for (int i = 0; i < outline.length - 1; i++) {
      final p0 = outline[i];
      final p1 = outline[i + 1];
      path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سورة الفاتحة — نسخ بالقلم')),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: _PagePainter(strokes: _strokes, current: _current),
                size: Size.infinite,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _evaluate, child: const Text('قيّم')),
                ElevatedButton(onPressed: _clear, child: const Text('مسح')),
                Text('الدرجة: ${_score.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PagePainter extends CustomPainter {
  _PagePainter({required this.strokes, this.current});

  final List<List<PointVector>> strokes;
  final List<PointVector>? current;

  @override
  void paint(Canvas canvas, Size size) {
    // خلفية الصفحة
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFF8E7));

    // صورة صفحة الفاتحة من مصحف المدينة النبوية (مجمع الملك فهد)
    try {
      final img = const AssetImage('assets/images/fatiha_page.png');
      final provider = img.resolve(const ImageConfiguration());
      provider.addListener(ImageStreamListener((info, _) {
        final paint = Paint()
          ..colorFilter = const ColorFilter.mode(Color(0xFF8B7355), BlendMode.srcIn)
          ..color = const Color(0xFF8B7355).withOpacity(0.35);
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawImageRect(
          info.image,
          Rect.fromLTWH(0, 0, info.image.width.toDouble(), info.image.height.toDouble()),
          Offset.zero & size,
          paint,
        );
        canvas.restore();
      }));
    } catch (_) {
      // إذا ما لقيت الصورة بعد ما تحملت
    }

    // خطوط المستخدم
    final paint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..style = PaintingStyle.fill;
    for (final s in strokes) {
      canvas.drawPath(_strokePathOf(s), paint);
    }
    if (current != null && current!.length > 1) {
      canvas.drawPath(_strokePathOf(current!), paint);
    }
  }

  Path _strokePathOf(List<PointVector> points) {
    final outline = getStroke(
      points,
      options: StrokeOptions(
        size: 14,
        thinning: 0.7,
        smoothing: 0.5,
        streamline: 0.5,
        simulatePressure: true,
        start: const StrokeEndOptions(cap: true, taperEnabled: true),
        end: const StrokeEndOptions(cap: true, taperEnabled: true),
      ),
    );
    final path = Path();
    if (outline.isEmpty) return path;
    path.moveTo(outline.first.dx, outline.first.dy);
    for (int i = 0; i < outline.length - 1; i++) {
      final p0 = outline[i];
      final p1 = outline[i + 1];
      path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _PagePainter old) =>
      old.strokes != strokes || old.current != current;
}
