package com.example.snehsaathi.features.content

import com.example.snehsaathi.core.tts.OfflineTtsManager
import kotlinx.coroutines.delay

class BhajanKahaaniManager(
    private val ttsManager: OfflineTtsManager
) {
    // Mocked Offline Content Library
    private val bhajans = listOf(
        "अच्चुतम केशवं कृष्ण दामोदरं, राम नारायणं जानकी वल्लभं",
        "रघुपति राघव राजाराम, पतित पावन सीताराम"
    )

    private val stories = listOf(
        "एक बार की बात है, एक समझदार दादी अपने गाँव में..."
    )

    suspend fun playBhajan() {
        val selectedBhajan = bhajans.random()
        ttsManager.speak("दादी, ये लीजिये आपका पसंदीदा भजन... ")
        delay(3000)
        // Note: In production, we'd play pre-rendered MP3s via MediaPlayer here.
        ttsManager.speak(selectedBhajan)
    }

    suspend fun tellStory() {
        ttsManager.speak("आज मैं आपको एक बहुत अच्छी कहानी सुनाती हूँ।")
        delay(3000)
        ttsManager.speak(stories.random())
    }

    // Triggered at 9 PM if Dadi is inactive
    suspend fun triggerGoodnightMode() {
        ttsManager.speak("दादी, रात हो गयी है। चलिए सोने से पहले थोड़ा भजन सुन लें।")
        delay(4000)
        playBhajan()
    }
}
