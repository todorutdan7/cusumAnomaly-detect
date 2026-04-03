import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

file = '04-12-22_temperature_measurements.csv'

def process_csv(filename):
    data_frame = pd.read_csv(filename)
    data_frame.columns = data_frame.columns.str.strip()
    sensor_data = data_frame.drop(columns=['Timestamp'])
    sensor_data_integer = (sensor_data * 100).round().astype(int)
    return sensor_data_integer

def cusum(data, threshold=200, drift=50):
    x = data.values
    n = len(x)
    g_plus = np.zeros(n)
    g_minus = np.zeros(n)
    anomalies = np.zeros(n) # 0 normal, 1 anomaly
    
    for t in range (1,n):
        s_t = x[t] - x[t - 1]
        
        g_plus[t] = max(g_plus[t-1] + s_t - drift, 0)
        g_minus[t] = max(g_minus[t-1] - s_t - drift, 0)
        
        if g_plus[t] > threshold or g_minus[t] > threshold:
            anomalies[t] = 1
            g_plus[t] = 0
            g_minus[t] = 0       

    return anomalies

def run_exercise_2(df_int):
    THRESHOLD = 200
    DRIFT = 50

    for col in df_int.columns:
        series = df_int[col]
        labels = cusum(series, THRESHOLD, DRIFT)
        
        plt.figure(figsize=(10, 4))
        plt.plot(series.index, series.values, label='Temperature (Int)', color='blue', alpha=0.6)
        
        anomaly_indices = np.where(labels == 1)[0]
        if len(anomaly_indices) > 0:
            plt.scatter(anomaly_indices, series.iloc[anomaly_indices], color='red', label='Anomaly', zorder=5)
            
        plt.title(f"CUSUM Anomaly Detection: {col}")
        plt.xlabel("Sample Index")
        plt.ylabel("Temperature (x100)")
        plt.legend()
        plt.grid(True, alpha=0.3)
        plt.show()

def int_to_binary_string(val, bits=32):
    return f'{val & (2**bits - 1):0{bits}b}'

def save_binary_files(df_int):
    
    for col in df_int.columns:
        filename = f"{col}_bin.mem" 
        
        with open(filename, 'w') as f:
            f.write("index,binary_val\n")
            for i, val in enumerate(df_int[col]):
                f.write(f"{i},{int_to_binary_string(val)}\n")
                
        print(f"Generated VHDL input file: {filename}")


def save_processed_single_file(original_filename, df_int):
    df_orig = pd.read_csv(original_filename)
    df_orig.columns = df_orig.columns.str.strip()
    df_final = pd.concat([df_orig['Timestamp'], df_int], axis=1)
    output_filename = "multiplied.csv"
    df_final.to_csv(output_filename, index=False)

def validate_hardware_results(df_int, vhdl_csv_filename, column_name='LM35DZ'):
    print(f"\n--- Validating Hardware Output for {column_name} ---")
    
    series = df_int[column_name]
    python_labels = cusum(series, threshold=200, drift=50) 
    
    if not os.path.exists(vhdl_csv_filename):
        print(f"Error: VHDL output file {vhdl_csv_filename} not found.")
        return

    vhdl_df = pd.read_csv(vhdl_csv_filename)
    vhdl_df.columns = vhdl_df.columns.str.strip() 
    
    total_samples = len(vhdl_df)
    mismatches = 0
    
    for index, row in vhdl_df.iterrows():
        hw_idx = int(row['index'])
        hw_label = int(row['label'])
        
        py_idx = hw_idx + 1
        if py_idx >= len(python_labels):
            break
            
        py_label = int(python_labels[py_idx])
        
        if hw_label != py_label:
            print(f"MISMATCH at HW Index {hw_idx} (Py Index {py_idx}): HW={hw_label} vs Py={py_label}")
            mismatches += 1
            
    if mismatches == 0:
        print("SUCCESS: Hardware implementation matches Software exactly!")
        
        anomalies = vhdl_df[vhdl_df['label'] == 1]['index'].tolist()
        print(f"Hardware detected {len(anomalies)} anomalies at indices: {anomalies}")
        print(f"(Equivalent to Python indices: {[x+1 for x in anomalies]})")
    else:
        print(f"FAILURE: Found {mismatches} mismatches.")


def save_coe_file(df_int, output_file="sensor_data.coe"):
    print(f"Generating COE file for Xilinx Block RAM...")
    
    column_name = 'LM35DZ' 
    data = df_int[column_name].tolist()
    
    try:
        with open(output_file, 'w') as f:
            f.write("memory_initialization_radix=10;\n")
            f.write("memory_initialization_vector=\n")
            
            for i, val in enumerate(data):
                if i == len(data) - 1:
                    f.write(f"{val};\n") 
                else:
                    f.write(f"{val},\n")
                    
        print(f"Success! Load '{output_file}' into Vivado Block Memory Generator.")
        
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    if os.path.exists(file):
        print(f"Processing {file}...")
        df_processed = process_csv(file)
        
        if df_processed is not None:
            save_binary_files(df_processed)
        
            validate_hardware_results(df_processed, 'LM35DZ.csv')
            save_coe_file(df_processed)
            # save_processed_single_file(file, df_processed)
            print("Processing complete.")


    else:
        print(f"Error: File {file} not found in current directory.")