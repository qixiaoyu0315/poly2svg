import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

void main() {
  runApp(PolylineToSVGApp());
}

class PolylineToSVGApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PolylineToSVGScreen(),
    );
  }
}

class PolylineToSVGScreen extends StatefulWidget {
  @override
  _PolylineToSVGScreenState createState() => _PolylineToSVGScreenState();
}

class _PolylineToSVGScreenState extends State<PolylineToSVGScreen> {
  final TextEditingController _controller = TextEditingController();
  String _svgData = "";

  /// 使用 `flutter_polyline_points` 解码 polyline
  List<List<double>> _decodePolyline(String polylineStr) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(polylineStr);

    return result
        .map((p) => wgs84ToWebMercator(p.longitude, p.latitude))
        .toList();
  }

  /// WGS84 转换为 Web Mercator
  List<double> wgs84ToWebMercator(double lon, double lat) {
    double x = lon * 20037508.34 / 180;
    double y = log(tan((90 + lat) * pi / 360)) / (pi / 180);
    y = y * 20037508.34 / 180;
    return [x, y];
  }

  void _generateSVG() {
    String polylineStr = _controller.text.trim();
    if (polylineStr.isEmpty) return;

    List<List<double>> points = _decodePolyline(polylineStr);

    if (points.isEmpty) return;

    double minX = points.map((p) => p[0]).reduce(min);
    double maxX = points.map((p) => p[0]).reduce(max);
    double minY = points.map((p) => p[1]).reduce(min);
    double maxY = points.map((p) => p[1]).reduce(max);

    double width = maxX - minX;
    double height = maxY - minY;
    double imageWidth = 800;
    double imageHeight = 600;
    double scale = min(imageWidth / width, imageHeight / height);

    List<String> pathData = points.map((p) {
      double x = (p[0] - minX) * scale;
      double y = (maxY - p[1]) * scale;
      return "${x.toStringAsFixed(2)},${y.toStringAsFixed(2)}";
    }).toList();

    String svgContent = '''
      <svg viewBox="0 0 $imageWidth $imageHeight" xmlns="http://www.w3.org/2000/svg">
        <polyline points="${pathData.join(' ')}" fill="none" stroke="green" stroke-width="15"/>
      </svg>
    ''';

    setState(() {
      _svgData = svgContent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Polyline to SVG")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter Polyline String",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _generateSVG,
              child: Text("Convert to SVG"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _svgData.isNotEmpty
                  ? Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: SvgPicture.string(_svgData, fit: BoxFit.contain),
                      ),
                    )
                  : Center(child: Text("SVG will be shown here")),
            ),
          ],
        ),
      ),
    );
  }
}
