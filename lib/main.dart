import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

void main() => runApp(const QuranTracingApp());

class QuranTracingApp extends StatelessWidget {
  const QuranTracingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نسخ القرآن',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial',
      ),
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
  final List<Stroke> _strokes = [];
  Stroke? _current;
  double _score = 0;

  void _onPanStart(DragStartDetails d) {
    _current = Stroke([PointVector(d.localPosition.dx, d.localPosition.dy, 0.5)]);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    _current?.points.add(PointVector(d.localPosition.dx, d.localPosition.dy, 0.5));
    setState(() {});
  }

  void _onPanEnd(DragEndDetails _) {
    if (_current != null) _strokes.add(_current!);
    _current = null;
    setState(() {});
  }

  void _clear() => setState(() {
        _strokes.clear();
        _score = 0;
      });

  void _evaluate() {
    final total = _strokes.fold<int>(0, (s, st) => s + st.points.length);
    setState(() => _score = (total / 200).clamp(0, 1) * 100);
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 0.35,
                    child: SvgPicture.asset(
                      'assets/images/001.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(Colors.brown, BlendMode.srcIn),
                    ),
                  ),
                  CustomPaint(
                    painter: _PagePainter(strokes: _strokes, current: _current),
                    size: Size.infinite,
                  ),
                ],
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
  final List<Stroke> strokes;
  final Stroke? current;
  _PagePainter({required this.strokes, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade800
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      final outline = getStroke(s.points, options: const StrokeOptions(size: 6, thinning: 0.7, smoothing: 0.8, streamline: 0.7, easing: (t) => t, start: StrokeEndOptions(cap: true, taperEnabled: true), end: StrokeEndOptions(cap: true, taperEnabled: true)));
      final path = Path()..moveTo(outline.first.dx, outline.first.dy);
      for (final p in outline.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    if (current != null && current!.points.isNotEmpty) {
      final outline = getStroke(current!.points, options: const StrokeOptions(size: 6, thinning: 0.7, smoothing: 0.8, streamline: 0.7, easing: (t) => t, start: StrokeEndOptions(cap: true, taperEnabled: true), end: StrokeEndOptions(cap: true, taperEnabled: true)));
      final path = Path()..moveTo(outline.first.dx, outline.first.dy);
      for (final p in outline.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PagePainter old) => true;
}
