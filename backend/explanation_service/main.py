from fastapi import FastAPI
from pydantic import BaseModel
from transformers import pipeline

app = FastAPI(
    title="Explanation AI Service",
    description="Generates explanations for fraud predictions.",
    version="1.0.0"
)

# Load the Hugging Face model on startup
# This can take a moment, but it's only done once.
explainer = pipeline("text-generation", model="distilgpt2")

class PredictionDetails(BaseModel):
    transactionAmount: float
    transactionAmountDeviation: float
    timeAnomaly: float
    locationDistance: float
    merchantNovelty: float
    transactionFrequency: float
    isFraud: bool
    riskScore: float

class ExplanationResponse(BaseModel):
    explanation: str

@app.post("/explain", response_model=ExplanationResponse)
async def get_explanation(details: PredictionDetails):
    """Generates a human-readable explanation for a fraud prediction."""
    prompt = create_prompt(details)
    
    try:
        result = explainer(
            prompt,
            max_length=100,
            num_return_sequences=1,
            pad_token_id=explainer.tokenizer.eos_token_id
        )
        explanation = result[0]['generated_text'].replace(prompt, "").strip()
        return ExplanationResponse(explanation=explanation)
    except Exception as e:
        return ExplanationResponse(explanation=f"Could not generate explanation: {e}")

def create_prompt(details: PredictionDetails) -> str:
    """Creates a structured, few-shot prompt for the LLM to generate a high-quality explanation."""
    status = "fraudulent" if details.isFraud else "legitimate"

    # Few-shot examples to guide the model
    examples = """
**Example 1 (Fraudulent):**
- **Data:** High amount, high location distance, new merchant.
- **Explanation:** This transaction is considered high-risk because it involves a large amount at a location far from the user's typical area and with a merchant they have not used before.

**Example 2 (Legitimate):**
- **Data:** Normal amount, low location distance, frequent merchant.
- **Explanation:** This transaction appears to be safe. The amount is consistent with the user's spending habits, it occurred at a familiar location, and it's with a frequently used merchant.
"""

    # The actual prompt for the current transaction
    current_transaction_prompt = f"""
**Current Transaction:**
- **Status:** {status}
- **Risk Score:** {details.riskScore*100:.0f}%
- **Key Factors:** Amount deviation is {details.transactionAmountDeviation:.2f}, time anomaly is {details.timeAnomaly:.2f}, location distance is {details.locationDistance:.1f}km, merchant novelty is {details.merchantNovelty:.2f}, and transaction frequency is {details.transactionFrequency:.1f}.
- **Explanation:**"""

    # Combine the role, examples, and current transaction into a single prompt
    full_prompt = f"You are a fraud analyst. Your task is to provide a brief, professional explanation for a transaction's fraud status based on the provided data.\n\n{examples}\n\n{current_transaction_prompt}"
    
    return full_prompt

@app.get("/health")
async def health_check():
    return {"status": "ok"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8081)
