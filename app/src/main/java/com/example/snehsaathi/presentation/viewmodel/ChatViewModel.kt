package com.example.snehsaathi.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.snehsaathi.core.network.ConnectivityObserver
import com.example.snehsaathi.core.tts.OfflineTtsManager
import com.example.snehsaathi.data.repository.MemoryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

enum class ResponseSource { CLOUD, OFFLINE, NONE }

data class UiState(
    val response: String = "Dadi, namaste. Main yahin hoon. Aap jab chaahen bol sakti hain.",
    val source: ResponseSource = ResponseSource.NONE,
    val isProcessing: Boolean = false
)

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val connectivityObserver: ConnectivityObserver,
    private val memoryRepository: MemoryRepository,
    private val offlineTtsManager: OfflineTtsManager
    // In a real app we'd inject SarvamRepository too
) : ViewModel() {

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    fun sendMessage(userInput: String) {
        viewModelScope.launch {
            _uiState.update { it.copy(isProcessing = true) }
            val isOnline = connectivityObserver.isOnline.first()
            val relevantMemories = memoryRepository.retrieveRelevantMemories(userInput)
            
            if (isOnline) {
                // Mock Sarvam API call using the relevant memories
                val response = "Acha, aapne pehle bataya tha: ${relevantMemories.joinToString(", ")}. ${generateCloudResponse(userInput)}"
                memoryRepository.saveMemory("Dadi said: $userInput") // mock extraction
                
                _uiState.update { it.copy(response = response, source = ResponseSource.CLOUD, isProcessing = false) }
                // Let the UI handle TTS or handle it here
            } else {
                // Fully offline path
                val offlineResponse = generateOfflineResponse(userInput, relevantMemories)
                offlineTtsManager.speak(offlineResponse)
                _uiState.update { it.copy(response = offlineResponse, source = ResponseSource.OFFLINE, isProcessing = false) }
            }
        }
    }

    private fun generateCloudResponse(userInput: String): String {
        return "Haan Dadi, main sun rahi hoon. Aapne kaha: $userInput"
    }

    private fun generateOfflineResponse(userInput: String, memories: List<String>): String {
        return "Abhi network nahi hai Dadi, lekin main yahin hoon. Aap theek hain?"
    }
}
