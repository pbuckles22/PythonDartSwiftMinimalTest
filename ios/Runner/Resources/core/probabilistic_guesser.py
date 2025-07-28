#!/usr/bin/env python3
"""
Advanced Probabilistic Guessing for Minesweeper

Enhanced probability-based guessing with pattern recognition,
advanced mine probability estimation, and risk assessment.
"""

import numpy as np
from typing import List, Tuple, Dict, Optional, Set
from collections import defaultdict
import logging

# Configure logging
logging.basicConfig(level=logging.WARNING)  # Reduced from INFO to WARNING
logger = logging.getLogger(__name__)


class ProbabilisticGuesser:
    """
    Advanced probability-based guessing for Minesweeper.
    
    Features:
    - Pattern recognition for common configurations
    - Advanced mine probability estimation
    - Risk assessment and safety evaluation
    - Multi-factor probability models
    """
    
    def __init__(self, board_size: Tuple[int, int], mine_count: int):
        """
        Initialize the advanced probabilistic guesser.
        
        Args:
            board_size: (height, width) of the board
            mine_count: Total number of mines on the board
        """
        self.board_height, self.board_width = board_size
        self.mine_count = mine_count
        self.total_cells = self.board_height * self.board_width
        
        # Enhanced probability model weights
        self.weights = {
            'global_density': 0.25,
            'local_density': 0.30,
            'pattern_recognition': 0.20,
            'edge_factor': 0.10,
            'corner_factor': 0.05,
            'isolation_factor': 0.10
        }
        
        # Cache for calculations
        self.adjacency_cache = {}
        self.pattern_cache = {}
        
        # Pattern recognition database
        self._initialize_patterns()
    
    def _initialize_patterns(self):
        """Initialize common Minesweeper patterns."""
        self.patterns = {
            '1-1': {'cells': 2, 'mines': 1, 'safety_factor': 0.8},
            '1-2-1': {'cells': 3, 'mines': 2, 'safety_factor': 0.6},
            '2-2': {'cells': 2, 'mines': 2, 'safety_factor': 0.2},
            '1-2-2-1': {'cells': 4, 'mines': 3, 'safety_factor': 0.4},
            'isolated': {'cells': 1, 'mines': 0, 'safety_factor': 0.9}
        }
    
    def _get_neighbors(self, row: int, col: int) -> List[Tuple[int, int]]:
        """Get valid neighboring cells."""
        if (row, col) in self.adjacency_cache:
            return self.adjacency_cache[(row, col)]
        
        neighbors = []
        for di in [-1, 0, 1]:
            for dj in [-1, 0, 1]:
                if di == 0 and dj == 0:
                    continue
                ni, nj = row + di, col + dj
                if (0 <= ni < self.board_height and 
                    0 <= nj < self.board_width):
                    neighbors.append((ni, nj))
        
        self.adjacency_cache[(row, col)] = neighbors
        return neighbors
    
    def _get_revealed_neighbors(self, row: int, col: int, revealed_cells: Set[Tuple[int, int]]) -> List[Tuple[int, int]]:
        """Get revealed neighboring cells."""
        neighbors = self._get_neighbors(row, col)
        return [n for n in neighbors if n in revealed_cells]
    
    def _get_unrevealed_neighbors(self, row: int, col: int, revealed_cells: Set[Tuple[int, int]]) -> List[Tuple[int, int]]:
        """Get unrevealed neighboring cells."""
        neighbors = self._get_neighbors(row, col)
        return [n for n in neighbors if n not in revealed_cells]
    
    def calculate_global_density_probability(self, unrevealed_cells: List[Tuple[int, int]], 
                                           remaining_mines: int) -> Dict[Tuple[int, int], float]:
        """
        Calculate mine probability based on global mine density with refinement.
        """
        if not unrevealed_cells:
            return {}
        
        # Base uniform probability
        base_probability = remaining_mines / len(unrevealed_cells)
        
        # Refine based on board position
        probabilities = {}
        for cell in unrevealed_cells:
            row, col = cell
            
            # Center cells tend to be safer in Minesweeper
            center_row = self.board_height // 2
            center_col = self.board_width // 2
            distance_from_center = abs(row - center_row) + abs(col - center_col)
            max_distance = center_row + center_col
            
            # Center bias: cells closer to center are slightly safer
            center_factor = 1.0 - (0.1 * distance_from_center / max_distance)
            
            probabilities[cell] = base_probability * center_factor
        
        logger.debug(f"Global density probability: {base_probability:.3f}")
        return probabilities
    
    def calculate_local_density_probability(self, unrevealed_cells: List[Tuple[int, int]], 
                                          revealed_cells: Set[Tuple[int, int]], 
                                          board_state: np.ndarray) -> Dict[Tuple[int, int], float]:
        """
        Calculate mine probability based on local mine density from revealed numbers.
        """
        probabilities = {}
        
        for cell in unrevealed_cells:
            row, col = cell
            revealed_neighbors = self._get_revealed_neighbors(row, col, revealed_cells)
            
            if not revealed_neighbors:
                # No revealed neighbors, use neutral probability
                probabilities[cell] = 1.0
                continue
            
            # Calculate weighted average of local mine densities
            total_weight = 0
            weighted_sum = 0
            
            for neighbor in revealed_neighbors:
                ni, nj = neighbor
                number = board_state[0, ni, nj]
                
                if number >= 0:  # Valid number (not a mine)
                    # Count unrevealed neighbors of this revealed cell
                    neighbor_unrevealed = self._get_unrevealed_neighbors(ni, nj, revealed_cells)
                    
                    if neighbor_unrevealed:
                        # Calculate local mine density
                        local_mine_density = number / len(neighbor_unrevealed)
                        
                        # Weight by distance (closer neighbors have more influence)
                        distance = abs(row - ni) + abs(col - nj)
                        weight = 1.0 / (distance + 1)
                        
                        weighted_sum += local_mine_density * weight
                        total_weight += weight
            
            if total_weight > 0:
                avg_local_density = weighted_sum / total_weight
                # Convert to probability factor
                local_factor = 0.3 + (0.7 * avg_local_density)
            else:
                local_factor = 1.0
            
            probabilities[cell] = local_factor
        
        logger.debug(f"Local density probability calculated for {len(unrevealed_cells)} cells")
        return probabilities
    
    def calculate_pattern_probability(self, unrevealed_cells: List[Tuple[int, int]], 
                                    revealed_cells: Set[Tuple[int, int]], 
                                    board_state: np.ndarray) -> Dict[Tuple[int, int], float]:
        """
        Calculate mine probability based on pattern recognition.
        """
        probabilities = {}
        
        for cell in unrevealed_cells:
            row, col = cell
            pattern_factor = 1.0
            
            # Check for common patterns around this cell
            revealed_neighbors = self._get_revealed_neighbors(row, col, revealed_cells)
            
            for neighbor in revealed_neighbors:
                ni, nj = neighbor
                number = board_state[0, ni, nj]
                
                if number >= 0:
                    # Get unrevealed neighbors of this revealed cell
                    neighbor_unrevealed = self._get_unrevealed_neighbors(ni, nj, revealed_cells)
                    
                    if len(neighbor_unrevealed) == 2 and number == 1:
                        # 1-1 pattern: one of two cells is a mine
                        if cell in neighbor_unrevealed:
                            pattern_factor *= 0.8  # Slightly safer
                    
                    elif len(neighbor_unrevealed) == 2 and number == 2:
                        # 2-2 pattern: both cells are mines
                        if cell in neighbor_unrevealed:
                            pattern_factor *= 1.5  # More dangerous
                    
                    elif len(neighbor_unrevealed) == 3 and number == 2:
                        # 1-2-1 pattern: two of three cells are mines
                        if cell in neighbor_unrevealed:
                            pattern_factor *= 1.2  # More dangerous
            
            probabilities[cell] = pattern_factor
        
        logger.debug(f"Pattern probability calculated for {len(unrevealed_cells)} cells")
        return probabilities
    
    def calculate_edge_probability(self, unrevealed_cells: List[Tuple[int, int]]) -> Dict[Tuple[int, int], float]:
        """
        Calculate mine probability based on edge proximity with refinement.
        """
        probabilities = {}
        
        for cell in unrevealed_cells:
            row, col = cell
            
            # Calculate distance to nearest edge
            dist_to_edge = min(row, col, 
                              self.board_height - 1 - row, 
                              self.board_width - 1 - col)
            
            # Enhanced edge factor: edges are more dangerous, but not as much as before
            max_dist = max(self.board_height, self.board_width) // 2
            edge_factor = 1.0 + (0.3 * (1.0 - dist_to_edge / max_dist))
            
            probabilities[cell] = edge_factor
        
        logger.debug(f"Edge probability calculated for {len(unrevealed_cells)} cells")
        return probabilities
    
    def calculate_corner_probability(self, unrevealed_cells: List[Tuple[int, int]]) -> Dict[Tuple[int, int], float]:
        """
        Calculate mine probability based on corner proximity.
        """
        probabilities = {}
        
        for cell in unrevealed_cells:
            row, col = cell
            
            # Check if cell is in a corner
            is_corner = ((row == 0 or row == self.board_height - 1) and 
                        (col == 0 or col == self.board_width - 1))
            
            # Corner factor: corners might be slightly more dangerous
            corner_factor = 1.1 if is_corner else 1.0
            
            probabilities[cell] = corner_factor
        
        logger.debug(f"Corner probability calculated for {len(unrevealed_cells)} cells")
        return probabilities
    
    def calculate_isolation_probability(self, unrevealed_cells: List[Tuple[int, int]], 
                                      revealed_cells: Set[Tuple[int, int]]) -> Dict[Tuple[int, int], float]:
        """
        Calculate mine probability based on isolation from revealed cells.
        """
        probabilities = {}
        
        for cell in unrevealed_cells:
            row, col = cell
            
            # Count revealed neighbors
            revealed_neighbors = self._get_revealed_neighbors(row, col, revealed_cells)
            
            # Isolation factor: cells with more revealed neighbors are safer
            isolation_factor = 1.0 + (0.2 * (4 - len(revealed_neighbors)) / 4)
            
            probabilities[cell] = isolation_factor
        
        logger.debug(f"Isolation probability calculated for {len(unrevealed_cells)} cells")
        return probabilities
    
    def get_guessing_candidates(self, unrevealed_cells: List[Tuple[int, int]], 
                               revealed_cells: Set[Tuple[int, int]], 
                               flagged_cells: Set[Tuple[int, int]], 
                               board_state: np.ndarray) -> List[Tuple[int, int]]:
        """
        Get ranked list of guessing candidates with enhanced probability models.
        """
        if not unrevealed_cells:
            return []
        
        remaining_mines = self.mine_count - len(flagged_cells)
        
        # Calculate individual probability components
        global_probs = self.calculate_global_density_probability(unrevealed_cells, remaining_mines)
        local_probs = self.calculate_local_density_probability(unrevealed_cells, revealed_cells, board_state)
        pattern_probs = self.calculate_pattern_probability(unrevealed_cells, revealed_cells, board_state)
        edge_probs = self.calculate_edge_probability(unrevealed_cells)
        corner_probs = self.calculate_corner_probability(unrevealed_cells)
        isolation_probs = self.calculate_isolation_probability(unrevealed_cells, revealed_cells)
        
        # Combine probabilities using weighted average
        combined_probs = {}
        for cell in unrevealed_cells:
            combined_prob = (
                self.weights['global_density'] * global_probs.get(cell, 1.0) +
                self.weights['local_density'] * local_probs.get(cell, 1.0) +
                self.weights['pattern_recognition'] * pattern_probs.get(cell, 1.0) +
                self.weights['edge_factor'] * edge_probs.get(cell, 1.0) +
                self.weights['corner_factor'] * corner_probs.get(cell, 1.0) +
                self.weights['isolation_factor'] * isolation_probs.get(cell, 1.0)
            )
            combined_probs[cell] = combined_prob
        
        # Rank by safety (lower probability = safer)
        ranked_candidates = sorted(unrevealed_cells, key=lambda cell: combined_probs[cell])
        
        logger.debug(f"Ranked {len(ranked_candidates)} guessing candidates")
        for i, cell in enumerate(ranked_candidates[:5]):  # Log top 5
            prob = combined_probs[cell]
            logger.debug(f"  {i+1}. Cell {cell}: probability {prob:.3f}")
        
        return ranked_candidates
    
    def select_best_guess(self, unrevealed_cells: List[Tuple[int, int]], 
                         revealed_cells: Set[Tuple[int, int]], 
                         flagged_cells: Set[Tuple[int, int]], 
                         board_state: np.ndarray) -> Optional[Tuple[int, int]]:
        """
        Select the best cell to guess with enhanced selection logic.
        """
        candidates = self.get_guessing_candidates(unrevealed_cells, revealed_cells, 
                                                flagged_cells, board_state)
        
        if not candidates:
            logger.warning("No guessing candidates available")
            return None
        
        # Enhanced selection: consider multiple top candidates
        if len(candidates) >= 3:
            # If we have multiple good candidates, prefer the one with most revealed neighbors
            top_candidates = candidates[:3]
            best_candidate = max(top_candidates, 
                               key=lambda cell: len(self._get_revealed_neighbors(cell[0], cell[1], revealed_cells)))
        else:
            best_candidate = candidates[0]
        
        logger.debug(f"Selected best guess: {best_candidate}")
        return best_candidate
    
    def get_probability_info(self, cell: Tuple[int, int], 
                           unrevealed_cells: List[Tuple[int, int]], 
                           revealed_cells: Set[Tuple[int, int]], 
                           flagged_cells: Set[Tuple[int, int]], 
                           board_state: np.ndarray) -> Dict:
        """
        Get detailed probability information for a specific cell.
        """
        remaining_mines = self.mine_count - len(flagged_cells)
        
        global_prob = self.calculate_global_density_probability(unrevealed_cells, remaining_mines).get(cell, 1.0)
        local_prob = self.calculate_local_density_probability(unrevealed_cells, revealed_cells, board_state).get(cell, 1.0)
        pattern_prob = self.calculate_pattern_probability(unrevealed_cells, revealed_cells, board_state).get(cell, 1.0)
        edge_prob = self.calculate_edge_probability(unrevealed_cells).get(cell, 1.0)
        corner_prob = self.calculate_corner_probability(unrevealed_cells).get(cell, 1.0)
        isolation_prob = self.calculate_isolation_probability(unrevealed_cells, revealed_cells).get(cell, 1.0)
        
        combined_prob = (
            self.weights['global_density'] * global_prob +
            self.weights['local_density'] * local_prob +
            self.weights['pattern_recognition'] * pattern_prob +
            self.weights['edge_factor'] * edge_prob +
            self.weights['corner_factor'] * corner_prob +
            self.weights['isolation_factor'] * isolation_prob
        )
        
        return {
            'cell': cell,
            'global_density': global_prob,
            'local_density': local_prob,
            'pattern_recognition': pattern_prob,
            'edge_factor': edge_prob,
            'corner_factor': corner_prob,
            'isolation_factor': isolation_prob,
            'combined_probability': combined_prob,
            'weights': self.weights.copy()
        }


def test_probabilistic_guesser():
    """Test the enhanced probabilistic guesser with a simple example."""
    # Create a 4x4 board with 2 mines
    guesser = ProbabilisticGuesser((4, 4), 2)
    
    # Simulate a board state
    board_state = np.zeros((4, 4, 4), dtype=np.float32)
    revealed_cells = {(0, 0), (0, 1)}
    flagged_cells = set()
    unrevealed_cells = [(i, j) for i in range(4) for j in range(4) 
                        if (i, j) not in revealed_cells]
    
    # Set some revealed numbers
    board_state[0, 0, 0] = 1
    board_state[0, 1, 0] = 2
    
    # Get guessing candidates
    candidates = guesser.get_guessing_candidates(unrevealed_cells, revealed_cells, 
                                               flagged_cells, board_state)
    
    print(f"Enhanced guessing candidates: {candidates[:5]}")  # Show top 5
    
    # Get detailed info for first candidate
    if candidates:
        info = guesser.get_probability_info(candidates[0], unrevealed_cells, 
                                          revealed_cells, flagged_cells, board_state)
        print(f"Enhanced probability info for {candidates[0]}: {info}")


if __name__ == "__main__":
    test_probabilistic_guesser() 