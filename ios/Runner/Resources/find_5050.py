#!/usr/bin/env python3
"""
Sophisticated 50/50 Detection for Minesweeper

Uses CSP (Constraint Satisfaction Problem) and probabilistic analysis
to identify true 50/50 situations in Minesweeper.
"""

import json
import sys
import os
from typing import List, Dict, Tuple, Optional

# Add the current directory to Python path to import our modules
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

def check_dependencies():
    """Check if required dependencies are available."""
    try:
        import numpy as np
        print("✅ NumPy is available", file=sys.stderr)
        return True
    except ImportError as e:
        print(f"❌ NumPy not available: {e}", file=sys.stderr)
        return False

def import_sophisticated_solver():
    """Import the sophisticated solver modules."""
    try:
        from core.csp_agent import CSPAgent
        from core.probabilistic_guesser import ProbabilisticGuesser
        from core.advanced_csp_solver import AdvancedMinesweeperCSP
        print("✅ Sophisticated solver modules imported successfully", file=sys.stderr)
        return True
    except ImportError as e:
        print(f"❌ Failed to import sophisticated solver: {e}", file=sys.stderr)
        return False

def create_board_state_from_probability_map(probability_map: Dict) -> Tuple[Optional[List], int, int, int]:
    """
    Create a simplified board state from the probability map.
    
    Args:
        probability_map: Dictionary with cell probabilities
        
    Returns:
        Tuple of (board_state, board_height, board_width, mine_count)
    """
    # Extract all cell positions to determine board size
    all_cells = set()
    for key in probability_map.keys():
        if isinstance(key, str) and key.startswith("("):
            clean_key = key.replace("(", "").replace(")", "")
            row_str, col_str = clean_key.split(", ")
            row = int(row_str)
            col = int(col_str)
            all_cells.add((row, col))
        else:
            all_cells.add(tuple(key))
    
    if not all_cells:
        # Fallback: assume 16x30 board (Hard difficulty)
        return None, 16, 30, 99
    
    # Determine board dimensions
    max_row = max(cell[0] for cell in all_cells)
    max_col = max(cell[1] for cell in all_cells)
    board_height = max_row + 1
    board_width = max_col + 1
    
    # Estimate mine count based on board size
    if board_height == 16 and board_width == 30:  # Hard difficulty
        mine_count = 99
    elif board_height == 16 and board_width == 16:  # Normal difficulty
        mine_count = 40
    elif board_height == 9 and board_width == 9:  # Easy difficulty
        mine_count = 10
    else:
        # Estimate based on board size (typical mine density)
        total_cells = board_height * board_width
        mine_count = int(total_cells * 0.2)  # 20% mine density
    
    # Create a simplified board state
    # In a real implementation, you'd get the actual board state from Flutter
    board_state = []
    for row in range(board_height):
        board_row = []
        for col in range(board_width):
            cell_key = f"({row}, {col})"
            if cell_key in probability_map:
                # This is an unrevealed cell with a probability
                board_row.append(-1)  # -1 represents unrevealed
            else:
                # This cell is either revealed or not in the probability map
                board_row.append(0)  # Assume revealed with no adjacent mines
        board_state.append(board_row)
    
    return board_state, board_height, board_width, mine_count

