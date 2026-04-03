import pandas as pd
import numpy as np
import os

INPUT_FILENAME = '04-12-22_temperature_measurements.csv'
OUTPUT_FILENAME = 'Thermistor_expected.csv'
SENSOR_NAME = 'Thermistor'  

THRESHOLD = 200
DRIFT = 50

def process_csv(filename):
    if not os.path.exists(filename):
        print(f"Error: {filename} not found.")
        return None
    data_frame = pd.read_csv(filename)
    data_frame.columns = data_frame.columns.str.strip()
    sensor_data = data_frame.drop(columns=['Timestamp'])
    sensor_data_integer = (sensor_data * 100).round().astype(int)
    return sensor_data_integer

def cusum(data, threshold, drift):
    x = data.values
    n = len(x)
    g_plus = np.zeros(n)
    g_minus = np.zeros(n)
    anomalies = np.zeros(n) 
    
    for t in range(1, n):
        s_t = x[t] - x[t - 1]
        
        g_plus[t] = max(g_plus[t-1] + s_t - drift, 0)
        g_minus[t] = max(g_minus[t-1] - s_t - drift, 0)
        
        if g_plus[t] > threshold or g_minus[t] > threshold:
            anomalies[t] = 1
            g_plus[t] = 0
            g_minus[t] = 0       

    return anomalies

def save_vhdl_style_file(df_int, output_file):
    print(f"Processing sensor: {SENSOR_NAME}")
    
    series = df_int[SENSOR_NAME]
    labels = cusum(series, THRESHOLD, DRIFT)
    
    try:
        with open(output_file, 'w') as f:
            f.write("index, label\n")
            
            for t in range(1, len(labels)):
                hw_index = t - 1
                label_val = int(labels[t])
                f.write(f"{hw_index}, {label_val}\n")
                
        print(f"Successfully saved expected results to: {output_file}")
        
    except IOError as e:
        print(f"Error writing to file: {e}")

def save_coe_file(df_int, output_file="sensor_data.coe"):
    print(f"Generating COE file for Xilinx Block RAM...")
    
    # We use the 'Thermistor' column or whichever you chose
    # Assuming df_int has the integer values
    column_name = 'Thermistor' 
    data = df_int[column_name].tolist()
    
    try:
        with open(output_file, 'w') as f:
            # Standard Xilinx COE Header
            f.write("memory_initialization_radix=10;\n")
            f.write("memory_initialization_vector=\n")
            
            # Write data comma separated
            for i, val in enumerate(data):
                if i == len(data) - 1:
                    f.write(f"{val};\n") # End with semicolon
                else:
                    f.write(f"{val},\n")
                    
        print(f"Success! Load '{output_file}' into Vivado Block Memory Generator.")
        
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    df = process_csv(INPUT_FILENAME)
    if df is not None:
        save_vhdl_style_file(df, OUTPUT_FILENAME)