import pandas as pd
import numpy as np

# Define the number of samples
num_samples = 6000

# Generate random data for angles
data = {
    'Side': 'left',
    # Standing position
    'Shoulder_Angle': np.random.uniform(80, 100, size=num_samples),
    # Relaxed arms
    'Elbow_Angle': np.random.uniform(170, 180, size=num_samples),
    # Neutral position
    'Hip_Angle': np.random.uniform(170, 180, size=num_samples),
    # Standing
    'Knee_Angle': np.random.uniform(170, 180, size=num_samples),
    # Slightly bent
    'Ankle_Angle': np.random.uniform(85, 95, size=num_samples),
    'Shoulder_Ground_Angle': np.full(num_samples, 90.0),
    'Elbow_Ground_Angle': np.full(num_samples, 90.0),
    'Hip_Ground_Angle': np.full(num_samples, 90.0),
    'Knee_Ground_Angle': np.full(num_samples, 90.0),
    'Ankle_Ground_Angle': np.full(num_samples, 90.0),
    'Label': np.full(num_samples, 'No Exercise')
}

# Create a DataFrame
df_no_exercise = pd.DataFrame(data)

# Save to CSV
df_no_exercise.to_csv('no_exercise_data.csv', index=False)

print("Generated No Exercise data and saved to no_exercise_data.csv")
