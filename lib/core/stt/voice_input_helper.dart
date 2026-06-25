import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../network/sarvam_client.dart';

class VoiceInputHelper {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SarvamClient _sarvamClient;
  
  bool _isRecording = false;
  Timer? _silenceTimer;
  String? _audioFilePath;

  VoiceInputHelper(this._sarvamClient);

  Future<void> startListening({
    required Function() onStart,
    required Function() onStop,
    required Function(String) onResult,
    String languageCode = 'hi-IN',
  }) async {
    if (_isRecording) return;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        onResult(_retryPrompt(languageCode));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _audioFilePath = '${tempDir.path}/audio_record.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000, // Lower sample rate for better compatibility with STT
          bitRate: 128000,
        ),
        path: _audioFilePath!,
      );

      _isRecording = true;
      onStart();

      // Start silence detection loop
      _startSilenceDetection(onStop, onResult, languageCode);
    } catch (e) {
      _isRecording = false;
      onStop();
      onResult(_retryPrompt(languageCode));
    }
  }

  bool _isCheckingSilence = false;

  void _startSilenceDetection(Function() onStop, Function(String) onResult, String languageCode) {
    int silenceTicks = 0;
    
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }

      if (_isCheckingSilence) return;
      _isCheckingSilence = true;

      try {
        final amplitude = await _audioRecorder.getAmplitude();
        // Lower threshold to be more sensitive to quiet voices
        if (amplitude.current < -40) {
          silenceTicks++;
        } else {
          silenceTicks = 0;
        }
      } catch (e) {
        silenceTicks++;
      } finally {
        _isCheckingSilence = false;
      }

      // 2 seconds of silence for responsive auto-stop (10 ticks * 200ms)
      if (silenceTicks > 10) {
        timer.cancel();
        stopListening(onStop, onResult, languageCode);
      }
    });
  }

  Future<void> stopListening(Function() onStop, Function(String) onResult, String languageCode) async {
    if (!_isRecording) return;
    _isRecording = false;
    _silenceTimer?.cancel();

    // Play stop beep
    // _audioPlayer.play(AssetSource('sounds/beep_stop.mp3'));

    final path = await _audioRecorder.stop();
    onStop();

    if (path != null) {
      try {
        final text = await _sarvamClient.speechToText(path, languageCode: languageCode);
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          onResult(text);
        } else {
          onResult(_retryPrompt(languageCode));
        }
      } catch (e) {
        onResult(_retryPrompt(languageCode));
      }
    } else {
      onResult(_retryPrompt(languageCode));
    }
  }

  String _retryPrompt(String languageCode) {
    return (languageCode == 'en-IN')
        ? "There is a slight issue. Could you please speak again?"
        : "Phir se boliye. Awaaz saaf nahi aayi.";
  }

  void destroy() {
    _silenceTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}