def find_5050_situations_sophisticated(probability_map: Dict) -> List[List[int]]:
    """
    Find true 50/50 situations using sophisticated CSP and probabilistic analysis.
    
    Args:
        probability_map: Dictionary with cell probabilities (from Flutter)
        
    Returns:
        List of [row, col] coordinates that are true 50/50 situations
    """
    try:
        # Check dependencies
        if not check_dependencies():
            print("⚠️ Falling back to simple detection due to missing dependencies", file=sys.stderr)
            return find_5050_situations_simple(probability_map)
        
        # Import sophisticated solver
        if not import_sophisticated_solver():
            print("⚠️ Falling back to simple detection due to import errors", file=sys.stderr)
            return find_5050_situations_simple(probability_map)
        
        from core.csp_agent import CSPAgent
        import numpy as np
        
        # Create board state from probability map
        board_state, board_height, board_width, mine_count = create_board_state_from_probability_map(probability_map)
        
        if board_state is None:
            print("⚠️ Could not create board state, falling back to simple detection", file=sys.stderr)
            return find_5050_situations_simple(probability_map)
        
        print(f"🔍 Using sophisticated solver: {board_height}x{board_width} board, {mine_count} mines", file=sys.stderr)
        
        # Initialize the sophisticated CSP agent
        agent = CSPAgent((board_height, board_width), mine_count)
        
        # Convert board state to numpy array (simplified 4-channel representation)
        # In reality, you'd get the proper 4-channel board state from Flutter
        np_board_state = np.zeros((board_height, board_width, 4), dtype=np.float32)
        
        # Set revealed cells (simplified - in reality you'd get this from Flutter)
        revealed_cells = set()
        flagged_cells = set()
        
        for row in range(board_height):
            for col in range(board_width):
                cell_key = f"({row}, {col})"
                if cell_key not in probability_map:
                    # This cell is revealed
                    revealed_cells.add((row, col))
                    # Set the revealed number (simplified)
                    np_board_state[row, col, 0] = 0  # Assume no adjacent mines
        
        # Update agent with current board state
        agent.update_state(np_board_state, revealed_cells, flagged_cells)
        
        # Get all unrevealed cells from probability map
        unrevealed_cells = []
        for key in probability_map.keys():
            if isinstance(key, str) and key.startswith("("):
                clean_key = key.replace("(", "").replace(")", "")
                row_str, col_str = clean_key.split(", ")
                row = int(row_str)
                col = int(col_str)
                unrevealed_cells.append((row, col))
            else:
                unrevealed_cells.append(tuple(key))
        
        # Calculate probabilities for all unrevealed cells using the sophisticated algorithm
        fifty_fifty_cells = []
        
        for cell in unrevealed_cells:
            try:
                # Get detailed probability information for this cell
                prob_info = agent.get_probability_info(cell)
                combined_probability = prob_info.get('combined_probability', 1.0)
                
                print(f"🔍 Cell {cell}: probability {combined_probability:.3f}", file=sys.stderr)
                
                # Check if this is a true 50/50 situation (probability very close to 0.5)
                if abs(combined_probability - 0.5) < 1e-6:
                    fifty_fifty_cells.append([cell[0], cell[1]])
                    print(f"✅ Found 50/50 cell: {cell}", file=sys.stderr)
                    
            except Exception as e:
                print(f"⚠️ Error analyzing cell {cell}: {e}", file=sys.stderr)
                continue
        
        print(f"🎯 Sophisticated detection found {len(fifty_fifty_cells)} 50/50 cells", file=sys.stderr)
        return fifty_fifty_cells
        
    except Exception as e:
        print(f"❌ Error in sophisticated 50/50 detection: {e}", file=sys.stderr)
        # Fallback to simple probability map filtering
        return find_5050_situations_simple(probability_map)

def find_5050_situations_simple(probability_map: Dict) -> List[List[int]]:
    """
    Simple fallback 50/50 detection that filters the probability map.
    
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

def find_5050_situations(probability_map):
    """
    Main function to find 50/50 situations.
    
    Args:
        probability_map: Dict with keys like "(row, col)" and values as probabilities
        
    Returns:
        List of [row, col] coordinates that are part of 50/50 situations
    """
    print(f"🔍 Starting 50/50 detection with {len(probability_map)} cells", file=sys.stderr)
    
    # Try sophisticated detection first
    try:
        return find_5050_situations_sophisticated(probability_map)
    except Exception as e:
        print(f"❌ Sophisticated detection failed: {e}", file=sys.stderr)
        # Fallback to simple detection
        return find_5050_situations_simple(probability_map)

if __name__ == "__main__":
    # Read input from stdin (JSON format)
    input_data = sys.stdin.read()
    probability_map = json.loads(input_data)
    
    # Find 50/50 situations
    result = find_5050_situations(probability_map)
    
    # Output result as JSON
    print(json.dumps(result)) 