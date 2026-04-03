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

# Call this in your main block
# save_coe_file(df_processed)