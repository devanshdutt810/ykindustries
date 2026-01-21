import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui';

// Responsive size helper
double rs(BuildContext context, double mobile, double tablet, double desktop) {
  final w = MediaQuery.of(context).size.width;
  if (w < 600) return mobile;
  if (w < 1100) return tablet;
  return desktop;
}

class VideoBackground extends StatefulWidget {
  const VideoBackground({super.key});

  @override
  State<VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<VideoBackground> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/images/background.mp4')
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox();
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final double opacity;
  final EdgeInsets padding;
  final Color tintColor; // <-- NEW

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 12,
    this.opacity = 0.2,
    this.padding = const EdgeInsets.all(0),
    this.tintColor = Colors.white, // default glass
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(),
          ),
          Container(
            padding: padding == EdgeInsets.zero
                ? EdgeInsets.all(rs(context, 16, 22, 28))
                : padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tintColor.withOpacity(opacity + 0.08),
                  tintColor.withOpacity(opacity),
                  tintColor.withOpacity(opacity - 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: tintColor.withOpacity(0.45), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YK Industries',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: HomePage(),
    );
  }
}

class WaterBackground extends StatefulWidget {
  const WaterBackground({super.key});

  @override
  State<WaterBackground> createState() => _WaterBackgroundState();
}

class _WaterBackgroundState extends State<WaterBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // faster, more dynamic feel
    )..repeat(reverse: true);
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
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + (2 * t), -1),
              end: Alignment(1 - (2 * t), 1),
              colors: const [
                Color.fromARGB(255, 15, 116, 156),
                Color(0xFFEAF9FF), // very light aqua
                Color(0xFFCDEFFF), // soft water blue
                Color(0xFFB3E5F5),
                Color.fromARGB(255, 15, 116, 156),
                // Color(0xFFEAF9FF), // very light aqua
                // Color(0xFFCDEFFF), // soft water blue
                // Color(0xFFB3E5F5),
                // Color(0xFFEAF9FF), // very light aqua
                // Color(0xFFCDEFFF), Color(0xFFB3E5F5),
                // Color.fromARGB(255, 15, 116, 156), // deeper tone
              ],
            ),
          ),
        );
      },
    );
  }
}

class PumpProduct {
  final String name;
  final String description;
  final String image;
  final Map<String, String> specs;

  PumpProduct({
    required this.name,
    required this.description,
    required this.image,
    required this.specs,
  });

