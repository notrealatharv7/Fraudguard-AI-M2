"""
Fraud Detection API - FastAPI Backend
This API receives transaction data and returns fraud predictions.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import os
import numpy as np
import requests
from typing import Optional

# Initialize FastAPI app
app = FastAPI(
    title="Fraud Detection API",
    description="API for detecting fraudulent transactions using ML",
    version="1.0.0"
)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variable to store the loaded model
model = None
# Model path - works both locally and in Docker
# Try relative path first (for Docker), then parent directory (for local dev)
if os.path.exists("ml/model.pkl"):
    MODEL_PATH = "ml/model.pkl"
else:
    MODEL_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), "ml", "model.pkl")

# Pydantic model for request input
class TransactionInput(BaseModel):
    """Input model for transaction data - must match training features exactly."""
    transactionAmount: float = Field(..., description="Transaction amount")
    transactionAmountDeviation: float = Field(..., description="Amount deviation from normal")
    timeAnomaly: float = Field(..., ge=0, le=1, description="Time anomaly score (0-1)")
    locationDistance: float = Field(..., description="Distance from usual location")
    merchantNovelty: float = Field(..., ge=0, le=1, description="Merchant novelty score (0-1)")
    transactionFrequency: float = Field(..., description="Transaction frequency")
    
    class Config:
        json_schema_extra = {
            "example": {
                "transactionAmount": 150.50,
                "transactionAmountDeviation": 0.25,
                "timeAnomaly": 0.3,
                "locationDistance": 25.0,
                "merchantNovelty": 0.2,
                "transactionFrequency": 5
            }
        }

# Pydantic model for response output
class FraudPrediction(BaseModel):
    """Output model for fraud prediction results."""
    fraud: bool = Field(..., description="True if fraud detected, False if legitimate")
    risk_score: float = Field(..., ge=0, le=1, description="Risk score between 0 and 1")
    explanation: Optional[str] = Field(None, description="AI-generated explanation for the prediction")

def load_model():
    """
    Load the trained ML model from disk.
    This function is called at application startup.
    """
    global model
    try:
        if not os.path.exists(MODEL_PATH):
            raise FileNotFoundError(f"Model file not found at {MODEL_PATH}")
        
        model = joblib.load(MODEL_PATH)
        print(f"[OK] Model loaded successfully from {MODEL_PATH}")
        return model
    except Exception as e:
        print(f"[ERROR] Error loading model: {str(e)}")
        raise

@app.on_event("startup")
async def startup_event():
    """Load the ML model when the API starts."""
    print("Starting Fraud Detection API...")
    try:
        load_model()
        print("API ready to accept requests!")
    except Exception as e:
        print(f"Failed to start API: {e}")
        raise

@app.get("/")
async def root():
    """Root endpoint - API information."""
    return {
        "message": "Fraud Detection API",
        "version": "1.0.0",
        "endpoints": {
            "predict": "/predict",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "model_loaded": model is not None
    }

@app.post("/predict", response_model=FraudPrediction)
async def predict_fraud(transaction: TransactionInput):
    """
    Predict if a transaction is fraudulent.
    
    Accepts transaction data and returns:
    - fraud: boolean (True = Fraud, False = Legit)
    - risk_score: float (0-1, higher = more risky)
    """
    if model is None:
        raise HTTPException(status_code=500, detail="Model not loaded")
    
    try:
        # Prepare features in the exact order used during training
        features = np.array([[
            transaction.transactionAmount,
            transaction.transactionAmountDeviation,
            transaction.timeAnomaly,
            transaction.locationDistance,
            transaction.merchantNovelty,
            transaction.transactionFrequency
        ]])
        
        # Get prediction (0 = Legit, 1 = Fraud)
        prediction = model.predict(features)[0]
        
        # Get probability/confidence score
        # predict_proba returns [prob_class_0, prob_class_1]
        probabilities = model.predict_proba(features)[0]
        fraud_probability = probabilities[1]  # Probability of fraud (class 1)
        
        # Convert to boolean and return
        is_fraud = bool(prediction == 1)
        
        # Get AI explanation
        explanation = get_ai_explanation(transaction, is_fraud, fraud_probability)

        return FraudPrediction(
            fraud=is_fraud,
            risk_score=round(float(fraud_probability), 4),
            explanation=explanation
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Prediction error: {str(e)}"
        )

def get_ai_explanation(transaction: TransactionInput, is_fraud: bool, risk_score: float) -> Optional[str]:
    """Calls the explanation service to get an AI-generated explanation."""
    # The URL for the explanation service, running locally
    url = "http://localhost:8081/explain"
    
    payload = {
        "transactionAmount": transaction.transactionAmount,
        "transactionAmountDeviation": transaction.transactionAmountDeviation,
        "timeAnomaly": transaction.timeAnomaly,
        "locationDistance": transaction.locationDistance,
        "merchantNovelty": transaction.merchantNovelty,
        "transactionFrequency": transaction.transactionFrequency,
        "isFraud": is_fraud,
        "riskScore": risk_score
    }
    
    try:
        response = requests.post(url, json=payload, timeout=10) # 10-second timeout
        response.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)
        return response.json().get("explanation")
    except requests.exceptions.RequestException as e:
        print(f"[ERROR] Could not connect to explanation service: {e}")
        return "AI explanation service is currently unavailable."

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

