import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeatherBackground extends StatefulWidget {
  final String weatherCondition;
  
  const WeatherBackground({super.key, required this.weatherCondition});
  
  @override
  State<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends State<WeatherBackground> with TickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final int particleCount = 40;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _initializeParticles();
  }
  
  void _initializeParticles() {
    particles.clear();
    
    for (int i = 0; i < particleCount; i++) {
      particles.add(Particle(
        position: Offset(
          math.Random().nextDouble() * 400,
          math.Random().nextDouble() * 800,
        ),
        size: math.Random().nextDouble() * 10 + 5,
        speed: math.Random().nextDouble() * 100 + 50,
        angle: math.Random().nextDouble() * 2 * math.pi,
      ));
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WeatherPainter(
            weatherCondition: widget.weatherCondition,
            animationValue: _controller.value,
            particles: particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  Offset position;
  double size;
  double speed;
  double angle;
  
  Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
  });
}

class WeatherPainter extends CustomPainter {
  final String weatherCondition;
  final double animationValue;
  final List<Particle> particles;
  
  WeatherPainter({
    required this.weatherCondition,
    required this.animationValue,
    required this.particles,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Different backgrounds based on weather condition
    switch (weatherCondition.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        _drawRain(canvas, size);
        break;
      case 'snow':
        _drawSnow(canvas, size);
        break;
      case 'clear':
        _drawClear(canvas, size);
        break;
      case 'clouds':
        _drawClouds(canvas, size);
        break;
      case 'thunderstorm':
        _drawThunderstorm(canvas, size);
        break;
      case 'mist':
      case 'fog':
        _drawMist(canvas, size);
        break;
      default:
        _drawDefault(canvas, size);
        break;
    }
  }
  
  void _drawRain(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF1A237E),
          Color(0xFF303F9F),
          Color(0xFF3949AB),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw rain drops
    final rainPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (var particle in particles) {
      final currentY = (particle.position.dy + particle.speed * animationValue) % size.height;
      
      canvas.drawLine(
        Offset(particle.position.dx, currentY),
        Offset(particle.position.dx, currentY + particle.size),
        rainPaint,
      );
    }
  }
  
  void _drawSnow(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF90CAF9),
          Color(0xFF64B5F6),
          Color(0xFF42A5F5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw snowflakes
    final snowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    for (var particle in particles) {
      final currentY = (particle.position.dy + particle.speed * 0.5 * animationValue) % size.height;
      final currentX = (particle.position.dx + math.sin(animationValue * 2 * math.pi + particle.angle) * 10) % size.width;
      
      canvas.drawCircle(
        Offset(currentX, currentY),
        particle.size / 2,
        snowPaint,
      );
    }
  }
  
  void _drawClear(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF1E88E5),
          Color(0xFF42A5F5),
          Color(0xFF64B5F6),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw sun
    final sunPaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    
    final sunCenter = Offset(size.width * 0.75, size.height * 0.2);
    canvas.drawCircle(sunCenter, 50, sunPaint);
    
    // Draw sun rays
    final rayPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < 12; i++) {
      final angle = i * 30 * math.pi / 180;
      final rayStart = Offset(
        sunCenter.dx + 60 * math.cos(angle),
        sunCenter.dy + 60 * math.sin(angle),
      );
      final rayEnd = Offset(
        sunCenter.dx + (70 + 10 * math.sin(animationValue * 2 * math.pi)) * math.cos(angle),
        sunCenter.dy + (70 + 10 * math.sin(animationValue * 2 * math.pi)) * math.sin(angle),
      );
      
      canvas.drawLine(rayStart, rayEnd, rayPaint);
    }
  }
  
  void _drawClouds(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF78909C),
          Color(0xFF90A4AE),
          Color(0xFFB0BEC5),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw clouds
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 5; i++) {
      final xOffset = (i * size.width / 3 + animationValue * 50) % (size.width + 200) - 100;
      
      _drawCloud(canvas, Offset(xOffset, 100 + i * 70), 40 + i * 10, cloudPaint);
    }
  }
  
  void _drawCloud(Canvas canvas, Offset center, double radius, Paint paint) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(Offset(center.dx + radius * 0.7, center.dy - radius * 0.3), radius * 0.8, paint);
    canvas.drawCircle(Offset(center.dx - radius * 0.7, center.dy - radius * 0.3), radius * 0.8, paint);
    canvas.drawCircle(Offset(center.dx + radius * 1.2, center.dy), radius * 0.7, paint);
    canvas.drawCircle(Offset(center.dx - radius * 1.2, center.dy), radius * 0.7, paint);
  }
  
  void _drawThunderstorm(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF303F9F),
          Color(0xFF3949AB),
          Color(0xFF5C6BC0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw clouds
    final cloudPaint = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.fill;
    
    _drawCloud(canvas, Offset(size.width * 0.3, 100), 60, cloudPaint);
    _drawCloud(canvas, Offset(size.width * 0.7, 150), 70, cloudPaint);
    
    // Draw lightning
    if (animationValue > 0.7 || (animationValue > 0.3 && animationValue < 0.35)) {
      final lightningPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      
      final path = Path();
      path.moveTo(size.width * 0.5, 150);
      path.lineTo(size.width * 0.53, 200);
      path.lineTo(size.width * 0.47, 220);
      path.lineTo(size.width * 0.5, 280);
      path.lineTo(size.width * 0.44, 320);
      path.lineTo(size.width * 0.52, 250);
      path.lineTo(size.width * 0.48, 230);
      path.lineTo(size.width * 0.53, 150);
      path.close();
      
      canvas.drawPath(path, lightningPaint);
    }
    
    // Draw rain drops
    final rainPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (var particle in particles) {
      final currentY = (particle.position.dy + particle.speed * animationValue) % size.height;
      
      canvas.drawLine(
        Offset(particle.position.dx, currentY),
        Offset(particle.position.dx, currentY + particle.size),
        rainPaint,
      );
    }
  }
  
  void _drawMist(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFFE0E0E0),
          Color(0xFFBDBDBD),
          Color(0xFF9E9E9E),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw mist layers
    final mistPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final yOffset = 100 + i * 100;
      final xOffset = math.sin(animationValue * 2 * math.pi + i) * 20;
      
      path.moveTo(0, yOffset + xOffset);
      
      for (double x = 0; x <= size.width; x += size.width / 8) {
        final y = yOffset + 
          math.sin((x / size.width + animationValue) * 2 * math.pi + i) * 20 +
          xOffset;
        
        path.lineTo(x, y);
      }
      
      path.lineTo(size.width, yOffset + 200);
      path.lineTo(0, yOffset + 200);
      path.close();
      
      canvas.drawPath(path, mistPaint);
    }
  }
  
  void _drawDefault(Canvas canvas, Size size) {
    // Linear gradient background
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF42A5F5),
          Color(0xFF64B5F6),
          Color(0xFF90CAF9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}