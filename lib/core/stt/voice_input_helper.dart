import 'dart:async';
import 'package:flutter/foundation.dart';
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
    if (_isRecording) {
      debugPrint('[STT] startListening called but already recording — ignoring');
      return;
    }

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('[STT] Microphone permission: $hasPermission');
      if (!hasPermission) {
        debugPrint('[STT] ❌ No microphone permission!');
        onResult(_retryPrompt(languageCode));
        return;
      }

      final tempDir = await getTemporaryDirectory();
      _audioFilePath = '${tempDir.path}/audio_record.m4a';
      debugPrint('[STT] Recording to: $_audioFilePath');

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100, // Universally supported sample rate on physical hardware
          bitRate: 128000,
        ),
        path: _audioFilePath!,
      );

      _isRecording = true;
      debugPrint('[STT] ✅ Recording started successfully');
      onStart();

      // Start silence detection loop
      _startSilenceDetection(onStop, onResult, languageCode);
    } catch (e) {
      debugPrint('[STT] ❌ Error starting recording: $e');
      _isRecording = false;
      onStop();
      onResult(_retryPrompt(languageCode));
    }
  }


  bool _isCheckingSilence = false;

  void _startSilenceDetection(Function() onStop, Function(String) onResult, String languageCode) {
    int silenceTicks = 0;
    int totalTicks = 0;
    bool speechDetected = false;
    
    // Ambient noise calibration: collect first ~1s of amplitude readings
    final List<double> calibrationSamples = [];
    double noiseFloor = -45.0; // Default fallback
    bool calibrated = false;
    
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
        final db = amplitude.current;
        totalTicks++;
        
        // Phase 1: Calibrate ambient noise floor (first ~1 second = 5 ticks)
        if (!calibrated) {
          calibrationSamples.add(db);
          if (calibrationSamples.length >= 5) {
            // Average the samples to get ambient noise floor
            noiseFloor = calibrationSamples.reduce((a, b) => a + b) / calibrationSamples.length;
            calibrated = true;
            debugPrint('[STT] 🎚️ Noise floor calibrated: ${noiseFloor.toStringAsFixed(1)} dB');
          }
          _isCheckingSilence = false;
          return;
        }

        // Log every ~2 seconds for debugging
        if (totalTicks % 10 == 0) {
          debugPrint('[STT] 🎤 Amplitude: ${db.toStringAsFixed(1)} dB | Floor: ${noiseFloor.toStringAsFixed(1)} dB | Speech: $speechDetected | SilenceTicks: $silenceTicks');
        }

        // Speech is detected when amplitude rises 8dB above noise floor
        final speechThreshold = noiseFloor + 8;
        
        if (db > speechThreshold) {
          // Someone is speaking
          if (!speechDetected) {
            debugPrint('[STT] 🗣️ Speech detected! (${db.toStringAsFixed(1)} dB > ${speechThreshold.toStringAsFixed(1)} dB threshold)');
          }
          speechDetected = true;
          silenceTicks = 0;
        } else if (speechDetected) {
          // Speech was detected before, now it's quiet again
          silenceTicks++;
        }
        // If no speech detected yet, don't count silence ticks
        
      } catch (e) {
        debugPrint('[STT] Amplitude check error: $e');
        if (speechDetected) silenceTicks++;
      } finally {
        _isCheckingSilence = false;
      }

      // Auto-stop after 2.5s of post-speech silence (12 ticks * 200ms)
      if (speechDetected && silenceTicks > 12) {
        debugPrint('[STT] ✅ 2.5s post-speech silence — auto-stopping');
        timer.cancel();
        stopListening(onStop, onResult, languageCode);
        return;
      }
      
      // Safety cap: max 30 seconds of recording (150 ticks * 200ms)
      if (totalTicks > 150) {
        debugPrint('[STT] ⏱️ 30s max recording reached — auto-stopping');
        timer.cancel();
        stopListening(onStop, onResult, languageCode);
        return;
      }
    });
  }

  Future<void> stopListening(Function() onStop, Function(String) onResult, String languageCode) async {
    if (!_isRecording) {
      debugPrint('[STT] stopListening called but not recording — ignoring');
      return;
    }
    _isRecording = false;
    _silenceTimer?.cancel();

    final path = await _audioRecorder.stop();
    debugPrint('[STT] Recording stopped. File path: $path');
    onStop();

    if (path != null) {
      try {
        debugPrint('[STT] Sending audio to Sarvam STT API (lang=$languageCode)...');
        final text = await _sarvamClient.speechToText(path, languageCode: languageCode);
        debugPrint('[STT] Sarvam STT result: "$text"');
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          onResult(text);
        } else {
          debugPrint('[STT] ⚠️ Empty or null transcript');
          onResult(_retryPrompt(languageCode));
        }
      } catch (e) {
        debugPrint('[STT] ❌ Sarvam STT API error: $e');
        onResult(_retryPrompt(languageCode));
      }
    } else {
      debugPrint('[STT] ❌ Recording path was null after stop');
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
