import numpy as np
import warnings
from typing import List, Tuple, Optional, Dict, Any
import time
from datetime import datetime
from collections import deque
import logging
import os
import sys

# Try to import gym, but provide fallback for CSP-only usage
try:
    import gym
    from gym import spaces
    GYM_AVAILABLE = True
except ImportError:
    GYM_AVAILABLE = False
    # Create simple space classes for CSP usage
    class SimpleDiscrete:
        def __init__(self, n):
            self.n = n
        
        def contains(self, x):
            """Check if x is in the space."""
            return isinstance(x, int) and 0 <= x < self.n
    
    class SimpleBox:
        def __init__(self, low, high, shape, dtype):
            self.low = low
            self.high = high
            self.shape = shape
            self.dtype = dtype
        
        def contains(self, x):
            """Check if x is in the space."""
            if not isinstance(x, np.ndarray):
                return False
            if x.shape != self.shape:
                return False
            if self.low is not None and np.any(x < self.low):
                return False
            if self.high is not None and np.any(x > self.high):
                return False
            return True

    class spaces:
        Discrete = SimpleDiscrete
        Box = SimpleBox

from .constants import (
    CELL_UNREVEALED,
    CELL_MINE,
    CELL_MINE_HIT,
    UNKNOWN_SAFETY,
    REWARD_FIRST_CASCADE_SAFE,
    REWARD_FIRST_CASCADE_HIT_MINE,
    REWARD_SAFE_REVEAL,
    REWARD_WIN,
    REWARD_HIT_MINE,
    REWARD_INVALID_ACTION,
    DIFFICULTY_LEVELS
)

