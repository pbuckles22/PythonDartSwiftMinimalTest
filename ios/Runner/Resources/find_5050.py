#!/usr/bin/env python3
"""
Simplified 50/50 Detection for Minesweeper

Uses simple probability filtering to identify 50/50 situations.
No external dependencies required - uses only Python standard library.
"""

import json
import sys
from typing import List, Dict

def find_5050_situations_simple(probability_map: Dict) -> List[List[int]]:
    """
    Simple 50/50 detection that filters the probability map.
    
    Args:
        probability_map: Dictionary with cell probabilities
        
    Returns:
        List of [row, col] coordinates that have 0.5 probability
    """
    fifty_fifty_cells = []
    
    for key, probability in probability_map.items():
        # Check if probability is very close to 0.5 (allowing for floating point precision)
        if abs(probability - 0.5) < 1e-6:
            # Parse the cell coordinates
            if isinstance(key, str) and key.startswith("("):
                # Handle "(row, col)" format
                clean_key = key.replace("(", "").replace(")", "")
                row_str, col_str = clean_key.split(", ")
                row = int(row_str)
                col = int(col_str)
                fifty_fifty_cells.append([row, col])
            elif isinstance(key, (list, tuple)):
                # Handle [row, col] or (row, col) format
                fifty_fifty_cells.append(list(key))
            else:
                # Handle other formats by converting to list
                fifty_fifty_cells.append(list(key))
    
    print(f"🎯 Simple detection found {len(fifty_fifty_cells)} 50/50 cells", file=sys.stderr)
    return fifty_fifty_cells

def test_import():
    """
    Simple test function to verify module import works.
    """
    print("✅ find_5050 module imported successfully", file=sys.stderr)
    return "Module import test successful"

def find_5050_situations(probability_map):
    """
    Main function to find 50/50 situations.
    
    Args:
        probability_map: Dict with keys like "(row, col)" and values as probabilities
        
    Returns:
        List of [row, col] coordinates that are part of 50/50 situations
    """
    print(f"🔍 Starting 50/50 detection with {len(probability_map)} cells", file=sys.stderr)
    print(f"🔍 Input probability_map: {probability_map}", file=sys.stderr)
    print(f"🔍 Input type: {type(probability_map)}", file=sys.stderr)
    
    # Use simple detection (no sophisticated solver needed)
    result = find_5050_situations_simple(probability_map)
    print(f"🔍 Returning result: {result}", file=sys.stderr)
    return result

if __name__ == "__main__":
    print("🐍 find_5050.py main script starting...", file=sys.stderr)
    print(f"🐍 Python version: {sys.version}", file=sys.stderr)
    
    # Read input from stdin (JSON format)
    input_data = sys.stdin.read()
    print(f"🐍 Received stdin data: {input_data}", file=sys.stderr)
    
    try:
        probability_map = json.loads(input_data)
        print(f"🐍 Parsed probability_map: {probability_map}", file=sys.stderr)
    except Exception as e:
        print(f"🐍 Error parsing JSON: {e}", file=sys.stderr)
        print("[]")
        sys.exit(1)
    
    # Find 50/50 situations
    result = find_5050_situations(probability_map)
    
    # Output result as JSON
    print(f"🐍 Final result: {result}", file=sys.stderr)
    print(json.dumps(result))
    print("🐍 find_5050.py main script finished", file=sys.stderr) 