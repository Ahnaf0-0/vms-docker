import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/theme/glass_theme.dart';
import 'scanner_overlay.dart';

class CameraCaptureScreen extends StatefulWidget {
  final Map<String, dynamic> visitorData;
  const CameraCaptureScreen({super.key, required this.visitorData});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  
  bool _cameraActive = false;
  int _currentSelfieIndex = 0; // 0 = Front, 1 = Left, 2 = Right
  final List<String> _titles = ['সামনের ছবি তুলুন', 'বাম পাশের ছবি তুলুন', 'ডান পাশের ছবি তুলুন'];
  final List<String> _photoKeys = ['photo_front', 'photo_left', 'photo_right'];

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _cameraActive = true;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    final image = await _controller!.takePicture();
    widget.visitorData[_photoKeys[_currentSelfieIndex]] = image.path;
    
    setState(() {
      if (_currentSelfieIndex < 2) {
        _currentSelfieIndex++;
      } else {
        _finishRegistration();
      }
    });
  }

  void _finishRegistration() {
    // In the future, this is where we send the data to FastAPI.
    // For now, we mock the success.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration complete!')),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ID & Selfie"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: GlassTheme.backgroundGradient,
        child: SafeArea(
          child: !_cameraActive ? _buildInstructionView() : _buildCameraView(),
        ),
      ),
    );
  }

  Widget _buildInstructionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF25424), width: 2),
                  color: GlassTheme.primaryViolet.withValues(alpha: 0.1),
                ),
                child: const Icon(LucideIcons.user, size: 80, color: GlassTheme.primaryViolet),
              ),
              const SizedBox(height: 32),
              _buildInstructionItem('১', 'ছবি তোলার সময় চোখ থেকে চশমা (যদি থাকে) খুলে ফেলুন।'),
              _buildInstructionItem('২', 'আপনার সামনের, বাম এবং ডান পাশের ৩টি ছবি নেওয়া হবে।'),
              _buildInstructionItem('৩', 'ছবি তোলার সময় আপনার চারপাশে পর্যাপ্ত আলো থাকতে হবে।'),
              _buildInstructionItem('৪', 'ছবি তোলার সময় ক্যামেরা স্থির রাখুন।'),
              _buildInstructionItem('৫', 'ছবি তুলতে ফ্রেমের নিচের নির্দেশনা গুলো অনুসরণ করুন।'),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GlassTheme.primaryViolet,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('পরবর্তী ধাপ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: GlassTheme.primaryViolet.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: GlassTheme.primaryViolet)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: GlassTheme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_titles[_currentSelfieIndex], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: GlassTheme.textPrimary)),
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: GlassTheme.primaryViolet.withValues(alpha: 0.2), width: 4),
              ),
              clipBehavior: Clip.hardEdge,
              child: _controller != null && _controller!.value.isInitialized
                  ? Builder(
                      builder: (context) {
                        final aspect = _controller!.value.aspectRatio;
                        final scale = aspect < 1.0 ? 1.0 / aspect : aspect;
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: Transform.scale(
                                scale: scale,
                                child: Center(
                                  child: CameraPreview(_controller!),
                                ),
                              ),
                            ),
                            // Orange progress arc indicator
                            const Positioned.fill(
                              child: ScannerOverlay(),
                            ),
                          ],
                        );
                      }
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 40),
          const Text('ছবি তোলার জন্য প্রস্তুত।', style: TextStyle(fontSize: 18, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _capturePhoto,
            icon: const Icon(LucideIcons.camera),
            label: const Text('Capture'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GlassTheme.primaryViolet,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _cameraActive = false;
                _currentSelfieIndex = 0;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              side: const BorderSide(color: GlassTheme.textSecondary),
            ),
            child: const Text('Cancel', style: TextStyle(color: GlassTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