  factory PumpProduct.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawSpecs = json['specs'] ?? {};
    return PumpProduct(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      specs: rawSpecs.map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _registerMapView() {
    ui_web.platformViewRegistry.registerViewFactory('yk-map-view', (
      int viewId,
    ) {
      final iframe = html.IFrameElement()
        ..src =
            "https://www.google.com/maps?q=YK%20Industries%20Mayapuri%20Delhi&output=embed"
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    });
  }

  Future<void> _openGoogleMaps() async {
    final Uri url = Uri.parse("https://maps.app.goo.gl/t4kaya8tw8v6ft6i9");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open Google Maps';
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse(
      "https://wa.me/8070090061?text=Hello%20I%20would%20like%20to%20enquire%20about%20your%20water%20pumps.",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open WhatsApp';
    }
  }

  List<dynamic> categories = [];
  String selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _registerMapView();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final String jsonString = await rootBundle.loadString(
      'assets/products.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);

    setState(() {
      categories = data['categories'];
      selectedCategory = categories.first['id'];
    });
  }

  List<PumpProduct> get filteredProducts {
    if (categories.isEmpty) return [];

    final selected = categories.firstWhere(
      (c) => c['id'] == selectedCategory,
      orElse: () => categories.first,
    );

    final List products = selected['products'] ?? [];
    return products.map((e) => PumpProduct.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    return Scaffold(
      body: Stack(
        children: [
          const VideoBackground(),

          // Dark overlay for readability
          Container(color: Colors.black.withOpacity(0.35)),

          // Main scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),

                // Hero Section
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 24,
                      ),
                      child: GlassCard(
                        blur: 6,
                        opacity: 0.05,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "YK Industries",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: rs(context, 24, 32, 40),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Engineering Water Flow Solutions Since 2012",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: rs(context, 14, 16, 20),
                                fontWeight: FontWeight.w500,
                                //color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "We are a trusted manufacturer of high‑quality water pumps for coolers, fountains, circulation systems, and compact water handling applications. Designed for durability, efficiency, and long‑lasting performance.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: rs(context, 13, 15, 17),
                                color: Colors.white.withOpacity(0.6),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Product Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Our Product Range",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: rs(context, 22, 26, 28),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "High‑performance pumps engineered for durability and efficiency.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: rs(context, 14, 16, 20),
                            //color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Category filter buttons
                      SizedBox(
                        height: isMobile ? 42 : 50,
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(categories.length, (
                                index,
                              ) {
                                final cat = categories[index];
                                final bool isSelected =
                                    selectedCategory == cat['id'];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedCategory = cat['id'];
                                      });
                                    },
                                    child: GlassCard(
                                      blur: 3,
                                      opacity: isSelected ? 0.20 : 0.10,
                                      borderRadius: 24,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 12,
                                      ),
                                      tintColor: isSelected
                                          ? Colors.lightGreenAccent
                                          : Colors.white,
                                      child: Text(
                                        cat['name'],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.75),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProducts.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width < 600
                              ? 2
                              : MediaQuery.of(context).size.width < 1100
                              ? 3
                              : 4,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: rs(context, 0.85, 0.9, 1.0),
                        ),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    _ProductDetailDialog(product: product),
                              );
                            },
                            child: GlassCard(
                              blur: 4,
                              opacity: 0.08,
                              borderRadius: 18,
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex:
                                        MediaQuery.of(context).size.width < 600
                                        ? 3
                                        : 4,
                                    child: Center(
                                      child: Container(
                                        width: rs(context, 70, 90, 110),
                                        height: rs(context, 70, 90, 110),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(
                                            0.12,
                                          ), // frosted glass base
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.35,
                                            ),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.18,
                                              ),
                                              blurRadius: 18,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: ClipOval(
                                            child: Image.asset(
                                              product.image,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        // const SizedBox(height: 6),
                                        // const Text(
                                        //   "View Details",
                                        //   style: TextStyle(
                                        //     fontSize: 12,
                                        //     color: Colors.blueAccent,
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // About Section
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1300),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 24,
                      ),
                      child: Column(
                        children: [
                          // ───────────── About YK Industries Card ─────────────
                          GlassCard(
                            blur: 6,
                            opacity: 0.12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "About Us",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: rs(context, 22, 26, 28),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "YK Industries is a Delhi‑based manufacturer specializing in the production of high‑quality water pumps. Established in 2012, we have built a strong reputation for delivering reliable and durable pumping solutions for coolers, fountains, and compact water systems.",
                                  style: TextStyle(
                                    fontSize: rs(context, 14, 16, 20),
                                    color: Colors.white.withOpacity(0.6),
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Our manufacturing process emphasizes precision engineering, strict quality control, and long‑term performance. We serve both wholesale and bulk buyers across India.",
                                  style: TextStyle(
                                    fontSize: rs(context, 14, 16, 20),
                                    color: Colors.white.withOpacity(0.6),
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Location: Mayapuri, New Delhi, India",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Established: 2012",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Business Type: Manufacturer & Wholesale Supplier",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 50),

                          // ───────────── Map + Buttons Card ─────────────
                          GlassCard(
                            blur: 6,
                            opacity: 0.12,
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "Contact Us",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: rs(context, 22, 26, 28),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 12),

                                // Google Map
                                Container(
                                  height: rs(context, 160, 200, 260),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: const HtmlElementView(
                                      viewType: 'yk-map-view',
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Open in Google Maps Button
                                GestureDetector(
                                  onTap: _openGoogleMaps,
                                  child: GlassCard(
                                    blur: 4,
                                    opacity: 0.18,
                                    tintColor: Colors.lightBlueAccent,
                                    borderRadius: 14,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/maps.svg',
                                          height: 20,
                                          width: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Open in Google Maps",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: rs(context, 13, 14, 15),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // WhatsApp Button
                                GestureDetector(
                                  onTap: _openWhatsApp,
                                  child: GlassCard(
                                    blur: 4,
                                    opacity: 0.18,
                                    tintColor: const Color(0xFF25D366),
                                    borderRadius: 14,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/whatsapp.svg',
                                          height: 20,
                                          width: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Contact on WhatsApp",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: rs(context, 13, 14, 15),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
                  ),
                ),

                // const SizedBox(
                //   height: 250,
                // ), // Extra space so content goes behind wave
              ],
            ),
          ),

          // Water wave animation at the bottom
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 0,
          //   child: SizedBox(
          //     height: 280,
          //     child: WaterAnimation(
          //       waterColor: const Color.fromARGB(
          //         255,
          //         82,
          //         210,
          //         246,
          //       ).withOpacity(0.85),
          //       //backgroundColor: Colors.transparent,
          //       amplitude: 25,
          //       speed: 3,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _ProductDetailDialog extends StatelessWidget {
  final PumpProduct product;
  const _ProductDetailDialog({required this.product});

  Future<void> _enquireOnWhatsApp(BuildContext context) async {
    final String message = "I would like to buy ${product.name}";
    final Uri url = Uri.parse(
      "https://wa.me/8070090061?text=${Uri.encodeComponent(message)}",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not open WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        blur: 8,
        opacity: 0.14,
        borderRadius: 22,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          width: rs(
            context,
            MediaQuery.of(context).size.width * 0.95,
            600,
            720,
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: rs(context, 18, 19, 20),
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: rs(context, 13, 13.5, 14),
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.specs['Price'] ?? '',
                        style: TextStyle(
                          fontSize: rs(context, 14, 15, 16),
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.specs['Minimum Order Quantity'] ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.9)),
                      ),

                      const SizedBox(height: 16),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.white.withOpacity(0.15),
                          child: Image.asset(
                            product.image,
                            height: rs(context, 160, 180, 220),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "Specifications",
                        style: TextStyle(
                          fontSize: rs(context, 16, 17, 18),
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...product.specs.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () => _enquireOnWhatsApp(context),
                        child: GlassCard(
                          blur: 4,
                          opacity: 0.22,
                          tintColor: const Color(0xFF25D366),
                          borderRadius: 14,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/whatsapp.svg',
                                height: 18,
                                width: 18,
                                // colorFilter: const ColorFilter.mode(
                                //   Colors.white,
                                //   BlendMode.srcIn,
                                // ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Enquire on WhatsApp",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: rs(context, 13, 14, 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Close Button
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white.withOpacity(0.9)),
                  splashRadius: 20,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
