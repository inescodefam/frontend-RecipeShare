import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

import 'api_config.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/push_notification_service.dart';

/// Entry point for the RecipeShare mob app
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final PushNotificationService? pushNotifications;
  final services = useMockServices
      ? RecipeShareServices.mock()
      : () {
          final session = createAuthSessionStorage();
          final dio = DioClient.createDio(
            baseUrl: resolveApiBaseUrl(),
            session: session,
          );
          return RecipeShareServices.api(dio, session);
        }();
  pushNotifications = useMockServices
      ? null
      : PushNotificationService(deviceTokenService: services.deviceTokens);
  final auth = AuthProvider(
    services.auth,
    onBeforeLogout: pushNotifications?.unregisterCurrentToken,
  );
  final GoRouter router = AppRouter.create(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<RecipeShareServices>.value(value: services),
        Provider<PushNotificationService?>.value(value: pushNotifications),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: NotificationBootstrap(
        child: RecipeShareMobileApp(router: router),
      ),
    ),
  );
}

class NotificationBootstrap extends StatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationBootstrap> createState() => _NotificationBootstrapState();
}

class _NotificationBootstrapState extends State<NotificationBootstrap> {
  bool _wasLoggedIn = false;
  AuthProvider? _authProvider;
  PushNotificationService? _pushService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextAuth = context.read<AuthProvider>();
    _pushService ??= context.read<PushNotificationService?>();
    if (!identical(_authProvider, nextAuth)) {
      _authProvider?.removeListener(_onAuthChanged);
      _authProvider = nextAuth;
      _wasLoggedIn = nextAuth.isLoggedIn;
      _authProvider?.addListener(_onAuthChanged);
      _initializeNotifications();
    }
  }

  Future<void> _initializeNotifications() async {
    final push = _pushService;
    if (push == null) return;
    await push.initialize();
    if (!mounted) return;
    if (context.read<AuthProvider>().isLoggedIn) {
      debugPrint('Push: user already logged in at bootstrap, registering token');
      await push.registerCurrentToken();
    }
  }

  Future<void> _onAuthChanged() async {
    final auth = _authProvider;
    if (auth == null) return;
    final push = _pushService;
    if (push == null) return;
    final isLoggedIn = auth.isLoggedIn;
    if (isLoggedIn && !_wasLoggedIn) {
      _wasLoggedIn = true;
      debugPrint('Push: auth changed to logged in, registering token');
      await push.registerCurrentToken();
      return;
    }
    if (!isLoggedIn && _wasLoggedIn) {
      _wasLoggedIn = false;
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    _pushService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class RecipeShareMobileApp extends StatelessWidget {
  const RecipeShareMobileApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RecipeShare',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
