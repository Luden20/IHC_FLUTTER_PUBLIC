import 'dart:async';
import 'dart:io';

import 'package:appihv/components/general/toast.dart';
import 'package:appihv/screens/KeepAliveScreen.dart';
import 'package:appihv/screens/create_screen.dart';
import 'package:appihv/screens/event_detail_screen.dart';
import 'package:appihv/screens/home_screen.dart';
import 'package:appihv/screens/join_screen.dart';
import 'package:appihv/screens/login_screen.dart';
import 'package:appihv/screens/profile_screen.dart';
import 'package:appihv/screen_enums.dart';
import 'package:appihv/service/background.service.dart';
import 'package:appihv/service/data_provider.service.dart';
import 'package:appihv/service/pocketbase.service.dart';
import 'package:appihv/theme/app_theme.dart';
import 'package:appihv/components/general/app_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:app_links/app_links.dart';
import 'components/general/exit_confirmation_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


void main() async {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  WidgetsFlutterBinding.ensureInitialized();

  final themeController = AppThemeController();
  await themeController.loadSavedTheme();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  await PBService.init();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    firebaseFMCListener(
      message,
      messengerKey,
      navigatorKey,
      flutterLocalNotificationsPlugin,
    );
  });

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(
      MyApp(
        navigatorKey: navigatorKey,
        messengerKey: messengerKey,
        themeController: themeController,
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.navigatorKey,
    required this.messengerKey,
    required this.themeController,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final AppThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final themeData = AppTheme.resolve(themeController.mode);
        return MaterialApp(
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: messengerKey,
          title: 'Flutter Demo',
          theme: themeData,
          builder: (context, child) => AppGradientBackground(
            child: child ?? const SizedBox.shrink(),
          ),
          home: MyHomePage(
            title: 'Flutter Demo Home Page',
            themeController: themeController,
          ),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.title,
    required this.themeController,
  });
  final String title;
  final AppThemeController themeController;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  screens currentScreen = screens.home;
  late final PageController _pageController;
  late final List<Widget> _loggedInTabViews;
  late final Widget _loginNavigatorView;

  final GlobalKey<NavigatorState> _homeNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _joinNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _createNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _profileNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _loginNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey<HomeScreenState> homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<JoinScreenState> joinKey = GlobalKey<JoinScreenState>();

  late final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? subUri;

  late final StreamSubscription authSub;

  String? _pendingCode;
  String? _lastUserId;
  void _handleMove(screens screen) {
    _updateTab(screen, animate: true);
  }

  void _listenLinks() {
    subUri = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        final txt = uri.queryParameters['code'] ?? '';
        if (PBService.isLoggedIn) {
          _updateTab(screens.join, animate: true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            joinKey.currentState?.llenar(txt);
          });
        } else {
          _pendingCode = txt;
          _updateTab(screens.home, animate: false);
        }
      },
      onError: (err) {
        debugPrint('Error en uriLinkStream: $err');
      },
    );
  }

  Future<void> _handleInitialLink() async {
    try {
      final Uri? uri = await _appLinks.getInitialLink();
      if (uri != null) {
        final txt = uri.queryParameters['code'] ?? '';
        if (PBService.isLoggedIn) {
          _updateTab(screens.join, animate: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            joinKey.currentState?.llenar(txt);
          });
        } else {
          _pendingCode = txt;
          _updateTab(screens.home, animate: false);
        }
      }
    } catch (e) {
      debugPrint('Error al leer link inicial: $e');
    }
  }

  void _handleEventSelected(String eventId) {
    if (!PBService.isLoggedIn) return;
    unawaited(_showEventDetail(eventId));
  }

  void _handleEventCreated(String eventId) {
    if (!PBService.isLoggedIn) return;
    DataProvider.notifyEventoActualizado(eventId);
    unawaited(_showEventDetail(eventId, ensureHomeTab: true));
  }

  void _handleEventJoined(String eventId) {
    if (!PBService.isLoggedIn) return;
    DataProvider.notifyEventoActualizado(eventId);
    unawaited(_showEventDetail(eventId, ensureHomeTab: true));
  }

  Future<void> _showEventDetail(
    String eventId, {
    bool ensureHomeTab = false,
  }) async {
    if (!mounted) return;

    final bool shouldSwitchTab = ensureHomeTab || currentScreen != screens.home;
    if (shouldSwitchTab && currentScreen != screens.home) {
      setState(() {
        currentScreen = screens.home;
      });
      if (_pageController.hasClients) {
        await _pageController.animateToPage(
          screens.home.value,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
    }

    final navigator = _homeNavigatorKey.currentState;
    if (navigator == null) return;

    navigator.popUntil((route) => route.isFirst);
    await navigator.push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(id: eventId)),
    );
  }

  void _resetHomeStack() {
    final navigator = _homeNavigatorKey.currentState;
    navigator?.popUntil((route) => route.isFirst);
  }

  void _updateTab(screens targetScreen, {bool animate = false}) {
    if (currentScreen == targetScreen) return;
    setState(() {
      currentScreen = targetScreen;
    });

    if (!PBService.isLoggedIn || !_pageController.hasClients) {
      return;
    }

    if (animate) {
      _pageController.animateToPage(
        targetScreen.value,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(targetScreen.value);
    }
  }

  NavigatorState? _navigatorForCurrentTab() {
    if (!PBService.isLoggedIn) {
      return _loginNavigatorKey.currentState;
    }

    switch (currentScreen) {
      case screens.home:
        return _homeNavigatorKey.currentState;
      case screens.join:
        return _joinNavigatorKey.currentState;
      case screens.create:
        return _createNavigatorKey.currentState;
      case screens.profile:
        return _profileNavigatorKey.currentState;
    }
  }

  Future<bool> _handleRootWillPop() async {
    final navigator = _navigatorForCurrentTab();
    if (navigator != null && await navigator.maybePop()) {
      return false;
    }

    return ExitConfirmationDialog.show(
      context,
      title: 'Salir',
      message: '¿Deseas cerrar la aplicación?',
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentScreen.value);
    _loggedInTabViews = <Widget>[
      Navigator(
        key: _homeNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => HomeScreen(
            key: homeKey,
            onEventSelected: _handleEventSelected,
            onIndexChange: _handleMove,
          ),
        ),
      ),
      Navigator(
        key: _joinNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => JoinScreen(
            key: joinKey,
            onEventJoined: _handleEventJoined,
            onIndexChange: _handleMove,
          ),
        ),
      ),
      Navigator(
        key: _createNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              CreateScreen(onEventCreated: _handleEventCreated),
        ),
      ),
      Navigator(
        key: _profileNavigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) =>
              ProfileScreen(themeController: widget.themeController),
        ),
      ),
    ];
    _loginNavigatorView = Navigator(
      key: _loginNavigatorKey,
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    _lastUserId = PBService.actualUser?.id;
    _handleInitialLink();
    _listenLinks();
    authSub = PBService.client.authStore.onChange.listen((_) {
      if (PBService.isLoggedIn) {
        final String? newUserId = PBService.actualUser?.id;
        final String? previousUserId = _lastUserId;
        final bool isFirstLogin = previousUserId == null && newUserId != null;
        final bool userChanged =
            previousUserId != null &&
            newUserId != null &&
            previousUserId != newUserId;
        if (isFirstLogin || userChanged) {
          DataProvider.clearCache();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          homeKey.currentState?.handleAuthChanged();
          joinKey.currentState?.clearInput();
        });

        _lastUserId = newUserId;

        if (_pendingCode != null) {
          _updateTab(screens.join, animate: false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            joinKey.currentState?.llenar(_pendingCode!);
            _pendingCode = null;
          });
        } else if (isFirstLogin || userChanged) {
          _updateTab(screens.home, animate: false);
          // Forzar Home seleccionado tras login (solo en login real)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_pageController.hasClients) {
              _pageController.jumpToPage(screens.home.value);
            }
            if (currentScreen != screens.home) {
              setState(() {
                currentScreen = screens.home;
              });
            }
          });
        }

        // Asegura rebuild para reflejar cambio de login
        if (mounted) setState(() {});
      } else {
        DataProvider.clearCache();
        _pendingCode = null;
        _lastUserId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          joinKey.currentState?.clearInput();
        });
        // Limpia los stacks de navegadores antes de ocultarlos
        try {
          _homeNavigatorKey.currentState?.popUntil((r) => r.isFirst);
          _joinNavigatorKey.currentState?.popUntil((r) => r.isFirst);
          _createNavigatorKey.currentState?.popUntil((r) => r.isFirst);
          _profileNavigatorKey.currentState?.popUntil((r) => r.isFirst);
        } catch (_) {}
        _updateTab(screens.home, animate: false);

        // Asegura rebuild para reflejar logout inmediato
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    authSub.cancel();
    subUri?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = PBService.isLoggedIn;

    final int safeIndex = isLoggedIn ? currentScreen.value : 0;

    final Widget loggedInBody = PageView(
      key: const ValueKey('loggedInTabs'),
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (int index) {
        final screens nextScreen = screens.values[index];
        if (currentScreen != nextScreen) {
          setState(() {
            currentScreen = nextScreen;
          });
        }
      },
      children: _loggedInTabViews
          .map((page) => KeepAlivePage(child: page))
          .toList(growable: false),
    );

    final Widget loginBody = _loginNavigatorView;

    final Widget body = IndexedStack(
      index: isLoggedIn ? 0 : 1,
      children: <Widget>[
        loggedInBody,
        loginBody,
      ],
    );

    return WillPopScope(
      onWillPop: _handleRootWillPop,
      child: Scaffold(
        body: body,
        bottomNavigationBar: isLoggedIn
            ? NavigationBar(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: "Home"),
                  NavigationDestination(
                    icon: Icon(Icons.add_box),
                    label: "Unirme",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.add_box_outlined),
                    label: "Crear",
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person),
                    label: "Profile",
                  ),
                ],
                selectedIndex: safeIndex,
                onDestinationSelected: (int index) {
                  final screens destination = screens.values[index];
                  final bool isHomeTab = destination == screens.home;
                  final bool isSameTab = destination == currentScreen;

                  if (isHomeTab && isSameTab) {
                    _resetHomeStack();
                    return;
                  }

                  _updateTab(destination, animate: true);

                  if (isHomeTab) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _resetHomeStack();
                    });
                  }
                },
              )
            : null,
      ),
    );
  }
}
