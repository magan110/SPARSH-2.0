import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:learning2/core/theme/app_theme.dart';
import 'package:learning2/features/authentication/presentation/pages/login_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showLogin = false;
  late AnimationController _animationController;
  late AnimationController _particleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _shimmerAnimation;

  // Particle system variables
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Initialize particles
    _initializeParticles();

    // Slide animation with elastic curve
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Enhanced fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Enhanced scale animation with spring effect
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    // Enhanced rotate animation
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOutBack),
      ),
    );

    // Shimmer animation for text
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
    _checkLoginStatus();
  }

  void _initializeParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * 400,
          y: _random.nextDouble() * 800,
          size: _random.nextDouble() * 4 + 1,
          speed: _random.nextDouble() * 2 + 1,
          opacity: _random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    const splashDuration = Duration(seconds: 3);

    print('SplashScreen: isLoggedIn = $isLoggedIn');

    if (isLoggedIn) {
      Future.delayed(splashDuration, () {
        if (mounted) {
          print('SplashScreen: Navigating to HomeScreen');
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const HomeScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 1000),
            ),
          );
        }
      });
    } else {
      Future.delayed(splashDuration, () {
        if (mounted) {
          setState(() {
            _showLogin = true;
          });
          _animationController.forward(from: 0.6);
        }
      });
    }
  }

  void _handleSwipeUp() {
    print('SplashScreen: _handleSwipeUp called');
    setState(() {
      _showLogin = true;
    });
    _animationController.forward(from: 0.6);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Widget _buildParticleEffect() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _particleController.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget buildImageContainer(
    double width,
    double height,
    Image image, {
    int delay = 0,
  }) {
    return Container(
          width: width,
          height: height,
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image,
          ),
        )
        .animate()
        .fadeIn(delay: delay.milliseconds, duration: 800.milliseconds)
        .slideY(
          begin: 0.3,
          end: 0,
          delay: delay.milliseconds,
          duration: 600.milliseconds,
          curve: Curves.easeOutQuad,
        )
        .scaleXY(
          begin: 0.8,
          end: 1.0,
          delay: delay.milliseconds,
          duration: 600.milliseconds,
        );
  }

  Widget _buildShimmerText(String text, TextStyle style) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white,
                Colors.white.withOpacity(0.3),
              ],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment(_shimmerAnimation.value - 1, 0),
              end: Alignment(_shimmerAnimation.value + 1, 0),
            ).createShader(bounds);
          },
          child: Text(text, style: style),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Stack(
        children: [
          // Background Images with staggered animations
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildImageContainer(
                    width,
                    height * 0.2,
                    Image.asset('assets/image11.png', fit: BoxFit.cover),
                    delay: 0,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildImageContainer(
                        width * 0.4,
                        height * 0.2,
                        Image.asset('assets/image12.png', fit: BoxFit.cover),
                        delay: 100,
                      ),
                      buildImageContainer(
                        width * 0.5,
                        height * 0.2,
                        Image.asset('assets/image13.png', fit: BoxFit.cover),
                        delay: 200,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildImageContainer(
                        width * 0.5,
                        height * 0.2,
                        Image.asset('assets/image14.png', fit: BoxFit.contain),
                        delay: 300,
                      ),
                      buildImageContainer(
                        width * 0.5,
                        height * 0.2,
                        Image.asset('assets/image15.png', fit: BoxFit.contain),
                        delay: 400,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      buildImageContainer(
                        width * 0.4,
                        height * 0.2,
                        Image.asset('assets/image16.png', fit: BoxFit.contain),
                        delay: 500,
                      ),
                      buildImageContainer(
                        width * 0.5,
                        height * 0.2,
                        Image.asset('assets/image17.png', fit: BoxFit.contain),
                        delay: 600,
                      ),
                    ],
                  ),
                  buildImageContainer(
                    width * 0.9,
                    height * 0.2,
                    Image.asset('assets/image18.png', fit: BoxFit.contain),
                    delay: 700,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Particle Effect Overlay
          _buildParticleEffect(),

          // Enhanced Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SparshTheme.primaryBlue.withOpacity(0.85),
                    SparshTheme.primaryBlueLight.withOpacity(0.85),
                    Colors.cyan.shade400.withOpacity(0.85),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: 1000.milliseconds,
              delay: 500.milliseconds,
            ),
          ),

          // Main content with enhanced animations
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced Title animations with shimmer
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          _buildShimmerText(
                            'Welcome to',
                            const TextStyle(
                              fontSize: 28,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                            ),
                          ).animate().slideY(
                            begin: 0.5,
                            end: 0,
                            duration: 800.milliseconds,
                            curve: Curves.easeOutQuad,
                          ),

                          const SizedBox(height: 10),

                          ShaderMask(
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                child: Text(
                                  'SPARSH',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                              )
                              .animate()
                              .scaleXY(
                                begin: 0.5,
                                end: 1.0,
                                duration: 600.milliseconds,
                                curve: Curves.elasticOut,
                              )
                              .then()
                              .shimmer(
                                delay: 1000.milliseconds,
                                duration: 1500.milliseconds,
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Enhanced Footer with animations
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      Text(
                            'Developed By',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          )
                          .animate()
                          .fadeIn(
                            delay: 1200.milliseconds,
                            duration: 600.milliseconds,
                          )
                          .slideY(
                            begin: 0.3,
                            end: 0,
                            duration: 600.milliseconds,
                          ),

                      const SizedBox(height: 5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Birla White IT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(
                            delay: 1400.milliseconds,
                            duration: 600.milliseconds,
                          ),

                          const SizedBox(width: 8),

                          Icon(
                                Icons.favorite,
                                color: Colors.red.shade400,
                                size: 20,
                              )
                              .animate()
                              .fadeIn(
                                delay: 1600.milliseconds,
                                duration: 400.milliseconds,
                              )
                              .scaleXY(end: 1.2, duration: 400.milliseconds)
                              .then()
                              .scaleXY(end: 1.0, duration: 400.milliseconds),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Enhanced Login screen slide up animation
          if (_showLogin)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.9,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: LoginScreen(),
                      ),
                    )
                    .animate()
                    .shimmer(duration: 1000.milliseconds)
                    .then()
                    .scaleXY(end: 1.02, duration: 200.milliseconds)
                    .then()
                    .scaleXY(end: 1.0, duration: 200.milliseconds),
              ),
            ),

          // Enhanced Swipe up indicator
          if (!_showLogin)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! < 0) {
                    _handleSwipeUp();
                  }
                },
                child: Column(
                  children: [
                    Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 36)
                        .animate(
                          onPlay:
                              (controller) => controller.repeat(reverse: true),
                        )
                        .moveY(begin: 0, end: -10, duration: 1000.milliseconds),

                    const SizedBox(height: 8),

                    Text(
                          'Swipe up to login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        .animate()
                        .fadeIn(
                          duration: 1000.milliseconds,
                          delay: 2000.milliseconds,
                        )
                        .then()
                        .shimmer(duration: 2000.milliseconds),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Particle system classes
class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];
      final animatedY = particle.y - (animationValue * particle.speed * 100);

      // Reset particle position when it goes off screen
      if (animatedY < -10) {
        particles[i] = Particle(
          x: particle.x,
          y: size.height + 10,
          size: particle.size,
          speed: particle.speed,
          opacity: particle.opacity,
        );
        continue;
      }

      paint.color = Colors.white.withOpacity(
        particle.opacity * (1 - animationValue * 0.5),
      );
      canvas.drawCircle(Offset(particle.x, animatedY), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
