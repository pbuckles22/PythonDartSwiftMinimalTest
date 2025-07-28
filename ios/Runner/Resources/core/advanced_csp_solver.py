#!/usr/bin/env python3
"""
Advanced Constraint Satisfaction Problem (CSP) Solver for Minesweeper

Implements advanced CSP techniques including:
- Arc consistency
- Forward checking
- Backtracking with heuristics
- Pattern recognition
- Subset sum optimization
"""

import numpy as np
from typing import List, Tuple, Set, Dict, Optional, Any
from collections import defaultdict, deque
import logging
from itertools import combinations

# Configure logging
logging.basicConfig(level=logging.WARNING)
logger = logging.getLogger(__name__)


class AdvancedMinesweeperCSP:
    """
    Advanced CSP solver with sophisticated constraint propagation.
    
    Features:
    - Arc consistency propagation
    - Forward checking
    - Pattern recognition
    - Subset sum optimization
    - Heuristic variable ordering
    """
    
    def __init__(self, board_size: Tuple[int, int], mine_count: int):
        """
        Initialize the advanced CSP solver.
        
        Args:
            board_size: (height, width) of the board
            mine_count: Total number of mines on the board
        """
        self.board_height, self.board_width = board_size
        self.mine_count = mine_count
        self.total_cells = self.board_height * self.board_width
        
        # CSP state
        self.variables = set()  # All cell positions
        self.domains = {}       # Domain for each variable
        self.constraints = []   # List of constraints
        self.constraint_graph = defaultdict(set)  # Constraint graph
        
        # Board state tracking
        self.revealed = set()   # Revealed cells
        self.flagged = set()    # Flagged mines
        
        # Performance optimizations
        self._neighbor_offsets = [(-1, -1), (-1, 0), (-1, 1),
                                 (0, -1),           (0, 1),
                                 (1, -1),  (1, 0),  (1, 1)]
        self.adjacency_cache = {}
        
        # Advanced features
        self.pattern_cache = {}  # Cache for pattern recognition
        self.subset_cache = {}   # Cache for subset sum calculations
        
        # Initialize variables and domains
        self._initialize_csp()
    
    def _initialize_csp(self):
        """Initialize CSP variables and domains."""
        for i in range(self.board_height):
            for j in range(self.board_width):
                cell = (i, j)
                self.variables.add(cell)
                self.domains[cell] = {'safe', 'mine'}
    
    def _get_neighbors(self, row: int, col: int) -> List[Tuple[int, int]]:
        """Get valid neighboring cells with caching."""
        if (row, col) in self.adjacency_cache:
            return self.adjacency_cache[(row, col)]
        
        neighbors = []
        for di, dj in self._neighbor_offsets:
            ni, nj = row + di, col + dj
            if (0 <= ni < self.board_height and 
                0 <= nj < self.board_width):
                neighbors.append((ni, nj))
        
        self.adjacency_cache[(row, col)] = neighbors
        return neighbors
    
    def _get_unrevealed_neighbors(self, row: int, col: int) -> List[Tuple[int, int]]:
        """Get unrevealed neighboring cells."""
        neighbors = self._get_neighbors(row, col)
        return [n for n in neighbors if n not in self.revealed]
    
    def _get_flagged_neighbors(self, row: int, col: int) -> List[Tuple[int, int]]:
        """Get flagged neighboring cells."""
        neighbors = self._get_neighbors(row, col)
        return [n for n in neighbors if n in self.flagged]
    
    def update_board_state(self, board_state: np.ndarray, revealed_cells: Set[Tuple[int, int]], 
                          flagged_cells: Set[Tuple[int, int]]):
        """
        Update the CSP with current board state.
        
        Args:
            board_state: Current board state (4-channel representation)
            revealed_cells: Set of revealed cell positions
            flagged_cells: Set of flagged cell positions
        """
        self.revealed = revealed_cells.copy()
        self.flagged = flagged_cells.copy()
        
        # Update domains based on revealed information
        self._update_domains_from_revealed()
        
        # Generate constraints from revealed numbers
        self._generate_constraints(board_state)
        
        # Build constraint graph
        self._build_constraint_graph()
        
        logger.debug(f"Updated CSP state: {len(self.revealed)} revealed, {len(self.flagged)} flagged")
    
    def _update_domains_from_revealed(self):
        """Update domains based on revealed cells."""
        for cell in self.revealed:
            self.domains[cell] = {'safe'}
        
        for cell in self.flagged:
            self.domains[cell] = {'mine'}
    
    def _generate_constraints(self, board_state: np.ndarray):
        """Generate constraints from revealed numbers with advanced features."""
        self.constraints = []
        
        # Extract game state from second channel (index 1) which contains revealed numbers
        # Channel 0 has -1 for unrevealed, channel 1 has the actual numbers
        game_state = board_state[1]
        
        # Detect revealed cells from the observation
        # A cell is revealed if it has a number (0-8) and is not -1 in channel 0
        # Channel 0 shows -1 for unrevealed, channel 1 shows the numbers
        revealed_from_obs = set()
        unrevealed_state = board_state[0]  # Channel 0 shows unrevealed cells
        
        for i in range(self.board_height):
            for j in range(self.board_width):
                # Cell is revealed if it's not -1 in channel 0 (unrevealed state)
                # AND it has a valid number (0-8) in channel 1
                if unrevealed_state[i, j] != -1 and 0 <= game_state[i, j] <= 8:
                    revealed_from_obs.add((i, j))
        
        # Update our revealed set with what we detected
        self.revealed.update(revealed_from_obs)
        
        # Generate adjacency constraints
        for i in range(self.board_height):
            for j in range(self.board_width):
                cell = (i, j)
                if cell in self.revealed:
                    number = game_state[i, j]
                    if 0 <= number <= 8:  # Valid revealed number (not mine)
                        unrevealed_neighbors = self._get_unrevealed_neighbors(i, j)
                        if unrevealed_neighbors:
                            flagged_neighbors = self._get_flagged_neighbors(i, j)
                            constraint = {
                                'type': 'adjacency',
                                'center': cell,
                                'number': number,
                                'unrevealed': unrevealed_neighbors,
                                'flagged': flagged_neighbors,
                                'required_mines': number - len(flagged_neighbors),
                                'variables': set(unrevealed_neighbors)
                            }
                            self.constraints.append(constraint)
        
        # Add global mine count constraint
        remaining_mines = self.mine_count - len(self.flagged)
        unrevealed_cells = [cell for cell in self.variables 
                           if cell not in self.revealed and cell not in self.flagged]
        
        if unrevealed_cells:
            global_constraint = {
                'type': 'global_mine_count',
                'cells': unrevealed_cells,
                'required_mines': remaining_mines,
                'variables': set(unrevealed_cells)
            }
            self.constraints.append(global_constraint)
        
        logger.debug(f"Generated {len(self.constraints)} constraints")
    
    def _build_constraint_graph(self):
        """Build constraint graph for arc consistency."""
        self.constraint_graph.clear()
        
        for constraint in self.constraints:
            if constraint['type'] == 'adjacency':
                variables = constraint['variables']
                for var1 in variables:
                    for var2 in variables:
                        if var1 != var2:
                            self.constraint_graph[var1].add(var2)
    
    def solve_step(self) -> List[Tuple[int, int]]:
        """
        Find safe moves using advanced constraint satisfaction.
        
        Returns:
            List of cell positions that can be safely revealed
        """
        safe_cells = []
        
        # Apply advanced constraint propagation
        self._arc_consistency()
        self._forward_checking()
        self._pattern_recognition()
        self._subset_sum_optimization()
        
        # Find cells that are definitely safe
        for cell in self.variables:
            if cell not in self.revealed and cell not in self.flagged:
                if self.domains[cell] == {'safe'}:
                    safe_cells.append(cell)
        
        if safe_cells:
            logger.info(f"Found {len(safe_cells)} safe cells: {safe_cells}")
        else:
            logger.debug("Found 0 safe cells")
        
        return safe_cells
    
    def _arc_consistency(self):
        """Apply arc consistency propagation."""
        queue = deque()
        
        # Initialize queue with all arcs
        for constraint in self.constraints:
            if constraint['type'] == 'adjacency':
                variables = list(constraint['variables'])
                for i, var1 in enumerate(variables):
                    for var2 in variables[i+1:]:
                        queue.append((var1, var2, constraint))
                        queue.append((var2, var1, constraint))
        
        # Process queue
        while queue:
            var1, var2, constraint = queue.popleft()
            if self._revise_domain(var1, var2, constraint):
                if not self.domains[var1]:
                    return  # Inconsistent
                
                # Add arcs back to queue
                for neighbor in self.constraint_graph[var1]:
                    if neighbor != var2:
                        for c in self.constraints:
                            if (var1 in c.get('variables', set()) and 
                                neighbor in c.get('variables', set())):
                                queue.append((neighbor, var1, c))
    
    def _revise_domain(self, var1: Tuple[int, int], var2: Tuple[int, int], 
                      constraint: Dict) -> bool:
        """Revise domain of var1 based on constraint with var2."""
        if constraint['type'] != 'adjacency':
            return False
        
        original_domain = self.domains[var1].copy()
        revised = False
        
        # Check each value in var1's domain
        for value1 in list(self.domains[var1]):
            has_support = False
            
            # Check if there's a value in var2's domain that satisfies the constraint
            for value2 in self.domains[var2]:
                if self._check_constraint_satisfaction(constraint, var1, value1, var2, value2):
                    has_support = True
                    break
            
            if not has_support:
                self.domains[var1].remove(value1)
                revised = True
        
        return revised
    
    def _check_constraint_satisfaction(self, constraint: Dict, var1: Tuple[int, int], 
                                     value1: str, var2: Tuple[int, int], value2: str) -> bool:
        """Check if a constraint is satisfied by given variable assignments."""
        if constraint['type'] == 'adjacency':
            # Count mines in the constraint's variables
            mine_count = 0
            if value1 == 'mine':
                mine_count += 1
            if value2 == 'mine':
                mine_count += 1
            
            # Add mines from other variables in the constraint
            for var in constraint['variables']:
                if var not in [var1, var2]:
                    if self.domains[var] == {'mine'}:
                        mine_count += 1
            
            return mine_count <= constraint['required_mines']
        
        return True
    
    def _forward_checking(self):
        """Apply forward checking to reduce domains."""
        for constraint in self.constraints:
            if constraint['type'] == 'adjacency':
                self._forward_check_constraint(constraint)
    
    def _forward_check_constraint(self, constraint: Dict):
        """Apply forward checking to a specific constraint."""
        unrevealed = set(constraint['unrevealed'])
        required_mines = constraint['required_mines']
        
        if not unrevealed:
            return
        
        # Count current mine assignments
        mine_count = 0
        unknown_cells = []
        
        for cell in unrevealed:
            domain = self.domains[cell]
            if domain == {'mine'}:
                mine_count += 1
            elif domain == {'safe', 'mine'}:
                unknown_cells.append(cell)
        
        # If we have too many mines, this is impossible
        if mine_count > required_mines:
            return
        
        # If we have exactly the required mines, all unknown cells are safe
        if mine_count == required_mines and unknown_cells:
            for cell in unknown_cells:
                self.domains[cell] = {'safe'}
        
        # If all remaining cells must be mines, mark them
        remaining_cells = len(unknown_cells)
        if mine_count + remaining_cells == required_mines and unknown_cells:
            for cell in unknown_cells:
                self.domains[cell] = {'mine'}
    
    def _pattern_recognition(self):
        """Apply pattern recognition to identify common configurations."""
        for constraint in self.constraints:
            if constraint['type'] == 'adjacency':
                self._recognize_patterns(constraint)
    
    def _recognize_patterns(self, constraint: Dict):
        """Recognize common patterns in constraints."""
        unrevealed = constraint['unrevealed']
        required_mines = constraint['required_mines']
        
        # Pattern: 1-1 pattern (two cells, one mine)
        if len(unrevealed) == 2 and required_mines == 1:
            # If one cell is known to be a mine, the other is safe
            for cell in unrevealed:
                if self.domains[cell] == {'mine'}:
                    other_cell = next(c for c in unrevealed if c != cell)
                    self.domains[other_cell] = {'safe'}
            # If one cell is known to be safe, the other is a mine
            for cell in unrevealed:
                if self.domains[cell] == {'safe'}:
                    other_cell = next(c for c in unrevealed if c != cell)
                    self.domains[other_cell] = {'mine'}
        
        # Pattern: 2-2 pattern (two cells, two mines)
        elif len(unrevealed) == 2 and required_mines == 2:
            # Both cells must be mines
            for cell in unrevealed:
                self.domains[cell] = {'mine'}
        
        # Pattern: 1-2-1 (three cells, two mines)
        elif len(unrevealed) == 3 and required_mines == 2:
            # If the pattern matches [1, 2, 1] in adjacent constraints
            # This is a simplified version: if two cells are known mines, the third is safe
            mine_count = sum(1 for cell in unrevealed if self.domains[cell] == {'mine'})
            if mine_count == 2:
                for cell in unrevealed:
                    if self.domains[cell] != {'mine'}:
                        self.domains[cell] = {'safe'}
        
        # Pattern: 1-2-2-1 (four cells, three mines)
        elif len(unrevealed) == 4 and required_mines == 3:
            # If three cells are known mines, the fourth is safe
            mine_count = sum(1 for cell in unrevealed if self.domains[cell] == {'mine'})
            if mine_count == 3:
                for cell in unrevealed:
                    if self.domains[cell] != {'mine'}:
                        self.domains[cell] = {'safe'}
        
        # Pattern: 1-1-2-1-1 (five cells, two mines)
        elif len(unrevealed) == 5 and required_mines == 2:
            # If two cells are known mines, the rest are safe
            mine_count = sum(1 for cell in unrevealed if self.domains[cell] == {'mine'})
            if mine_count == 2:
                for cell in unrevealed:
                    if self.domains[cell] != {'mine'}:
                        self.domains[cell] = {'safe'}
    
    def _subset_sum_optimization(self):
        """Apply subset sum optimization for complex constraints."""
        changed = True
        while changed:
            changed = False
            overlapping_constraints = self._find_overlapping_constraints()
            for constraint_group in overlapping_constraints:
                before = {v: self.domains[v].copy() for c in constraint_group for v in c['variables']}
                self._solve_subset_sum(constraint_group)
                after = {v: self.domains[v].copy() for c in constraint_group for v in c['variables']}
                if before != after:
                    changed = True
    
    def _find_overlapping_constraints(self) -> List[List[Dict]]:
        """Find groups of constraints that share variables."""
        adjacency_constraints = [c for c in self.constraints if c['type'] == 'adjacency']
        groups = []
        used = []  # Use a list instead of a set
        
        for constraint in adjacency_constraints:
            if any(constraint is u for u in used):
                continue
            
            group = [constraint]
            used.append(constraint)
            
            # Find all constraints that share variables with this one
            for other_constraint in adjacency_constraints:
                if not any(other_constraint is u for u in used):
                    if constraint['variables'] & other_constraint['variables']:
                        group.append(other_constraint)
                        used.append(other_constraint)
            
            if len(group) > 1:
                groups.append(group)
        
        return groups
    
    def _solve_subset_sum(self, constraint_group: List[Dict]):
        """Solve subset sum problem for overlapping constraints using enumeration."""
        # Collect all variables involved
        all_variables = sorted(set().union(*(c['variables'] for c in constraint_group)))
        ambiguous_vars = [v for v in all_variables if self.domains[v] == {'safe', 'mine'}]
        n = len(ambiguous_vars)
        if n == 0:
            return
        
        # Build a map from variable to index
        var_idx = {v: i for i, v in enumerate(ambiguous_vars)}
        
        # Enumerate all possible mine assignments
        valid_assignments = []
        for bits in range(2**n):
            assignment = {}
            for i, v in enumerate(ambiguous_vars):
                assignment[v] = 'mine' if (bits & (1 << i)) else 'safe'
            # Check if this assignment satisfies all constraints
            consistent = True
            for constraint in constraint_group:
                mines = 0
                for v in constraint['variables']:
                    if v in assignment:
                        if assignment[v] == 'mine':
                            mines += 1
                    elif self.domains[v] == {'mine'}:
                        mines += 1
                if mines != constraint['required_mines']:
                    consistent = False
                    break
            if consistent:
                valid_assignments.append(assignment)
        
        if not valid_assignments:
            # No valid assignments: leave domains ambiguous
            return
        
        # For each variable, check if always mine or always safe
        for v in ambiguous_vars:
            if all(a[v] == 'mine' for a in valid_assignments):
                self.domains[v] = {'mine'}
            elif all(a[v] == 'safe' for a in valid_assignments):
                self.domains[v] = {'safe'}
    
    def get_constraint_info(self) -> Dict:
        """Get information about current constraints."""
        return {
            'total_constraints': len(self.constraints),
            'adjacency_constraints': len([c for c in self.constraints if c['type'] == 'adjacency']),
            'global_constraints': len([c for c in self.constraints if c['type'] == 'global_mine_count']),
            'revealed_cells': len(self.revealed),
            'flagged_cells': len(self.flagged),
            'constraint_graph_size': len(self.constraint_graph)
        }
    
    def can_make_progress(self) -> bool:
        """Check if CSP can make progress."""
        return len(self.constraints) > 0


def test_advanced_csp_solver():
    """Test the advanced CSP solver with a complex example."""
    # Create a 5x5 board with 3 mines
    csp = AdvancedMinesweeperCSP((5, 5), 3)
    
    # Simulate a complex board state
    revealed_cells = {(0, 0), (0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 2)}
    flagged_cells = set()
    
    # Create a board state with overlapping constraints
    board_state = np.zeros((4, 5, 5))
    board_state[0, 0, 0] = 1  # Number 1
    board_state[0, 0, 1] = 2  # Number 2
    board_state[0, 0, 2] = 1  # Number 1
    board_state[0, 1, 0] = 2  # Number 2
    board_state[0, 1, 2] = 2  # Number 2
    board_state[0, 2, 0] = 1  # Number 1
    board_state[0, 2, 2] = 1  # Number 1
    
    csp.update_board_state(board_state, revealed_cells, flagged_cells)
    
    # Try to solve
    safe_cells = csp.solve_step()
    print(f"Advanced CSP found {len(safe_cells)} safe cells: {safe_cells}")
    
    # Get constraint info
    info = csp.get_constraint_info()
    print(f"Constraint info: {info}")


if __name__ == "__main__":
    test_advanced_csp_solver() 