import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';

class CallingScreen extends StatefulWidget {
  final String name;
  final String phone;

  const CallingScreen({super.key, required this.name, this.phone = ''});

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  bool _isMuted = false;
  bool _isSpeaker = false;
  int _callDuration = 0;
  Timer? _timer;
  String _status = 'Calling...';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _status = 'Connected');
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  String _formatDuration(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.header),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            
              Column(
                children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.white.withOpacity(0.2),
                    child: Text(
                      widget.name.isNotEmpty ? widget.name[0].toUpperCase() : 'C',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status == 'Connected' ? _formatDuration(_callDuration) : _status,
                    style: TextStyle(fontSize: 16, color: AppColors.white.withOpacity(0.85)),
                  ),
                ],
              ),

             
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _callOption(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: 'Mute',
                          isActive: _isMuted,
                          onTap: () => setState(() => _isMuted = !_isMuted),
                        ),
                        _callOption(
                          icon: _isSpeaker ? Icons.volume_up : Icons.volume_down,
                          label: 'Speaker',
                          isActive: _isSpeaker,
                          onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end, color: AppColors.white, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? AppColors.white : AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isActive ? AppColors.darkAccent : AppColors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: AppColors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
