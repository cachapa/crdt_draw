import 'dart:async';
import 'dart:math';

import 'package:crdt/map_crdt.dart';
import 'package:crdt_sync/crdt_sync.dart';
import 'package:flutter/material.dart';

import 'canvas.dart';

late final MapCrdt crdt;
late final CrdtSyncClient client;

const colors = [
  Colors.white,
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  // Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.blueGrey,
  Colors.black,
];

Future<void> main() async {
  crdt = MapCrdt(['pixels', 'meta']);
  client = CrdtSyncClient(
    crdt,
    // Uri.parse('ws://localhost:8080'),
    Uri.parse('wss://draw-api.cachapa.net'),
    // onChangesetReceived: (recordCounts, nodeId) =>
    //     print('⇩ $nodeId $recordCounts'),
    // onChangesetSent: (recordCounts, nodeId) => print('⇧ $nodeId $recordCounts'),
  )..connect();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRDT Draw!',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  var _connectToggle = true;
  var _userCount = 0;
  var _state = SocketState.disconnected;
  final _points = List.generate(
      canvasSize, (_) => List<Color?>.generate(canvasSize, (_) => null));
  late Color _selectedColor;

  StreamSubscription? _stateSubscription;
  StreamSubscription? _metaSubscription;
  StreamSubscription? _pixelsSubscription;

  @override
  void initState() {
    super.initState();

    _selectedColor = colors[Random().nextInt(colors.length)];

    _stateSubscription =
        client.watchState.listen((state) => setState(() => _state = state));

    _metaSubscription = crdt
        .watch('meta')
        .where((e) => e.key == 'user_count')
        .listen((e) => setState(() => _userCount = e.value));

    _pixelsSubscription = crdt.watch('pixels').listen((e) {
      final i = e.key.indexOf(' ');
      final x = int.parse(e.key.substring(0, i));
      final y = int.parse(e.key.substring(i + 1));
      final color = e.isDeleted ? null : (e.value as String).toColor();
      setState(() => _points[x][y] = color);
    });

    // Wait for first frame to show info dialog
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInfo());
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _metaSubscription?.cancel();
    _pixelsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: Tooltip(
          message: 'Auto-connect',
          child: Switch.adaptive(
            activeThumbImage: const AssetImage('assets/sync.png'),
            inactiveThumbImage: const AssetImage('assets/sync_disabled.png'),
            activeColor: Colors.green.shade600,
            value: _connectToggle,
            onChanged: (value) {
              setState(() => _connectToggle = value);
              if (value) {
                client.connect();
              } else {
                client.disconnect();
              }
            },
          ),
        ),
        title: Text(
          switch (_state) {
            SocketState.disconnected => 'Offline',
            SocketState.connecting => 'Connecting',
            SocketState.connected => _userCount == 1
                ? '$_userCount user online'
                : '$_userCount users online',
          },
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: switch (_state) {
                SocketState.disconnected => Colors.red.shade800,
                SocketState.connecting => Colors.amber,
                SocketState.connected => Colors.green.shade600,
              }),
        ),
        actions: [
          IconButton(
            onPressed: _showInfo,
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
          ),
          IconButton(
            onPressed: _clearCanvas,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear board',
          ),
        ],
      ),
      body: Center(
        child: DrawCanvas(
          points: _points,
          onDraw: _updatePixel,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: colors
                    .sublist(0, colors.length ~/ 2)
                    .map(
                      (color) => ColorButton(
                        color: color,
                        selected: color == _selectedColor,
                        onPressed: () => setState(() => _selectedColor = color),
                      ),
                    )
                    .toList(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: colors
                    .sublist(colors.length ~/ 2, colors.length)
                    .map(
                      (color) => ColorButton(
                        color: color,
                        selected: color == _selectedColor,
                        onPressed: () => setState(() => _selectedColor = color),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('CRDT Draw'),
        content: const Text(
            '''This is a global canvas where anyone can draw.
            
It serves as a demo of Conflict-free Replicated Data Types (CRDTs). Tap "more" to go deeper into the nerd tech stuff.

If you see something that you consider disagreeable just tap the trash icon to clear the board.

Enjoy!'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('More…'.toUpperCase()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Close'.toUpperCase()),
          ),
        ],
      ),
    );
  }

  // Mark all available pixels as deleted
  void _clearCanvas() => crdt.putAll({'pixels': crdt.getMap('pixels')}, true);

  void _updatePixel(int x, int y) =>
      crdt.put('pixels', '$x $y', _selectedColor.toHexString());
}

class ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onPressed;

  const ColorButton({
    super.key,
    required this.color,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 60, maxHeight: 60),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          decoration: BoxDecoration(
            border: selected ? Border.all(width: 2) : null,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: color,
              child: InkWell(
                onTap: onPressed,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  Color toColor() =>
      Color(int.parse(replaceFirst('#', ''), radix: 16) + 0xFF000000);
}

extension ColorX on Color {
  String toHexString() =>
      '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
