import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'localization_service.dart';
import 'sarvam_service.dart';

class VoiceAssistantSheet extends StatefulWidget {
  final IndicLanguage language;
  final SarvamAiService sarvam;
  final Function({
    required String category,
    required double weight,
    required String condition,
    required String transcript,
  }) onExtracted;

  const VoiceAssistantSheet({
    super.key,
    required this.language,
    required this.sarvam,
    required this.onExtracted,
  });

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool isRecording = false;
  bool isProcessing = false;
  int recordDurationSeconds = 0;
  Timer? _timer;

  final textCtrl = TextEditingController();
  String? extractedSummary;
  String? _lastExtractedCat;
  double? _lastExtractedWt;
  String? _lastExtractedCond;
  String? _lastExtractedQuery;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animCtrl.dispose();
    _audioRecorder.dispose();
    textCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    debugPrint('[VoiceAssistant] Microphone permission: $hasPermission');
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for voice capture.'),
            backgroundColor: Color(0xFF0F382A),
          ),
        );
      }
      return;
    }

    try {
      String? targetPath;
      if (!kIsWeb) {
        final tempDir = await getTemporaryDirectory();
        targetPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      debugPrint('[VoiceAssistant] Starting recording... path=${targetPath ?? "(web blob)"}');
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, bitRate: 128000),
        path: targetPath ?? '',
      );
      debugPrint('[VoiceAssistant] Recording started successfully');

      setState(() {
        isRecording = true;
        recordDurationSeconds = 0;
        extractedSummary = null;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => recordDurationSeconds++);
        if (recordDurationSeconds >= 6) {
          _stopRecordingAndProcess();
        }
      });
    } catch (e) {
      debugPrint('[VoiceAssistant] Recording hardware init FAILED: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Microphone not available: $e'),
            backgroundColor: const Color(0xFF8B1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingAndProcess([String? customTranscript]) async {
    _timer?.cancel();
    String? audioPath;

    if (isRecording) {
      try {
        audioPath = await _audioRecorder.stop();
        debugPrint('[VoiceAssistant] Recording stopped. audioPath=$audioPath');
      } catch (e) {
        debugPrint('[VoiceAssistant] Error stopping recorder: $e');
      }
    }

    setState(() {
      isRecording = false;
      isProcessing = true;
    });

    String? transcribedLive;

    // Only attempt transcription if we have audio bytes (not when user tapped a sample phrase)
    if (customTranscript == null && audioPath != null && audioPath.isNotEmpty) {
      try {
        List<int> bytes = [];
        if (kIsWeb && audioPath.startsWith('blob:')) {
          debugPrint('[VoiceAssistant] Web blob detected, fetching bytes...');
          final res = await http.get(Uri.parse(audioPath));
          bytes = res.bodyBytes;
          debugPrint('[VoiceAssistant] Fetched ${bytes.length} bytes from blob');
        } else {
          debugPrint('[VoiceAssistant] Native file path, reading bytes...');
          final xfile = XFile(audioPath);
          bytes = await xfile.readAsBytes();
          debugPrint('[VoiceAssistant] Read ${bytes.length} bytes from file');
        }

        if (bytes.isNotEmpty) {
          debugPrint('[VoiceAssistant] Sending ${bytes.length} bytes to Sarvam STT...');
          debugPrint('[VoiceAssistant] API key active: ${widget.sarvam.hasActiveKey}');
          transcribedLive = await widget.sarvam.transcribeAudioBytes(
            audioBytes: bytes,
            language: widget.language,
          );
          debugPrint('[VoiceAssistant] Sarvam STT result: "$transcribedLive"');
        } else {
          debugPrint('[VoiceAssistant] WARNING: Audio bytes are empty!');
        }
      } catch (e) {
        debugPrint('[VoiceAssistant] Transcription error: $e');
      }
    }

    // Determine the final text to process
    String? query;
    if (customTranscript != null && customTranscript.trim().isNotEmpty) {
      // User typed text or tapped a sample phrase — use it directly
      query = customTranscript.trim();
      debugPrint('[VoiceAssistant] Using custom/typed transcript: "$query"');
    } else if (transcribedLive != null && transcribedLive.trim().isNotEmpty) {
      // Real transcription from Sarvam succeeded
      query = transcribedLive.trim();
      debugPrint('[VoiceAssistant] Using live transcription: "$query"');
    } else if (textCtrl.text.trim().isNotEmpty) {
      // User had typed something in the text field
      query = textCtrl.text.trim();
      debugPrint('[VoiceAssistant] Using typed text field: "$query"');
    } else {
      // Transcription failed and nothing was typed — show error, don't use sample
      debugPrint('[VoiceAssistant] No transcription result and no typed text. Showing error.');
      if (mounted) {
        setState(() => isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice not recognised. Please speak again or tap a sample phrase below.',
            ),
            backgroundColor: Color(0xFF8B1A1A),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    textCtrl.text = query;

    // Process through Sarvam Saaras Parser
    final result = await widget.sarvam.parseVoiceInput(
      speechQuery: query,
      language: widget.language,
    );

    if (!mounted) return;

    final cat = result['category'] as String;
    final wt = result['weight'] != null ? (result['weight'] as num).toDouble() : null;
    final cond = result['condition'] as String;

    _lastExtractedCat = cat;
    _lastExtractedWt = wt;
    _lastExtractedCond = cond;
    _lastExtractedQuery = query;

    setState(() {
      isProcessing = false;
      extractedSummary = wt != null
          ? '$cat • ${wt.toStringAsFixed(wt.truncateToDouble() == wt ? 0 : 1)} kg • $cond'
          : '$cat • $cond';
    });

    // Provide natural neural speech feedback confirming the actual spoken item
    final wtStr = wt != null ? wt.toStringAsFixed(wt.truncateToDouble() == wt ? 0 : 1) : '';
    final spokenMsg = widget.language == IndicLanguage.hindi
        ? (wt != null ? '$cat $wtStr किलो, $cond स्वीकार किया गया।' : '$cat, $cond स्वीकार किया गया।')
        : widget.language == IndicLanguage.marathi
            ? (wt != null ? '$cat $wtStr किलो, $cond नोंदवले गेले.' : '$cat, $cond नोंदवले गेले.')
            : (wt != null ? '$cat, $wtStr kilograms, $cond confirmed.' : '$cat, $cond confirmed.');

    widget.sarvam.speakText(text: spokenMsg, language: widget.language);

    widget.onExtracted(
      category: cat,
      weight: wt ?? 0.0,
      condition: cond,
      transcript: query,
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentLime = Color(0xFFC6F24D);
    const mintGlow = Color(0xFF4DF2C6);
    const inkDark = Color(0xFF0C241B);
    const surfaceEmerald = Color(0xFF163E2E);
    const cardBorder = Color(0x554DF2C6);

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentLime.withAlpha(50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded, color: accentLime, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sarvam Saaras Voice AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Listening in ${widget.language.englishLabel} (${widget.language.nativeLabel})',
                        style: const TextStyle(color: mintGlow, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Central Animated Microphone & Waveform
          Center(
            child: GestureDetector(
              onTap: () {
                if (isRecording) {
                  _stopRecordingAndProcess();
                } else if (!isProcessing) {
                  _startRecording();
                }
              },
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  final waveSpread = isRecording ? _animCtrl.value * 25.0 : 0.0;
                  return Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isRecording
                            ? [const Color(0xFFFF5252), const Color(0xFFFF1744)]
                            : [accentLime, mintGlow],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isRecording ? const Color(0xFFFF5252) : accentLime)
                              .withAlpha(isRecording ? 120 : 60),
                          blurRadius: 20 + waveSpread,
                          spreadRadius: waveSpread / 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 48,
                      color: isRecording ? Colors.white : inkDark,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Status & Audio Waveform Indicators
          Center(
            child: Text(
              isRecording
                  ? 'Recording live audio... 00:0${recordDurationSeconds}s'
                  : isProcessing
                      ? 'Parsing through Sarvam Saaras AI...'
                      : 'Tap mic to speak scrap lot details',
              style: TextStyle(
                color: isRecording ? const Color(0xFFFF8A80) : Colors.white70,
                fontSize: 13,
                fontWeight: isRecording ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Live Text / Speech Input Box
          TextField(
            controller: textCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Or type/speak lot details here...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: surfaceEmerald,
              prefixIcon: const Icon(Icons.edit_note_rounded, color: accentLime),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, color: accentLime),
                onPressed: () => _stopRecordingAndProcess(textCtrl.text.trim()),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: cardBorder),
              ),
            ),
          ),

          const SizedBox(height: 14),

          if (extractedSummary != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentLime.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentLime),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: accentLime, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Extracted: $extractedSummary',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentLime,
              foregroundColor: inkDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (_lastExtractedCat != null) {
                widget.onExtracted(
                  category: _lastExtractedCat!,
                  weight: _lastExtractedWt ?? 0.0,
                  condition: _lastExtractedCond ?? textCtrl.text.trim(),
                  transcript: _lastExtractedQuery ?? textCtrl.text.trim(),
                );
              } else if (textCtrl.text.trim().isNotEmpty) {
                // Parse typed text through the same voice parser to detect category/weight/condition
                final parsed = await widget.sarvam.parseVoiceInput(
                  speechQuery: textCtrl.text.trim(),
                  language: widget.language,
                );
                widget.onExtracted(
                  category: parsed['category'] as String,
                  weight: parsed['weight'] != null ? (parsed['weight'] as num).toDouble() : 0.0,
                  condition: parsed['condition'] as String,
                  transcript: textCtrl.text.trim(),
                );
              }
              if (!mounted) return;
              navigator.pop();
            },
            child: const Text('Confirm & Apply to Lot', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
