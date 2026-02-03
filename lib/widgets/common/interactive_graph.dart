import 'package:flutter/material.dart';

class InteractiveGraph extends StatefulWidget {
  final List<double> dataPoints;
  final List<String> labels;
  final double maxHeight;
  final Color color;

  const InteractiveGraph({
    super.key,
    required this.dataPoints,
    required this.labels,
    this.maxHeight = 200,
    required this.color,
  });

  @override
  State<InteractiveGraph> createState() => _InteractiveGraphState();
}

class _InteractiveGraphState extends State<InteractiveGraph> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dataPoints.isEmpty) {
      return SizedBox(
        height: widget.maxHeight,
        child: const Center(child: Text("No Data Available")),
      );
    }

    final maxVal = widget.dataPoints.reduce((curr, next) => curr > next ? curr : next);

    return SizedBox(
      height: widget.maxHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          const labelHeight = 60.0; // Increased to safe-guard against overflow
          final maxBarHeight = (availableHeight - labelHeight).clamp(0.0, double.infinity); 
          
          final barWidth = constraints.maxWidth / (widget.dataPoints.length * 1.5);
          
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.dataPoints.length, (index) {
              final value = widget.dataPoints[index];
              final normalizedHeight = (maxVal == 0) ? 0.0 : (value / maxVal) * maxBarHeight;

              return MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     // Tooltip container (overlay logic would be better, but keeping simple for now)
                    if (_hoveredIndex == index)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      )
                    else 
                      const SizedBox(height: 24), // Placeholder to keep alignment if needed, or remove to float

                    // Bar
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Container(
                          height: normalizedHeight * _animation.value,
                          width: barWidth,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                widget.color.withOpacity(0.5),
                                widget.color,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                             boxShadow: _hoveredIndex == index
                                ? [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]
                                : [],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.labels[index],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
