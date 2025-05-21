import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pearloc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
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
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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

  @override
  void initState() {
    super.initState();
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
            FlutterNativeSplash.remove();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.pearloc.com/'));
  }

  void _loadUrl(String url) {
    _controller.loadRequest(Uri.parse(url));
  }
}
