package com.example.snehsaathi.features.emotion

enum class EmotionHint {
    SAD, ANXIOUS, CONFUSED, NEUTRAL
}

data class VoiceEmotion(
    val energy: Float,       // RMS amplitude (0.0 to 1.0)
    val speakingRate: Float, // Words/syllables per second estimate
    val pitchVariance: Float // Monotone = low variance
)

object VoiceEmotionClassifier {
    
    fun classifyEmotion(sample: VoiceEmotion): EmotionHint {
        return when {
            // Low energy, monotone voice suggests sadness or depression
            sample.energy < 0.15f && sample.pitchVariance < 0.1f -> EmotionHint.SAD
            
            // High speaking rate with high energy suggests anxiety/panic
            sample.speakingRate > 3.5f && sample.energy > 0.7f -> EmotionHint.ANXIOUS
            
            // Very slow speaking rate suggests confusion or cognitive load
            sample.speakingRate < 0.8f -> EmotionHint.CONFUSED
            
            else -> EmotionHint.NEUTRAL
        }
    }

    fun getAdaptiveGreeting(emotion: EmotionHint): String {
        return when (emotion) {
            EmotionHint.SAD -> "दादी, आज थोड़ी उदास लग रही हैं... सब ठीक है?"
            EmotionHint.ANXIOUS -> "दादी आराम से बोलिए, मैं सुन रही हूँ। क्या हुआ?"
            EmotionHint.CONFUSED -> "मैं धीरे बोलती हूँ दादी। आपको क्या मदद चाहिए?"
            EmotionHint.NEUTRAL -> "जी दादी, बताइए।"
        }
    }
}
