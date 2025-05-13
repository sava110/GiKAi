import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Room {
  final String id;  // 部屋ID
  final String label;  // 部屋ラベル（表示用）
  final String description;  // 部屋の説明
  final double x,y;  // マップ上の座標（左上基準）
  final double width,height;  // 部屋の幅と高さ

  Room({
    required this.id,
    required this.label,
    required this.description,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  // JSONからRoomオブジェクトを作成するファクトリ
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      label: json['label'],
      description: json['description'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
    );
  }
}

class Floor {
  final String mapImage;  // フロアのマップ画像ファイルパス
  final List<Room> rooms;  // 部屋のリスト

  Floor({
    required this.mapImage,
    required this.rooms,
  });

  // JSONからFloorオブジェクトを作成するファクトリ
  factory Floor.fromJson(Map<String, dynamic> json) {
    var roomsList = (json['rooms'] as List)
        .map((roomJson) => Room.fromJson(roomJson))
        .toList();

    return Floor(
      mapImage: json['mapImage'],
      rooms: roomsList,
    );
  }
}

class BuildingData {
  final Map<String, Floor> floors;  // フロア名をキーとするfloorのマップ

  BuildingData({
    required this.floors,
  });

  // JSONからBuildingDataオブジェクトを作成
  factory BuildingData.fromJson(Map<String, dynamic> json) {
    Map<String, Floor> floorsMap = {};

    (json['floors'] as Map<String, dynamic>).forEach((key, value) {
      floorsMap[key] = Floor.fromJson(value);
    });

    return BuildingData(
      floors: floorsMap,
    );
  }

  // JSONファイルからデータを読み込む非同期メソッド
  static Future<BuildingData> load() async {
    final String jsonData = await rootBundle.loadString('assets/room_data.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonData);
    return BuildingData.fromJson(jsonMap);
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _currentFloor = '1F';  // 現在表示しているフロア
  String _currentRoomDescription = '';  // 現在表示しているフロア
  Offset? tapPosition;  // タップ位置（今後使える）
  BuildingData? _buildingData;  // 読み込まれた校舎データ
  bool _isLoading = true;  // ローディング中かどうか

  String? _selectedRoomId;  // 選択されている部屋のID

  @override
  void initState() {
    super.initState();
    _loadBuildingData();  // 初期化時にデータ読み込み
  }

  Future<void> _loadBuildingData() async {
    try {
      final data = await BuildingData.load();
      setState(() {
        _buildingData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('JSONデータの読み込みエラー: $e');
    }
  }

  void _onRoomTapped(String roomId) {
    setState(() {
      // 同じ部屋をタップした場合は選択を解除
      if (_selectedRoomId == roomId) {
        _selectedRoomId = null;
        _currentRoomDescription = '';
      } else {
        _selectedRoomId = roomId;

        // 部屋の説明を設定
        if (_buildingData != null) {
          final floor = _buildingData!.floors[_currentFloor];
          if (floor != null) {
            final room = floor.rooms.firstWhere((r) => r.id == roomId, orElse: () =>
                Room(id: '', label: '', description: '説明がありません', x: 0, y: 0, width: 0, height: 0));
            _currentRoomDescription = room.description;
          }
        }
      }
    });
  }

  void _onImageTapped(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    setState(() {
      tapPosition = localPosition;
    });
    debugPrint("Tapped at: ${localPosition.dx}, ${localPosition.dy}");
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('校舎棟マップ'),
        actions: [
          DropdownButton<String>(
            value: _currentFloor,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentFloor = value;
                  tapPosition = null;
                  _currentRoomDescription = '';
                  _selectedRoomId = null;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: '1F', child: Text('1F')),
              DropdownMenuItem(value: '2F', child: Text('2F')),
              DropdownMenuItem(value: '3F', child: Text('3F')),
              DropdownMenuItem(value: '4F', child: Text('4F')),
              DropdownMenuItem(value: '5F', child: Text('5F')),
              DropdownMenuItem(value: '6F', child: Text('6F')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildingData == null
          ? const Center(child: Text('データの読み込みに失敗しました'))
          : GestureDetector(
        onTapDown: _onImageTapped,
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          constrained: false,
          child: Stack(
            children: [
              // マップ画像
              Image.asset(
                _getMapAssetPath(),
                width: screenSize.width,
                fit: BoxFit.contain,
              ),

              // 部屋
              ..._buildRooms(screenSize),

              // 説明文
              if (_currentRoomDescription.isNotEmpty)
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _currentRoomDescription,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMapAssetPath() {
    if (_buildingData == null) {
      return 'assets/map-1F.png';
    }

    final floor = _buildingData!.floors[_currentFloor];
    if (floor == null) {
      return 'assets/map-1F.png';
    }

    return floor.mapImage;
  }

  List<Widget> _buildRooms(Size screenSize) {
    if (_buildingData == null) {
      return [];
    }

    final floor = _buildingData!.floors[_currentFloor];
    if (floor == null) {
      return [];
    }

    final scale = screenSize.width / 792; // 画像の元サイズに対する比率

    return floor.rooms.map((room) {
      return Positioned(
        left: room.x * scale,
        top: room.y * scale,
        child: GestureDetector(
          onTap: () => _onRoomTapped(room.id),
          child: Container(
            width: room.width * scale,
            height: room.height * scale,
            color: _selectedRoomId == room.id
                ? Colors.red.withOpacity(0.6)
                : Colors.grey.withOpacity(0.6),
            child: Center(
              child: Text(
                room.label,
                style: TextStyle(fontSize: 12 * scale),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
