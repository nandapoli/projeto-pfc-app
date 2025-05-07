import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/storage_service.dart'; // Importa o serviço de armazenamento
import 'package:fl_chart/fl_chart.dart';

// Tela que exibe o histórico das partidas
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, List<GameResult>> _gameHistory = {}; // Lista com o histórico das partidas
  Map<String, Set<int>> _chartsVisible = {}; // Controla quais índices de gráficos estão visíveis

  @override
  void initState() {
    super.initState();
    _loadHistory(); // Carrega os dados ao iniciar a tela
  }

  // Método que carrega os dados usando o StorageService
  Future<void> _loadHistory() async {
    final history = await StorageService.loadData(); // Carrega os dados do SharedPreferences
    setState(() {
      _gameHistory = history; // Atualiza o estado da tela com o histórico carregado
      _chartsVisible = {
        for (var key in history.keys) key: <int>{}
      };
    });
  }

 // Converter o tempo de jogo para exibição mais amigável
  String _formatGameTime(int? gameTime) {
    return gameTime == null ? "Ilimitado" : "$gameTime segundos";
  }

  String _formatDateTime(DateTime dt) {
  return "${dt.day.toString().padLeft(2, '0')}/"
         "${dt.month.toString().padLeft(2, '0')}/"
         "${dt.year} às "
         "${dt.hour.toString().padLeft(2, '0')}:"
         "${dt.minute.toString().padLeft(2, '0')}";
  }

  //Gera o gráfico de linha
  Widget _buildChart(List<double> times) {
  if (times.isEmpty) return SizedBox.shrink();

  final spots = times
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble() + 1, e.value))
      .toList();

  final minY = times.reduce((a, b) => a < b ? a : b);
  final maxY = times.reduce((a, b) => a > b ? a : b);
  
  // Calcular um intervalo apropriado para o eixo Y
  // Queremos entre 4-6 divisões no eixo Y
  final range = maxY - minY;
  final targetDivisions = 5;
  double interval = range / targetDivisions;
  
  // Arredondar o intervalo para um número mais "amigável"
  if (interval <= 10) {
    interval = 10; // Se o intervalo for pequeno, use 10
  } else if (interval <= 50) {
    interval = 50; // Se for médio, use 50
  } else if (interval <= 100) {
    interval = 100; // Se for grande, use 100
  } else {
    // Para valores muito grandes, arredondar para o múltiplo de 100 mais próximo
    interval = (interval / 100).ceil() * 100;
  }

  return RepaintBoundary(
    key: GlobalKey(),
    child: SizedBox(
      height: 250,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
        child: LineChart(
          LineChartData(
            minY: minY - (minY % interval) * 0.5,
            maxY: maxY + (interval - maxY % interval) * 0.5,
            titlesData: FlTitlesData(
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(value.toInt().toString(), style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: interval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: true,
              horizontalInterval: interval,
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            // Adicionar linhas horizontais extras para valores exatos (opcional)
            extraLinesData: ExtraLinesData(
              horizontalLines: spots.map((spot) {
                return HorizontalLine(
                  y: spot.y,
                  color: Colors.black.withValues(alpha: 0.4),
                  strokeWidth: 0.5,
                  dashArray: [5, 5], // Linha pontilhada para diferenciar das linhas principais
                );
              }).toList(),
            ),
            clipData: FlClipData.none(),
          ),
        ),
      ),
    ),
  );
}



  Future<void> _deleteResult(String timeKey, int index) async {
    final updatedList = List<GameResult>.from(_gameHistory[timeKey]!);
    updatedList.removeAt(index);
    setState(() {
      if (updatedList.isEmpty) {
        _gameHistory.remove(timeKey);
        _chartsVisible.remove(timeKey);
      } else {
        _gameHistory[timeKey] = updatedList;
      }
    });
    await StorageService.saveMatch(_gameHistory);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Histórico de Partidas"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _gameHistory.isEmpty
          ? Center(child: Text("Nenhuma partida salva"))
          : ListView.builder(
              itemCount: _gameHistory.keys.length,
              itemBuilder: (context, index) {
                String gameTime = _gameHistory.keys.elementAt(index);
                List<GameResult> results = _gameHistory[gameTime]!;

                return Card(
                  margin: EdgeInsets.all(10),
                  child: ExpansionTile(
                    title: Text(_formatGameTime(int.tryParse(gameTime))),
                    children: results.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final game = entry.value;
                      final isChartVisible = _chartsVisible[gameTime]!.contains(idx);

                      return Column(
                        children: [
                          ListTile(
                            title: Text("Média: ${game.avgReaction.toStringAsFixed(2)} ms"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Taxa de acerto: ${game.accuracyRate.toStringAsFixed(2)}%"),
                                Text("Data: ${_formatDateTime(game.dateTime)}"),
                              ],
                            ),
                          ),
                          OverflowBar(
                            alignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: Icon(isChartVisible ? Icons.hide_source : Icons.show_chart),
                                label: Text(isChartVisible ? "Ocultar gráfico" : "Ver gráfico"),
                                onPressed: () {
                                  setState(() {
                                    if (isChartVisible) {
                                      _chartsVisible[gameTime]!.remove(idx);
                                    } else {
                                      _chartsVisible[gameTime]!.add(idx);
                                    }
                                  });
                                },
                              ),
                              TextButton.icon(
                                icon: Icon(Icons.delete),
                                label: Text("Excluir"),
                                onPressed: () {
                                  _deleteResult(gameTime, idx);
                                },
                              ),
                            ],
                          ),
                          if (isChartVisible && game.reactionTimes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildChart(game.reactionTimes),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}


