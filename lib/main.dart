import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Set preferred orientations to portrait only
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set status bar color to white with dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pearloc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isConnected = true;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  int _selectedIndex = 0;
  final List<String> _urls = [
    'https://www.pearloc.com/',
    'https://www.pearloc.com/featured/',
    'https://www.pearloc.com/store/',
    'https://www.pearloc.com/my-account/',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isConnected) WebViewWidget(controller: _controller),
            if (_isLoading && _isConnected)
              const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            if (!_isConnected)
              Column(
                children: [
                  const SizedBox(height: 40),
                  // Logo at the top
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/logo/pearloc_logo.png',
                      width: 120,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Center the no internet UI
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.signal_wifi_off_rounded,
                            size: 80,
                            color: Colors.black54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Internet Connection',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your internet connection and try again',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              checkConnectivity();
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _loadUrl(_urls[index]);
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Featured'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Store',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  void checkConnectivity() {
    Connectivity().checkConnectivity().then((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
      if (_isConnected) {
        _loadUrl(_urls[_selectedIndex]);
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    // Check initial connectivity
    checkConnectivity();
    // Subscribe to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
      if (_isConnected) {
        _loadUrl(_urls[_selectedIndex]);
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            FlutterNativeSplash.remove();

            // Inject JavaScript to hide the black banner at the top
            _controller.runJavaScript('''
              (function() {
                // Target the black banner at the top
                var banners = document.querySelectorAll('div[style*="background-color: #000000"]');
                banners.forEach(function(banner) {
                  banner.style.display = 'none';
                });
                
                // Alternative approach targeting elements with the specific text
                var allElements = document.querySelectorAll('div');
                allElements.forEach(function(element) {
                  if (element.textContent && 
                      element.textContent.includes('Delivery') && 
                      element.textContent.includes('COD Available') &&
                      element.textContent.includes('10% off on Prepaid')) {
                    element.style.display = 'none';
                  }
                });
                
                // Hide the cart floating button
                var cartButtons = document.querySelectorAll('a[href*="cart"]');
                cartButtons.forEach(function(button) {
                  button.style.display = 'none';
                });
                
                // Hide elements containing the number 0 in top right (likely cart count)
                var zeroElements = document.querySelectorAll('div, span, a');
                zeroElements.forEach(function(element) {
                  if (element.textContent === '0' && 
                      element.getBoundingClientRect().right > window.innerWidth * 0.8 &&
                      element.getBoundingClientRect().top < window.innerHeight * 0.2) {
                    element.style.display = 'none';
                  }
                });
              })();
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = '${error.errorType}: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.pearloc.com/'));
  }

  void _loadUrl(String url) {
    _controller.loadRequest(Uri.parse(url));
  }
}
