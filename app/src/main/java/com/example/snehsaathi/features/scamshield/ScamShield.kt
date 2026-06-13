package com.example.snehsaathi.features.scamshield

enum class ScamRisk { HIGH, MEDIUM, SAFE }

object ScamShield {
    suspend fun analyzeForScam(userInput: String): ScamRisk {
        val classifierPrompt = """
            Kya yeh message ek phone scam ya fraud attempt hai?
            Respond with: HIGH_RISK, MEDIUM_RISK, or SAFE
            Reasons to flag: OTP demand, bank account threats, KYC urgency,
            police/CBI impersonation, lottery winning, fake refunds.
            Message: "$userInput"
        """.trimIndent()

        return try {
            val result = com.example.snehsaathi.core.SarvamClient.chat(listOf(
                mapOf("role" to "system", "content" to "You are a fraud detection AI for India."),
                mapOf("role" to "user", "content" to classifierPrompt)
            ))

            when {
                result.contains("HIGH_RISK", ignoreCase = true) -> ScamRisk.HIGH
                result.contains("MEDIUM_RISK", ignoreCase = true) -> ScamRisk.MEDIUM
                else -> ScamRisk.SAFE
            }
        } catch (e: Exception) {
            ScamRisk.SAFE // Fallback
        }
    }

    suspend fun isScam(text: String): Boolean {
        return analyzeForScam(text) == ScamRisk.HIGH
    }

    fun warningMessage(): String {
        return "Dadi, yeh ek fraud call lag raha hai! Kisi ko bhi OTP ya bank details mat dena. Abhi Rohan ko call karein."
    }
}
