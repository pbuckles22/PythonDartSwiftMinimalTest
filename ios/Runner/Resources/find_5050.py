#!/usr/bin/env python3
"""
Simplified 50/50 Detection for Minesweeper

Uses simple probability filtering to identify 50/50 situations.
No external dependencies required - uses only Python standard library.
"""

import json
import sys
from typing import List, Dict

def find_5050_situations_simple(probability_map: Dict, sensitivity: float = 0.1) -> List[List[int]]:
    """
    True 50/50 detection that finds actual 50/50 pairs.
    
    Args:
        probability_map: Dictionary with cell probabilities
        sensitivity: Detection sensitivity (0.1 = 40-60%, 0.05 = 45-55%, 0.2 = 30-70%)
        
    Returns:
        List of [row, col] coordinates that are part of true 50/50 situations
    """
    # Calculate the probability range based on sensitivity
    min_probability = 0.5 - sensitivity
    max_probability = 0.5 + sensitivity
    
    # First, find all cells within the probability range
    potential_5050_cells = []
    
    for key, probability in probability_map.items():
        # Check if probability is in the 50/50 range based on sensitivity
        if min_probability <= probability <= max_probability:
            # Parse the cell coordinates
            if isinstance(key, str) and key.startswith("("):
                # Handle "(row, col)" format
                clean_key = key.replace("(", "").replace(")", "")
                row_str, col_str = clean_key.split(", ")
                row = int(row_str)
                col = int(col_str)
                potential_5050_cells.append([row, col])
            elif isinstance(key, (list, tuple)):
                # Handle [row, col] or (row, col) format
                potential_5050_cells.append(list(key))
            else:
                # Handle other formats by converting to list
                potential_5050_cells.append(list(key))
    
    print(f"🎯 Found {len(potential_5050_cells)} cells with {min_probability:.1f}-{max_probability:.1f} probability (sensitivity: {sensitivity}): {potential_5050_cells}", file=sys.stderr)
    
    # Now find true 50/50 pairs (neighboring cells)
    true_5050_cells = []
    used_cells = set()
    
    for i, cell1 in enumerate(potential_5050_cells):
        if tuple(cell1) in used_cells:
            continue
            
        for j, cell2 in enumerate(potential_5050_cells):
            if i == j or tuple(cell2) in used_cells:
                continue
                
            # Check if cells are side-adjacent (not corner-adjacent)
            row_diff = abs(cell1[0] - cell2[0])
            col_diff = abs(cell1[1] - cell2[1])
            
            # Valid 50/50: cells must be side-adjacent (not corner-adjacent)
            # This means either same row and adjacent columns, or same column and adjacent rows
            if ((row_diff == 0 and col_diff == 1) or (row_diff == 1 and col_diff == 0)):
                # These are side-adjacent cells within the probability range - valid 50/50!
                print(f"🎯 VALID 50/50 PAIR: {cell1} and {cell2} are side-adjacent with {probability_map.get(str(cell1), 'unknown')} and {probability_map.get(str(cell2), 'unknown')} probability (range: {min_probability:.1f}-{max_probability:.1f})", file=sys.stderr)
                true_5050_cells.extend([cell1, cell2])
                used_cells.add(tuple(cell1))
                used_cells.add(tuple(cell2))
                break
    
    print(f"🎯 50/50 detection found {len(true_5050_cells)} cells in {len(true_5050_cells)//2} pairs", file=sys.stderr)
    return true_5050_cells

def test_import():
    """
    Simple test function to verify module import works.
    """
    print("✅ find_5050 module imported successfully", file=sys.stderr)
    return "Module import test successful"

def find_5050_situations(probability_map, sensitivity=0.1):
    """
    Main function to find 50/50 situations.
    
    Args:
        probability_map: Dict with keys like "(row, col)" and values as probabilities
        sensitivity: Detection sensitivity (0.1 = 40-60%, 0.05 = 45-55%, 0.2 = 30-70%)
        
    Returns:
        List of [row, col] coordinates that are part of 50/50 situations
    """
    print(f"🔍 Starting 50/50 detection with {len(probability_map)} cells, sensitivity: {sensitivity}", file=sys.stderr)
    print(f"🔍 Input probability_map: {probability_map}", file=sys.stderr)
    print(f"🔍 Input type: {type(probability_map)}", file=sys.stderr)
    
    # Use simple detection (no sophisticated solver needed)
    result = find_5050_situations_simple(probability_map, sensitivity)
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