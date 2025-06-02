import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:url_launcher/url_launcher.dart';
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

class VideoReelsScreen extends StatefulWidget {
  const VideoReelsScreen({super.key});

  @override
  State<VideoReelsScreen> createState() => _VideoReelsScreenState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  int _selectedIndex = 0;
  final List<String> _urls = [
    'https://www.pearloc.com/app/',
    'https://www.pearloc.com/featured/',
    '', // This will be handled specially for video reels
    'https://www.pearloc.com/my-account/',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_selectedIndex == 2) // Watch and Shop tab
              const VideoReelsScreen(),
            if (_selectedIndex != 2 && _isConnected)
              WebViewWidget(controller: _controller),
            if (_isLoading && _isConnected && _selectedIndex != 2)
              const Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            if (!_isConnected && _selectedIndex != 2)
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
            if (index != 2) {
              // Not Watch and Shop tab
              _loadUrl(_urls[index]);
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Featured'),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_filled),
            label: 'Watch & Shop',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }

  void checkConnectivity() {
    Connectivity().checkConnectivity().then((List<ConnectivityResult> results) {
      setState(() {
        _isConnected =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
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
      List<ConnectivityResult> results,
    ) {
      setState(() {
        _isConnected =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);
      });
      if (_isConnected) {
        _loadUrl(_urls[_selectedIndex]);
      }
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check if the URL should be opened externally
            if (_shouldOpenExternally(request.url)) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent; // Prevent loading in webview
            }
            return NavigationDecision.navigate; // Allow normal navigation
          },
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
                // var banners = document.querySelectorAll('div[style*="background-color: #000000"]');
                // banners.forEach(function(banner) {
                //   banner.style.display = 'none';
                // });
                
                // // Alternative approach targeting elements with the specific text
                // var allElements = document.querySelectorAll('div');
                // allElements.forEach(function(element) {
                //   if (element.textContent && 
                //       element.textContent.includes('Delivery') && 
                //       element.textContent.includes('COD Available') &&
                //       element.textContent.includes('10% off on Prepaid')) {
                //     element.style.display = 'none';
                //   }
                // });
                
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

  // Helper method to launch URL externally
  Future<void> _launchExternalUrl(String url) async {
    try {
      // Special handling for WhatsApp URLs - force browser opening
      if (url.contains('api.whatsapp.com/send') || url.contains('wa.me')) {
        final uri = Uri.parse(url);
        // Always open WhatsApp links in browser
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Handle Instagram URLs - force browser opening
      else if (url.contains('instagram.com') || url.contains('instagr.am')) {
        final uri = Uri.parse(url);
        // Always open Instagram links in browser
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Handle other URLs (tel, mailto, sms, etc.)
      else {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      // If all else fails, try to open in browser
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (e2) {
        // Last resort: open in browser
        final uri = Uri.parse(url);
        await launchUrl(uri);
      }
    }
  }

  void _loadUrl(String url) {
    _controller.loadRequest(Uri.parse(url));
  }

  // Helper method to check if URL should be opened externally
  bool _shouldOpenExternally(String url) {
    final uri = Uri.parse(url);

    // Check for WhatsApp links
    if (url.contains('wa.me') ||
        url.contains('whatsapp.com') ||
        url.contains('api.whatsapp.com') ||
        url.contains('web.whatsapp.com') ||
        uri.scheme == 'whatsapp') {
      return true;
    }

    // Check for Instagram links
    if (url.contains('instagram.com') ||
        url.contains('instagr.am') ||
        uri.scheme == 'instagram') {
      return true;
    }

    // Check for other social media or external app schemes
    if (uri.scheme == 'tel' || uri.scheme == 'mailto' || uri.scheme == 'sms') {
      return true;
    }

    return false;
  }
}

class _VideoReelsScreenState extends State<VideoReelsScreen> {
  late final WebViewController _videoController;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fullscreen WebView for video content
          WebViewWidget(controller: _videoController),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.black)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeVideoController();
  }

  void _initializeVideoController() {
    _videoController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Handle external links
            if (_shouldOpenExternally(request.url)) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });

            // Auto-click the first video after the page loads
            // Increased delay to allow external Whatmore script to load
            Future.delayed(const Duration(milliseconds: 300), () {
              _videoController.runJavaScript('''
                  (function() {
                    console.log('Attempting to auto-click first video...');
                    
                    // Function to check if Whatmore script has loaded
                    function isWhatmoreLoaded() {
                      // Check if the external script has created any content
                      var whatmoreContainer = document.querySelector('.whatmore-render-root');
                      if (whatmoreContainer && whatmoreContainer.children.length > 0) {
                        return true;
                      }
                      
                      // Check if Whatmore global object exists (if the script creates one)
                      if (typeof window.whatmore !== 'undefined' || typeof window.Whatmore !== 'undefined') {
                        return true;
                      }
                      
                      // Check for any dynamically created content
                      var hasContent = document.querySelectorAll('[class*="whatmore"]:not(.whatmore-base):not(.whatmore-render-root)').length > 0;
                      return hasContent;
                    }
                    
                    // Function to find and click video elements
                    function findAndClickFirstVideo() {
                      // Wait for Whatmore content to load
                      var attempts = 0;
                      var maxAttempts = 15; // Increased attempts
                    
                                          function tryClickVideo() {
                        attempts++;
                        console.log('Attempt ' + attempts + ' to find videos...');
                        
                        // First check if Whatmore has loaded
                        if (!isWhatmoreLoaded()) {
                          console.log('Whatmore script not loaded yet, waiting...');
                          if (attempts < maxAttempts) {
                            setTimeout(tryClickVideo, 1500); // Longer wait for external script
                          } else {
                            console.log('Whatmore script failed to load after max attempts');
                          }
                          return false;
                        }
                        
                        console.log('Whatmore script loaded, looking for videos...');
                        
                        // Look for various video selectors that Whatmore might use
                      var videoSelectors = [
                        '.whatmore-video-item',
                        '.whatmore-video',
                        '.video-item',
                        '.video-thumbnail',
                        '[class*="video"]',
                        '[class*="whatmore"] video',
                        '[class*="whatmore"] .item',
                        '.whatmore-render-root video',
                        '.whatmore-render-root [class*="video"]',
                        '.whatmore-render-root [class*="item"]',
                        '.whatmore-render-root img',
                        '.whatmore-render-root div[onclick]',
                        '.whatmore-render-root button',
                        '.whatmore-render-root a'
                      ];
                      
                      var foundVideo = null;
                      
                      // Try each selector
                      for (var i = 0; i < videoSelectors.length; i++) {
                        var elements = document.querySelectorAll(videoSelectors[i]);
                        if (elements.length > 0) {
                          console.log('Found ' + elements.length + ' elements with selector: ' + videoSelectors[i]);
                          foundVideo = elements[0];
                          break;
                        }
                      }
                      
                      // If no specific video selectors work, try finding clickable elements in whatmore container
                      if (!foundVideo) {
                        var whatmoreContainer = document.querySelector('.whatmore-render-root, .whatmore-base, [class*="whatmore"]');
                        if (whatmoreContainer) {
                          // Look for any clickable elements within the container
                          var clickableElements = whatmoreContainer.querySelectorAll(
                            'div[onclick], button, a, [role="button"], [class*="click"], [class*="play"], img, video'
                          );
                          if (clickableElements.length > 0) {
                            foundVideo = clickableElements[0];
                            console.log('Found clickable element in whatmore container');
                          }
                        }
                      }
                      
                      if (foundVideo) {
                        console.log('Found video element, attempting to click...');
                        
                        // Try multiple click methods
                        try {
                          // Method 1: Direct click
                          foundVideo.click();
                          console.log('Clicked using direct click');
                          
                          // Method 2: Dispatch click event
                          setTimeout(function() {
                            var clickEvent = new MouseEvent('click', {
                              view: window,
                              bubbles: true,
                              cancelable: true
                            });
                            foundVideo.dispatchEvent(clickEvent);
                            console.log('Dispatched click event');
                          }, 100);
                          
                          // Method 3: Touch events (for mobile)
                          setTimeout(function() {
                            var touchStartEvent = new TouchEvent('touchstart', {
                              bubbles: true,
                              cancelable: true
                            });
                            var touchEndEvent = new TouchEvent('touchend', {
                              bubbles: true,
                              cancelable: true
                            });
                            foundVideo.dispatchEvent(touchStartEvent);
                            foundVideo.dispatchEvent(touchEndEvent);
                            console.log('Dispatched touch events');
                          }, 200);
                          
                        } catch (error) {
                          console.log('Error clicking video:', error);
                        }
                        
                        return true; // Video found and clicked
                      } else {
                        console.log('No video elements found yet...');
                        
                        // If we haven't reached max attempts, try again
                        if (attempts < maxAttempts) {
                          setTimeout(tryClickVideo, 1500); // Longer intervals
                        } else {
                          console.log('Max attempts reached, giving up on auto-click');
                        }
                        return false;
                      }
                    }
                    
                    // Start trying to click
                    tryClickVideo();
                  }
                  
                  // Start the process
                  findAndClickFirstVideo();
                  
                })();
              ''');
            });
          },
        ),
      )
      ..loadFlutterAsset('assets/pearloc_whatmore.html');
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      if (url.contains('api.whatsapp.com/send') || url.contains('wa.me')) {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } else if (url.contains('instagram.com') || url.contains('instagr.am')) {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      } else {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }
    } catch (e) {
      try {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (e2) {
        final uri = Uri.parse(url);
        await launchUrl(uri);
      }
    }
  }

  bool _shouldOpenExternally(String url) {
    final uri = Uri.parse(url);

    if (url.contains('wa.me') ||
        url.contains('whatsapp.com') ||
        url.contains('api.whatsapp.com') ||
        url.contains('web.whatsapp.com') ||
        uri.scheme == 'whatsapp') {
      return true;
    }

    if (url.contains('instagram.com') ||
        url.contains('instagr.am') ||
        uri.scheme == 'instagram') {
      return true;
    }

    if (uri.scheme == 'tel' || uri.scheme == 'mailto' || uri.scheme == 'sms') {
      return true;
    }

    return false;
  }
}
