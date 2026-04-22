import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const TetrisApp());

class TetrisApp extends StatelessWidget {
  const TetrisApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const TetrisGame(),
  );
}

class TetrisGame extends StatefulWidget {
  const TetrisGame({super.key});
  @override
  State<TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const int row = 20;
  static const int col = 10;

  bool isGameStarted = false;
  List<int> currentPiece = [];
  String currentType = 'I';
  int score = 0;
  int highScore = 0;
  List<int> occupiedCells = [];
  Timer? gameTimer;

  void _createNewPiece() {
    final random = Random();
    List<String> types = ['I', 'O', 'T', 'S', 'Z', 'J', 'L'];
    currentType = types[random.nextInt(types.length)];

    switch (currentType) {
      case 'I': currentPiece = [4, 14, 24, 34]; break;
      case 'O': currentPiece = [4, 5, 14, 15]; break;
      case 'T': currentPiece = [4, 13, 14, 15]; break;
      case 'S': currentPiece = [5, 4, 14, 13]; break;
      case 'Z': currentPiece = [4, 5, 15, 16]; break;
      case 'J': currentPiece = [4, 14, 24, 23]; break;
      case 'L': currentPiece = [4, 14, 24, 25]; break;
    }
  }

  void _startGame() {
    setState(() {
      isGameStarted = true;
      score = 0;
      occupiedCells.clear();
      _createNewPiece();
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        if (_canMove(col)) {
          for (int i = 0; i < currentPiece.length; i++) {
            currentPiece[i] += col;
          }
        } else {
          _landPiece();
        }
      });
    });
  }

  bool _canMove(int delta) {
    for (int index in currentPiece) {
      int next = index + delta;
      if (next >= row * col || occupiedCells.contains(next)) return false;
      if (delta == -1 && index % col == 0) return false;
      if (delta == 1 && index % col == col - 1) return false;
    }
    return true;
  }

  void _landPiece() {
    occupiedCells.addAll(currentPiece);
    _checkLines();
    _createNewPiece();
    if (currentPiece.any((index) => occupiedCells.contains(index))) {
      _showGameOverDialog();
    }
  }

  void _checkLines() {
    for (int r = 0; r < row; r++) {
      bool isFull = true;
      for (int c = 0; c < col; c++) {
        if (!occupiedCells.contains(r * col + c)) {
          isFull = false;
          break;
        }
      }
      if (isFull) {
        setState(() {
          score += 100;
          if (score > highScore) highScore = score;
          occupiedCells.removeWhere((i) => i >= r * col && i < (r + 1) * col);
          occupiedCells = occupiedCells.map((i) => i < r * col ? i + col : i).toList();
        });
      }
    }
  }

  void _showGameOverDialog() {
    gameTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("GAME OVER",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Игра окончена!"),
            const SizedBox(height: 10),
            Text("Ваш счет: $score", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => isGameStarted = false);
              },
              child: const Text("В ГЛАВНОЕ МЕНЮ", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _rotatePiece() {
    setState(() {
      int pivot = currentPiece[1];
      int pr = pivot ~/ col;
      int pc = pivot % col;

      List<int> nextRotation = currentPiece.map((index) {
        int r = index ~/ col;
        int c = index % col;
        return (pr + (c - pc)) * col + (pc - (r - pr));
      }).toList();

      bool canRotate = nextRotation.every((idx) =>
      idx >= 0 && idx < row * col && !occupiedCells.contains(idx) &&
          (idx % col - pc).abs() < 4
      );

      if (canRotate) currentPiece = nextRotation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: isGameStarted ? _buildGameScreen() : _buildMenuScreen(),
    );
  }

  Widget _buildMenuScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("TETRIS", style: TextStyle(fontSize: 70, fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            child: const Text("ИГРАТЬ", style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 80),
          Text("MAX RECORD: $highScore", style: const TextStyle(fontSize: 18, color: Colors.amber)),
        ],
      ),
    );
  }

  Widget _buildGameScreen() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text("SCORE: $score", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
            child: GridView.builder(
              itemCount: row * col,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: col),
              itemBuilder: (context, index) {
                Color color = Colors.grey[900]!;
                if (currentPiece.contains(index)) color = Colors.indigoAccent;
                if (occupiedCells.contains(index)) color = Colors.white24;
                return Container(margin: const EdgeInsets.all(1), color: color);
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(iconSize: 50, icon: const Icon(Icons.arrow_back), onPressed: () => setState(() { if(_canMove(-1)) { for(int i=0; i<currentPiece.length; i++) currentPiece[i]--; } })),
              IconButton(iconSize: 50, icon: const Icon(Icons.rotate_right), onPressed: _rotatePiece),
              IconButton(iconSize: 50, icon: const Icon(Icons.arrow_forward), onPressed: () => setState(() { if(_canMove(1)) { for(int i=0; i<currentPiece.length; i++) currentPiece[i]++; } })),
            ],
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }
}