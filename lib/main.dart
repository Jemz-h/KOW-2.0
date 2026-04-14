import 'package:flutter/material.dart';

import 'api_service.dart';
import 'local_sync_store.dart';
import 'screens/menu.dart';
import 'screens/start.dart';
import 'widgets/mock_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await LocalSyncStore.instance.getSelectedTheme();
  if (savedTheme != null && themeBackgrounds.containsKey(savedTheme)) {
    selectedThemeNotifier.value = savedTheme;
  }
  ApiService.syncPending();
  runApp(const MyApp());
}

/// App root widget that wires theme and landing screen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(useMaterial3: true);
    return MaterialApp(
      // Uncomment the comment below to remove the debug ribbon on the upper right
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SuperCartoon',
        useMaterial3: true,
        textTheme: baseTheme.textTheme.apply(fontFamily: 'SuperCartoon'),
        primaryTextTheme: baseTheme.textTheme.apply(fontFamily: 'SuperCartoon'),
      ),
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Future<bool> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = ApiService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasSession = snapshot.data == true;
        if (hasSession) {
          return const MenuScreen();
        }

        return const StartScreen();
      },
    );
  }
}
