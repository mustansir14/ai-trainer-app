from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np

# Load the model
model = joblib.load('exercise_classifier.pkl')

app = FastAPI()

# Define the request model


class ExerciseData(BaseModel):
    shoulder_angle: float
    elbow_angle: float
    hip_angle: float
    knee_angle: float
    ankle_angle: float
    shoulder_ground_angle: float
    elbow_ground_angle: float
    hip_ground_angle: float
    knee_ground_angle: float
    ankle_ground_angle: float


# Example mapping, update it based on your actual labels
label_mapping = {
    0: "Jumping Jacks",
    1: "No exercise",
    2: "Pull Ups",
    3: "Push Ups",
    4: "Russian Twists",
    5: "Squats",
    # Add more mappings as needed
}


@app.post("/predict/")
async def predict(data: ExerciseData):
    # Convert input data to a format suitable for the model
    input_data = np.array([
        data.shoulder_angle,
        data.elbow_angle,
        data.hip_angle,
        data.knee_angle,
        data.ankle_angle,
        data.shoulder_ground_angle,
        data.elbow_ground_angle,
        data.hip_ground_angle,
        data.knee_ground_angle,
        data.ankle_ground_angle,
    ]).reshape(1, -1)  # Reshape for a single sample

    # Make prediction
    prediction = model.predict(input_data)

    predicted_label = label_mapping.get(int(prediction[0]), "Unknown")

    return {"prediction": predicted_label}
