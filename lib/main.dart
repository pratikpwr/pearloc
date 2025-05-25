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
    'https://www.pearloc.com/',
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
            label: 'Watch and Shop',
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen WebView for video content
          WebViewWidget(controller: _videoController),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
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

            // Wait a moment for the page to fully load, then scroll to videos and auto-play
            Future.delayed(const Duration(milliseconds: 1000), () {
              _videoController.runJavaScript('''
                (function() {
                  // Function to find and scroll to "Watch and more" section
                  function findAndScrollToVideoSection() {
                    // Look for "Watch and more" text or similar video section indicators
                    var watchSectionCandidates = [];
                    
                    // Search for text that might indicate the video section
                    var allElements = document.querySelectorAll('*');
                    allElements.forEach(function(element) {
                      var text = element.textContent || element.innerText || '';
                      if (text.toLowerCase().includes('watch and more') ||
                          text.toLowerCase().includes('watch & more') ||
                          text.toLowerCase().includes('videos') ||
                          text.toLowerCase().includes('video content') ||
                          text.toLowerCase().includes('watch now')) {
                        watchSectionCandidates.push(element);
                      }
                    });
                    
                    // Also look for sections that might contain video elements
                    var videoSections = document.querySelectorAll(
                      'section, .section, .video-section, .videos, ' +
                      '.content-section, .products-section, .featured-section'
                    );
                    
                    videoSections.forEach(function(section) {
                      var sectionText = section.textContent || section.innerText || '';
                      if (sectionText.toLowerCase().includes('watch') ||
                          section.querySelector('video') ||
                          section.querySelector('iframe') ||
                          section.querySelector('[class*="video"]') ||
                          section.querySelector('[class*="play"]')) {
                        watchSectionCandidates.push(section);
                      }
                    });
                    
                    // Find the best candidate (usually the one with most video content)
                    var bestSection = null;
                    var maxVideoElements = 0;
                    
                    watchSectionCandidates.forEach(function(candidate) {
                      var videoCount = candidate.querySelectorAll(
                        'video, iframe, [class*="video"], [class*="play"], img[src*="play"]'
                      ).length;
                      
                      if (videoCount > maxVideoElements) {
                        maxVideoElements = videoCount;
                        bestSection = candidate;
                      }
                    });
                    
                    return bestSection;
                  }
                  
                  // Function to find clickable video elements
                  function findVideoElements(section) {
                    if (!section) return [];
                    
                    var videoElements = [];
                    
                    // Look for various types of video triggers
                    var candidates = section.querySelectorAll(
                      'video, iframe, ' +
                      '[class*="video"], [id*="video"], ' +
                      '[class*="play"], [id*="play"], ' +
                      '[class*="thumbnail"], [class*="thumb"], ' +
                      'img[src*="play"], img[alt*="video"], img[alt*="play"], ' +
                      'a[href*="video"], button[class*="play"], ' +
                      '.product-item, .item, .card'
                    );
                    
                    candidates.forEach(function(element) {
                      // Check if this element looks like it should trigger a video
                      var hasVideoIndicator = (
                        element.querySelector('img[src*="play"]') ||
                        element.querySelector('[class*="play"]') ||
                        element.tagName.toLowerCase() === 'video' ||
                        element.tagName.toLowerCase() === 'iframe' ||
                        (element.textContent || '').toLowerCase().includes('play') ||
                        element.classList.toString().toLowerCase().includes('video') ||
                        element.classList.toString().toLowerCase().includes('play')
                      );
                      
                      if (hasVideoIndicator) {
                        videoElements.push(element);
                      }
                    });
                    
                    return videoElements;
                  }
                  
                  // Function to click on video elements
                  function clickVideoElements(videoElements) {
                    if (videoElements.length === 0) {
                      console.log('No video elements found to click');
                      return;
                    }
                    
                    // Click on the first video element to open it
                    var firstVideo = videoElements[0];
                    
                    // Try different ways to trigger the video
                    try {
                      // First try a direct click
                      firstVideo.click();
                      
                      // If that doesn't work, try clicking on child elements immediately
                      setTimeout(function() {
                        var playButton = firstVideo.querySelector('[class*="play"], button, a');
                        if (playButton) {
                          playButton.click();
                        }
                        
                        // Also try triggering events
                        var clickEvent = new MouseEvent('click', {
                          view: window,
                          bubbles: true,
                          cancelable: true
                        });
                        firstVideo.dispatchEvent(clickEvent);
                      }, 100);
                      
                    } catch (error) {
                      console.log('Error clicking video element:', error);
                    }
                  }
                  
                  // Main execution
                  console.log('Looking for Watch and more section...');
                  
                  var videoSection = findAndScrollToVideoSection();
                  
                  if (videoSection) {
                    console.log('Found video section, scrolling to it...');
                    
                    // Scroll to the video section
                    videoSection.scrollIntoView({ 
                      behavior: 'smooth', 
                      block: 'center' 
                    });
                    
                    // Quick wait for scroll to complete, then find and click videos
                    setTimeout(function() {
                      var videoElements = findVideoElements(videoSection);
                      
                      if (videoElements.length > 0) {
                        console.log('Found ' + videoElements.length + ' video elements, clicking first one...');
                        clickVideoElements(videoElements);
                      } else {
                        console.log('No clickable video elements found in section');
                        
                        // Try searching in a broader area around the section
                        var parentSection = videoSection.parentElement;
                        if (parentSection) {
                          var parentVideoElements = findVideoElements(parentSection);
                          if (parentVideoElements.length > 0) {
                            console.log('Found videos in parent section, clicking...');
                            clickVideoElements(parentVideoElements);
                          }
                        }
                      }
                    }, 500);
                    
                  } else {
                    console.log('Video section not found, trying to find videos on entire page...');
                    
                    // Fallback: look for videos anywhere on the page
                    var allVideoElements = findVideoElements(document.body);
                    
                    if (allVideoElements.length > 0) {
                      console.log('Found videos on page, scrolling to first one...');
                      
                      allVideoElements[0].scrollIntoView({ 
                        behavior: 'smooth', 
                        block: 'center' 
                      });
                      
                      setTimeout(function() {
                        clickVideoElements(allVideoElements);
                      }, 300);
                    } else {
                      console.log('No videos found on page');
                    }
                  }
                  
                })();
              ''');
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.pearloc.com/'));
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
