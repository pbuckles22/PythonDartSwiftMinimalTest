import json
import sys

def find_5050_situations(probability_map):
    """
    Find 50/50 situations in a probability map.
    
    Args:
        probability_map: Dict with keys like "(row, col)" and values as probabilities
        
    Returns:
        List of [row, col] coordinates that are part of 50/50 situations
    """
    fifty_fifty_cells = []
    
    for key, probability in probability_map.items():
        if probability == 0.5:
            # Parse "(row, col)" format
            clean_key = key.replace("(", "").replace(")", "")
            row_str, col_str = clean_key.split(", ")
            row = int(row_str)
            col = int(col_str)
            fifty_fifty_cells.append([row, col])
    
    return fifty_fifty_cells

if __name__ == "__main__":
    # Read input from stdin (JSON format)
    input_data = sys.stdin.read()
    probability_map = json.loads(input_data)
    
    # Find 50/50 situations
    result = find_5050_situations(probability_map)
    
    # Output result as JSON
    print(json.dumps(result)) 