import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _setTheme(bool isDark) => setState(() => _isDarkMode = isDark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter + Image Toggle',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(onThemeChanged: _setTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final void Function(bool) onThemeChanged;

  const MyHomePage({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  static const String _kCounterKey = 'counter';
  static const String _kIsImageOneKey = 'isImageOne';
  static const String _kIsDarkModeKey = 'isDarkMode';

  int _counter = 0;
  bool _isImageOne = true;
  bool _isDarkMode = false;

  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    _curvedAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() => _isImageOne = !_isImageOne);
        _saveImageState();
        _controller.forward();
      }
    });

    _loadState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _currentImageAsset => _isImageOne ? 'assets/image1.png' : 'assets/image2.png';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _counter = prefs.getInt(_kCounterKey) ?? 0;
      _isImageOne = prefs.getBool(_kIsImageOneKey) ?? true;
      _isDarkMode = prefs.getBool(_kIsDarkModeKey) ?? false;
    });

    widget.onThemeChanged(_isDarkMode);
    _controller.value = 1.0;
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCounterKey, _counter);
    await prefs.setBool(_kIsImageOneKey, _isImageOne);
    await prefs.setBool(_kIsDarkModeKey, _isDarkMode);
  }

  Future<void> _saveImageState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsImageOneKey, _isImageOne);
  }

  Future<void> _saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCounterKey, _counter);
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsDarkModeKey, _isDarkMode);
  }

  void _incrementCounter() {
    setState(() => _counter++);
    _saveCounter();
  }

  void _toggleImage() {
    if (!_controller.isAnimating) {
      _controller.reverse();
    }
  }

  void _toggleTheme() {
    setState(() => _isDarkMode = !_isDarkMode);
    widget.onThemeChanged(_isDarkMode);
    _saveTheme();
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset application?'),
        content: const Text(
            'This will reset the counter to 0, revert the image to the initial image, '
            'and clear stored data. This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); 

      setState(() {
        _counter = 0;
        _isImageOne = true;
        _isDarkMode = false;
      });

      widget.onThemeChanged(false);
      _controller.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter + Image Toggle'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Counter',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _incrementCounter,
                child: const Text('Increment'),
              ),

              const SizedBox(height: 28),

              Text(
                'Image',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: 240,
                height: 240,
                child: FadeTransition(
                  opacity: _curvedAnimation,
                  child: Image.asset(
                    _currentImageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _toggleImage,
                    child: const Text('Toggle Image'),
                  ),
                  ElevatedButton(
                    onPressed: _toggleTheme,
                    child: Text(_isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                  ),
                  ElevatedButton(
                    onPressed: _resetAll,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