class MinesweeperEnv:
    """
    A Minesweeper environment for reinforcement learning with enhanced state representation and fixed observation/action space for curriculum learning.
    Supports multiple difficulty levels from easy to chaotic.
    """
    def __init__(self, max_board_size=(35, 20), max_mines=130, render_mode=None,
                 early_learning_mode=False, early_learning_threshold=200,
                 early_learning_corner_safe=True, early_learning_edge_safe=True,
                 initial_board_size=4, initial_mines=2,
                 invalid_action_penalty=REWARD_INVALID_ACTION, mine_penalty=REWARD_HIT_MINE,
                 safe_reveal_base=REWARD_SAFE_REVEAL, win_reward=REWARD_WIN,
                 first_cascade_safe_reward=REWARD_FIRST_CASCADE_SAFE, first_cascade_hit_mine_reward=REWARD_FIRST_CASCADE_HIT_MINE):
        """Initialize the Minesweeper environment.
        
        Args:
            max_board_size: Maximum board dimensions (height, width)
            max_mines: Maximum number of mines
            render_mode: Rendering mode ('human' or None)
            early_learning_mode: Enable early learning mode
            early_learning_threshold: Threshold for early learning mode
            early_learning_corner_safe: Make corners safe in early learning
            early_learning_edge_safe: Make edges safe in early learning
            initial_board_size: Initial board size (height, width) or single dimension
            initial_mines: Initial number of mines
            invalid_action_penalty: Penalty for invalid actions
            mine_penalty: Penalty for hitting mines
            safe_reveal_base: Base reward for safe reveals
            win_reward: Reward for winning
            first_cascade_safe_reward: Reward for first cascade safe
            first_cascade_hit_mine_reward: Reward for first cascade hit mine
        """
        # Validate parameters
        if isinstance(max_board_size, int):
            if max_board_size <= 0:
                raise ValueError("Board size must be positive")
            if max_board_size > 100:
                raise ValueError("Board dimensions too large")
            max_board_area = max_board_size * max_board_size
            self.max_board_size = (max_board_size, max_board_size)
        else:
            if max_board_size[0] <= 0 or max_board_size[1] <= 0:
                raise ValueError("Board dimensions must be positive")
            if max_board_size[0] > 100 or max_board_size[1] > 100:
                raise ValueError("Board dimensions too large")
            max_board_area = max_board_size[0] * max_board_size[1]
            self.max_board_size = max_board_size
        if max_mines <= 0:
            raise ValueError("Mine count must be positive")
        if max_mines > max_board_area:
            raise ValueError("Mine count cannot exceed board size area (height*width)")
        
        # Initial parameters
        if isinstance(initial_board_size, int):
            if initial_board_size <= 0:
                raise ValueError("Initial board size must be positive")
            if isinstance(max_board_size, int):
                if initial_board_size > max_board_size:
                    raise ValueError("Initial board size cannot exceed max board size")
            else:
                if initial_board_size > max_board_size[0] or initial_board_size > max_board_size[1]:
                    raise ValueError("Initial board size cannot exceed max board size")
            self.initial_board_size = (initial_board_size, initial_board_size)
        else:
            if initial_board_size[0] <= 0 or initial_board_size[1] <= 0:
                raise ValueError("Initial board dimensions must be positive")
            if initial_board_size[0] > self.max_board_size[0] or initial_board_size[1] > self.max_board_size[1]:
                raise ValueError("Initial board size cannot exceed max board size")
            self.initial_board_size = initial_board_size
        if initial_mines <= 0:
            raise ValueError("Initial mine count must be positive")
        if initial_mines > self.initial_board_size[0] * self.initial_board_size[1]:
            raise ValueError("Initial mine count cannot exceed initial board area (height*width)")
        
        # Validate reward parameters
        if invalid_action_penalty is None or mine_penalty is None or safe_reveal_base is None or win_reward is None:
            raise TypeError("'>=' not supported between instances of 'NoneType' and 'int'")
        
        self.max_mines = max_mines
        self.initial_mines = initial_mines
        # Current parameters (can change during curriculum learning)
        self.current_board_height, self.current_board_width = self.initial_board_size
        self.current_mines = initial_mines
        
        # Early learning parameters
        self.early_learning_mode = early_learning_mode
        self.early_learning_threshold = early_learning_threshold
        self.early_learning_corner_safe = early_learning_corner_safe
        self.early_learning_edge_safe = early_learning_edge_safe
        
        # Reward parameters
        self.invalid_action_penalty = invalid_action_penalty
        self.mine_penalty = mine_penalty
        self.safe_reveal_base = safe_reveal_base
        self.win_reward = win_reward
        self.first_cascade_safe_reward = first_cascade_safe_reward
        self.first_cascade_hit_mine_reward = first_cascade_hit_mine_reward
        self.reward_invalid_action = invalid_action_penalty
        
        # Game state
        self.board = None
        self.mines = None
        self.revealed = None
        self.terminated = False
        self.truncated = False
        self.mines_placed = False
        
        # Pre-cascade tracking
        self.is_first_cascade = True
        self.in_cascade = False
        
        # Statistics tracking - Dual system
        # Real-life statistics (what would happen in actual Minesweeper)
        self.real_life_games_played = 0
        self.real_life_games_won = 0
        self.real_life_games_lost = 0
        
        # RL training statistics (excluding pre-cascade games)
        self.rl_games_played = 0
        self.rl_games_won = 0
        self.rl_games_lost = 0
        
        # Current game tracking
        self.current_game_was_pre_cascade = False
        self.current_game_ended_pre_cascade = False
        
        # Move counting for current game
        self.move_count = 0
        self.total_moves_across_games = 0
        self.games_with_move_counts = []
        
        # Repeated actions and revealed cell clicks
        self.repeated_actions = set()
        self.repeated_action_count = 0
        self.revealed_cell_click_count = 0
        self._actions_taken_this_game = set()
        
        # Reset invalid action and guaranteed mine click counters
        self.invalid_action_count = 0
        
        # Action space and observation space
        self.action_space = spaces.Discrete(self.current_board_width * self.current_board_height)
        self.observation_space = spaces.Box(
            low=-1, high=9, 
            shape=(4, self.current_board_height, self.current_board_width), 
            dtype=np.float32
        )
        
        # State representation
        self.state = np.zeros((4, self.current_board_height, self.current_board_width), dtype=np.float32)
        
        # Rendering
        self.render_mode = render_mode
        self.screen = None
        self.clock = None
        self.cell_size = 30
        
        # Initialize the environment
        self.reset()

    @property
    def max_board_height(self):
        """Get the maximum board height."""
        return self.max_board_size[0]

    @property
    def max_board_width(self):
        """Get the maximum board width."""
        return self.max_board_size[1]

    @property
    def initial_board_height(self):
        """Get the initial board height."""
        return self.initial_board_size[0]

    @property
    def initial_board_width(self):
        """Get the initial board width."""
        return self.initial_board_size[1]

    # Backward compatibility properties
    @property
    def max_board_size_int(self):
        """Get max board size as integer for backward compatibility."""
        if self.max_board_size[0] == self.max_board_size[1]:
            return self.max_board_size[0]
        return self.max_board_size[0]  # Return width as default

    def reset(self, seed=None, options=None):
        """Reset the environment."""
        # Ensure deterministic numpy RNG if seed is provided
        if seed is not None:
            np.random.seed(seed)
        
        # Initialize or update action space based on current board size
        self.action_space = spaces.Discrete(self.current_board_width * self.current_board_height)
        
        # Initialize enhanced state space with 4 channels for better pattern recognition
        low_bounds = np.full((4, self.current_board_height, self.current_board_width), -1, dtype=np.float32)
        low_bounds[0] = -4  # Channel 0: game state can go as low as -4 (mine hit)
        low_bounds[1] = -1  # Channel 1: safety hints can go as low as -1 (unknown)
        low_bounds[2] = 0   # Channel 2: revealed cell count (always >= 0)
        low_bounds[3] = 0   # Channel 3: game progress indicators (always >= 0)
        
        high_bounds = np.full((4, self.current_board_height, self.current_board_width), 8, dtype=np.float32)
        high_bounds[2] = self.current_board_height * self.current_board_width  # Max revealed cells
        high_bounds[3] = 1  # Binary indicators
        
        self.observation_space = spaces.Box(
            low=low_bounds,
            high=high_bounds,
            shape=(4, self.current_board_height, self.current_board_width),
            dtype=np.float32
        )
        
        # Initialize board state
        self.board = np.zeros((self.current_board_height, self.current_board_width), dtype=np.int8)
        self.mines = np.zeros((self.current_board_height, self.current_board_width), dtype=bool)
        self.revealed = np.zeros((self.current_board_height, self.current_board_width), dtype=bool)
        
        # Initialize enhanced state with 4 channels
        self.state = np.zeros((4, self.current_board_height, self.current_board_width), dtype=np.float32)
        
        # Channel 0: Game state (all unrevealed initially)
        self.state[0] = CELL_UNREVEALED
        
        # Channel 1: Safety hints (all unknown initially)
        self.state[1] = UNKNOWN_SAFETY
        
        # Channel 2: Revealed cell count (0 initially)
        self.state[2] = 0
        
        # Channel 3: Game progress indicators (0 initially)
        self.state[3] = 0
        
        # Reset game state variables
        self.revealed_count = 0
        self.won = False
        self.terminated = False
        self.truncated = False
        self.is_first_cascade = True
        self.first_cascade_done = False
        self.in_cascade = False  # Track if we're currently in a cascade
        
        # Reset move counting for new game
        self.move_count = 0
        
        # Reset repeated action and revealed cell click counters
        self.repeated_actions = set()
        self.repeated_action_count = 0
        self.revealed_cell_click_count = 0
        self._actions_taken_this_game = set()
        
        # Initialize info dict
        self.info = {
            "won": False
        }
        
        # Place mines immediately (before first move)
        self._place_mines()
        
        # Update enhanced state after mine placement
        self._update_enhanced_state()
        
        return self.state, self.info

    def _place_mines(self):
        """Place mines randomly on the board with optimized algorithm."""
        # Use numpy's random choice for better performance
        total_cells = self.current_board_height * self.current_board_width
        
        # Generate random indices for mine placement
        mine_indices = np.random.choice(total_cells, size=self.current_mines, replace=False)
        
        # Convert indices to 2D coordinates and place mines
        for idx in mine_indices:
            row = idx // self.current_board_width
            col = idx % self.current_board_width
            self.mines[row, col] = True

        # Update adjacent counts
        self._update_adjacent_counts()

    def _update_adjacent_counts(self):
        """Update the board with the count of adjacent mines using optimized convolution."""
        # Reset the board to zeros
        self.board.fill(0)
        
        # Create a kernel for counting adjacent mines
        # This is more efficient than nested loops
        kernel = np.array([[1, 1, 1],
                          [1, 0, 1],
                          [1, 1, 1]], dtype=np.int8)
        
        # Convert mines to int for convolution
        mines_int = self.mines.astype(np.int8)
        
        # Use scipy's convolve2d if available, otherwise use numpy
        try:
            from scipy.signal import convolve2d
            adjacent_counts = convolve2d(mines_int, kernel, mode='same', boundary='fill', fillvalue=0)
        except ImportError:
            # Fallback to numpy implementation
            adjacent_counts = np.zeros_like(mines_int, dtype=np.int8)
            for i in range(self.current_board_height):
                for j in range(self.current_board_width):
                    if self.mines[i, j]:
                        # Set the mine cell to 9 (representing a mine)
                        self.board[i, j] = 9
                        # Count adjacent mines using optimized offsets
                        for di, dj in [(-1, -1), (-1, 0), (-1, 1),
                                     (0, -1),           (0, 1),
                                     (1, -1),  (1, 0),  (1, 1)]:
                            ni, nj = i + di, j + dj
                            if (0 <= ni < self.current_board_height and 
                                0 <= nj < self.current_board_width):
                                adjacent_counts[ni, nj] += 1
        
        # Copy adjacent counts to board (excluding mine positions)
        mine_positions = self.mines
        self.board[~mine_positions] = adjacent_counts[~mine_positions]

    def _reveal_cell(self, row: int, col: int) -> None:
        """Reveal a cell and its neighbors if it's empty."""
        if not (0 <= row < self.current_board_height and 0 <= col < self.current_board_width):
            return
        if self.revealed[row, col]:
            return

        self.revealed[row, col] = True
        cell_value = self._get_cell_value(row, col)
        self.state[0, row, col] = cell_value

        # Check if this is a cascade (cell with value 0)
        if cell_value == 0:
            # This is a cascade - mark that we're in a cascade
            self.in_cascade = True
            # Note: We don't set is_first_cascade = False here anymore
            # It will be set after the win check in the step function
            # Reveal all neighbors
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0:
                        continue
                    self._reveal_cell(row + dr, col + dc)

    def _get_neighbors(self, row: int, col: int) -> List[Tuple[int, int]]:
        """Get all valid neighbors of a cell with optimized calculation.
        Args:
            row: Row coordinate
            col: Column coordinate
        Returns:
            List of (row, col) tuples for valid neighbors
        """
        # Pre-computed neighbor offsets for better performance
        neighbor_offsets = [(-1, -1), (-1, 0), (-1, 1),
                           (0, -1),           (0, 1),
                           (1, -1),  (1, 0),  (1, 1)]
        
        neighbors = []
        for dr, dc in neighbor_offsets:
            nr, nc = row + dr, col + dc
            if (0 <= nr < self.current_board_height and 
                0 <= nc < self.current_board_width):
                neighbors.append((nr, nc))
        return neighbors

    def _check_win(self) -> bool:
        """Check if the game is won.
        Win condition: All non-mine cells must be revealed.
        Returns:
            bool: True if all non-mine cells are revealed, False otherwise.
        """
        # For each cell that is not a mine, it must be revealed
        for i in range(self.current_board_height):
            for j in range(self.current_board_width):
                if not self.mines[i, j] and not self.revealed[i, j]:
                    return False
        return True

    def step(self, action):
        # Initialize info dict with 'won' key
        info = {'won': self._check_win()}

        # Convert action to integer if it's a numpy array
        if hasattr(action, 'item'):
            action = action.item()

        # If game is over, all actions are invalid and return negative reward
        if self.terminated or self.truncated:
            return self.state, self.invalid_action_penalty, True, False, info

        # Terminate if no valid actions left
        if not np.any(self.action_masks):
            self.terminated = True
            info['won'] = self._check_win()
            return self.state, 0.0, True, False, info

        # Check if action is within bounds first
        if action < 0 or action >= self.action_space.n:
            self.invalid_action_count += 1
            return self.state, self.invalid_action_penalty, False, False, info

        # Track repeated actions
        if action in self._actions_taken_this_game:
            self.repeated_action_count += 1
            self.repeated_actions.add(action)
        else:
            self._actions_taken_this_game.add(action)

        # Check if action is valid using action masks
        if not self.action_masks[action]:
            self.invalid_action_count += 1
            # If the cell is already revealed, increment revealed_cell_click_count
            col = action % self.current_board_width
            row = action // self.current_board_width
            if self.revealed[row, col]:
                self.revealed_cell_click_count += 1
            return self.state, self.invalid_action_penalty, False, False, info

        # Increment move count for valid actions
        self.move_count += 1

        # Convert action to (x, y) coordinates
        col = action % self.current_board_width
        row = action // self.current_board_width

        # Handle cell reveal
        if self.mines[row, col]:  # Hit a mine
            # Game always terminates on mine hit
            self.state[0, row, col] = CELL_MINE_HIT
            self.revealed[row, col] = True
            self.terminated = True
            info['won'] = False
            
            # Track if this game ended pre-cascade
            game_ended_pre_cascade = self.is_first_cascade
            
            # Update statistics
            self._update_statistics(game_won=False, game_ended_pre_cascade=game_ended_pre_cascade)
            
            # Mine hit penalty - immediate negative feedback
            return self.state, self.mine_penalty, True, False, info

        # Reveal the cell (safe cell)
        self._reveal_cell(row, col)

        # Update enhanced state after revealing cells
        self._update_enhanced_state()

        # Always check for win after all reveals (including cascades)
        if self._check_win():
            # Check if this win happened during the first cascade period
            win_during_first_cascade_period = self.is_first_cascade
            
            self.is_first_cascade = False
            self.terminated = True
            info['won'] = True
            
            # Track if this game ended pre-cascade
            game_ended_pre_cascade = win_during_first_cascade_period
            
            # Update statistics
            self._update_statistics(game_won=True, game_ended_pre_cascade=game_ended_pre_cascade)
            
            # Win reward - always give full win reward
            return self.state, self.win_reward, True, False, info

        # Safe reveal reward - immediate positive feedback
        reward = self.safe_reveal_base
        
        # If we had a cascade in this step and no win occurred, exit pre-cascade period
        if self.in_cascade and self.is_first_cascade:
            self.is_first_cascade = False
        
        # Reset cascade flag for next step
        self.in_cascade = False
        
        info['won'] = False
        return self.state, reward, False, False, info

    @property
    def action_masks(self):
        """Return a boolean mask indicating which actions are valid, including smart masking for obviously bad moves."""
        # If game is over, all actions are invalid
        if self.terminated or self.truncated:
            return np.zeros(self.action_space.n, dtype=bool)
        
        masks = np.ones(self.action_space.n, dtype=bool)
        
        for i in range(self.current_board_height):
            for j in range(self.current_board_width):
                # Reveal action
                reveal_idx = i * self.current_board_width + j
                
                # Basic masking: can't reveal already revealed cells
                if self.revealed[i, j]:
                    masks[reveal_idx] = False
                    continue
                
                # Smart masking: prefer cells that are guaranteed to be safe
                # (This is optional - we could prioritize safe cells but still allow others)
                # For now, we'll just avoid guaranteed mines
                
        return masks
    
    def render(self):
        """Render the environment (stub - no pygame rendering)."""
        # No rendering for CSP solver - just return
        pass

    def _is_valid_action(self, action):
        """Check if an action is valid."""
        # Check if action is within bounds
        if action < 0 or action >= self.action_space.n:
            return False

        # Convert action to (x, y) coordinates
        col = action % self.current_board_width
        row = action // self.current_board_width

        # Check if coordinates are valid
        if not (0 <= row < self.current_board_height and 0 <= col < self.current_board_width):
            return False

        # Handle reveal actions
        if self.revealed[row, col]:  # Can't reveal already revealed cells
            return False
        return True

    def _get_cell_value(self, row: int, col: int) -> int:
        """Get the value of a cell (number of adjacent mines).
        Args:
            row (int): Row index of the cell.
            col (int): Column index of the cell.
        Returns:
            int: The value of the cell (number of adjacent mines).
        """
        return self.board[row, col]

    def _update_enhanced_state(self):
        """Update the enhanced state representation with 4 channels for better pattern recognition."""
        # Channel 0: Game state (revealed cells with numbers, unrevealed as -1, mine hits as -4)
        for i in range(self.current_board_height):
            for j in range(self.current_board_width):
                if self.revealed[i, j]:
                    if self.mines[i, j]:
                        self.state[0, i, j] = CELL_MINE_HIT
                    else:
                        self.state[0, i, j] = self.board[i, j]
                else:
                    self.state[0, i, j] = CELL_UNREVEALED
        
        # Channel 1: Safety hints (number of adjacent mines for unrevealed cells, -1 for unknown)
        for i in range(self.current_board_height):
            for j in range(self.current_board_width):
                if self.revealed[i, j]:
                    self.state[1, i, j] = UNKNOWN_SAFETY  # Revealed cells don't need safety hints
                else:
                    # Count adjacent mines for unrevealed cells
                    adjacent_mines = 0
                    for di in [-1, 0, 1]:
                        for dj in [-1, 0, 1]:
                            if di == 0 and dj == 0:
                                continue
                            ni, nj = i + di, j + dj
                            if (0 <= ni < self.current_board_height and 
                                0 <= nj < self.current_board_width and 
                                self.mines[ni, nj]):
                                adjacent_mines += 1
                    self.state[1, i, j] = adjacent_mines
        
        # Channel 2: Revealed cell count (total number of revealed cells across the board)
        total_revealed = np.sum(self.revealed)
        self.state[2] = total_revealed
        
        # Channel 3: Game progress indicators (binary flags for important game states)
        for i in range(self.current_board_height):
            for j in range(self.current_board_width):
                # Set to 1 if this cell is a "safe bet" (adjacent to revealed cells with 0 mines)
                is_safe_bet = 0
                if not self.revealed[i, j]:  # Only for unrevealed cells
                    for di in [-1, 0, 1]:
                        for dj in [-1, 0, 1]:
                            if di == 0 and dj == 0:
                                continue
                            ni, nj = i + di, j + dj
                            if (0 <= ni < self.current_board_height and 
                                0 <= nj < self.current_board_width and 
                                self.revealed[ni, nj] and 
                                not self.mines[ni, nj] and 
                                self.board[ni, nj] == 0):  # Adjacent to revealed cell with 0 mines
                                is_safe_bet = 1
                                break
                        if is_safe_bet:
                            break
                self.state[3, i, j] = is_safe_bet

    def get_real_life_statistics(self):
        """Get real-life statistics (what would happen in actual Minesweeper gameplay).
        
        Returns:
            dict: Real-life statistics including games played, won, lost, and win rate
        """
        total_games = self.real_life_games_played
        if total_games == 0:
            return {
                'games_played': 0,
                'games_won': 0,
                'games_lost': 0,
                'win_rate': 0.0
            }
        
        return {
            'games_played': total_games,
            'games_won': self.real_life_games_won,
            'games_lost': self.real_life_games_lost,
            'win_rate': self.real_life_games_won / total_games
        }
    
    def get_rl_training_statistics(self):
        """Get RL training statistics (excluding pre-cascade games).
        
        Returns:
            dict: RL training statistics including games played, won, lost, and win rate
        """
        total_games = self.rl_games_played
        if total_games == 0:
            return {
                'games_played': 0,
                'games_won': 0,
                'games_lost': 0,
                'win_rate': 0.0
            }
        
        return {
            'games_played': total_games,
            'games_won': self.rl_games_won,
            'games_lost': self.rl_games_lost,
            'win_rate': self.rl_games_won / total_games
        }
    
    def get_combined_statistics(self):
        """Get both real-life and RL training statistics.
        
        Returns:
            dict: Combined statistics with both real-life and RL metrics
        """
        return {
            'real_life': self.get_real_life_statistics(),
            'rl_training': self.get_rl_training_statistics()
        }
    
    def _update_statistics(self, game_won, game_ended_pre_cascade):
        """Update both real-life and RL training statistics.
        
        Args:
            game_won (bool): Whether the game was won
            game_ended_pre_cascade (bool): Whether the game ended during pre-cascade period
        """
        # Always update real-life statistics
        self.real_life_games_played += 1
        if game_won:
            self.real_life_games_won += 1
        else:
            self.real_life_games_lost += 1
        
        # Only update RL training statistics if game didn't end pre-cascade
        if not game_ended_pre_cascade:
            self.rl_games_played += 1
            if game_won:
                self.rl_games_won += 1
            else:
                self.rl_games_lost += 1
        
        # Record move count for this game
        self._record_game_moves()

    def get_move_statistics(self):
        """Get statistics about moves made in the current game and across all games.
        
        Returns:
            dict: Dictionary containing move statistics
        """
        average_moves = self.total_moves_across_games / len(self.games_with_move_counts) if self.games_with_move_counts else 0
        min_moves = min(self.games_with_move_counts) if self.games_with_move_counts else 0
        max_moves = max(self.games_with_move_counts) if self.games_with_move_counts else 0
        return {
            'current_game_moves': self.move_count,
            'total_moves_across_games': self.total_moves_across_games,
            'games_with_move_counts': self.games_with_move_counts.copy(),
            'average_moves_per_game': average_moves,
            'min_moves_in_game': min_moves,
            'max_moves_in_game': max_moves,
            'repeated_action_count': self.repeated_action_count,
            'repeated_actions': list(self.repeated_actions),
            'revealed_cell_click_count': self.revealed_cell_click_count,
            'invalid_action_count': self.invalid_action_count
        }
    
    def get_board_statistics(self):
        """Get statistics about the current board configuration.
        
        Returns:
            dict: Dictionary containing board configuration statistics
        """
        # Get current mine positions
        mine_positions = []
        for i in range(self.current_board_height):
            for j in range(self.current_board_width):
                if self.mines[i, j]:
                    mine_positions.append((i, j))
        
        # Calculate board metrics
        total_cells = self.current_board_height * self.current_board_width
        mine_density = self.current_mines / total_cells
        
        return {
            'board_size': (self.current_board_height, self.current_board_width),
            'mines_placed': self.current_mines,
            'mine_positions': mine_positions,
            'total_cells': total_cells,
            'mine_density': mine_density,
            'safe_cells': total_cells - self.current_mines,
            'safe_cell_ratio': (total_cells - self.current_mines) / total_cells
        }
    
    def _record_game_moves(self):
        """Record the move count for the current game when it ends."""
        if self.move_count > 0:  # Only record if moves were made
            self.games_with_move_counts.append(self.move_count)
            self.total_moves_across_games += self.move_count

    def close(self):
        """Close the environment and clean up resources."""
        # No pygame resources to clean up for CSP solver
        pass

def main():
    # Create and test the environment
    env = MinesweeperEnv(max_board_size=8, max_mines=12)
    state, _ = env.reset()
    
    # Take a random action
    action = env.action_space.sample()
    state, reward, terminated, truncated, info = env.step(action)
    
    return state, reward, terminated, truncated, info

if __name__ == "__main__":
    main() 