package com.example.snehsaathi.features.scamshield

object ScamDetector {
    // Priority 1: Hard block keywords (always trigger warning)
    private val hardBlockKeywords = setOf(
        "otp", "o.t.p", "one time password",
        "cvv", "pin number", "atm pin",
        "lottery", "jackpot", "prize money",
        "account blocked", "kyc pending",
        "refund pending", "emi bounce"
    )

    // Priority 2: Soft risk phrases (score-based)
    private val riskPhrases = mapOf(
        "bank" to 10,
        "paytm" to 10,
        "upi" to 15,
        "transfer money" to 20,
        "send money" to 20,
        "click the link" to 25,
        "verify your" to 20,
        "government scheme" to 15,
        "free" to 5,
        "urgent" to 10,
        "immediately" to 10
    )

    data class ScamResult(
        val isScam: Boolean,
        val confidence: Float,   // 0.0 to 1.0
        val triggerReason: String
    )

    fun analyze(text: String): ScamResult {
        val lower = text.lowercase()
        
        // Hard block check
        hardBlockKeywords.forEach { keyword ->
            if (lower.contains(keyword)) {
                return ScamResult(true, 1.0f, "Keyword: \$keyword")
            }
        }
        
        // Soft score check
        val score = riskPhrases.entries.sumOf { (phrase, weight) ->
            if (lower.contains(phrase)) weight else 0
        }
        
        return when {
            score >= 40 -> ScamResult(true, score / 100f, "High risk score: \$score")
            score >= 20 -> ScamResult(false, score / 100f, "Medium risk: \$score")  // warn but don't block
            else -> ScamResult(false, 0f, "Safe")
        }
    }
}
