#!/usr/bin/env python3
import time
import os
import random
import argparse
import sys # Added for exit

# Attempt to import colorama for colored output
try:
    import colorama
    from colorama import Fore, Back, Style
    colorama.init()
    COLORAMA_ENABLED = True
except ImportError:
    # Define dummy Fore, Back, Style if colorama is not installed
    class DummyStyle:
        def __getattr__(self, name):
            return ""
    Fore = Back = Style = DummyStyle()
    COLORAMA_ENABLED = False
    print("Notice: 'colorama' package not found. Output will not be colored.")
    print("Install it with: pip install colorama\\n")

# --- Configuration ---
DEFAULT_ARRAY_SIZE = 15
DEFAULT_MIN_VALUE = 1 # Added default min value
DEFAULT_MAX_VALUE = 50
DEFAULT_ALGORITHM = 'bubble'
DEFAULT_SPEED = 0.2
MAX_BAR_WIDTH = 40 # Max width for ASCII bars

# --- Visualization Functions ---

def clear_screen():
    """Clears the terminal screen."""
    os.system('cls' if os.name == 'nt' else 'clear')

def pause(delay, interactive):
    """Pauses execution either for a fixed delay or until Enter is pressed."""
    if interactive:
        input("Press Enter to continue...")
    else:
        time.sleep(delay)

def visualize_array(arr, max_val, min_val, algorithm_name, stats, highlights=None):
    """Prints a visualization of the array with ASCII bars and stats.

    Args:
        arr (list): The array to visualize.
        max_val (int): The maximum value in the original array for scaling.
        min_val (int): The minimum value in the original array (used for display alignment).
        algorithm_name (str): Name of the sorting algorithm.
        stats (dict): Dictionary containing statistics like comparisons and swaps/moves.
        highlights (dict, optional): Dictionary indicating elements to highlight.
            Keys can be:
            - 'compare': Tuple/List of indices being compared. (Yellow)
            - 'swap': Tuple/List of indices being swapped/moved. (Red)
            - 'pivot': Index of a pivot element (e.g., in Insertion Sort). (Magenta)
            - 'sorted': Index up to which the array is sorted. (Green range)
    """
    clear_screen()
    if highlights is None:
        highlights = {}

    print(f"{Fore.CYAN}--- {algorithm_name.replace('_', ' ').title()} Sort Visualization ---{Style.RESET_ALL}")

    # Print Current Action/Status
    status_line = ""
    if 'compare' in highlights:
        indices = highlights['compare']
        status_line += f"{Fore.YELLOW}Comparing: Idx {indices[0]}({arr[indices[0]]}) and Idx {indices[1]}({arr[indices[1]]}) {Style.RESET_ALL} | "
    if 'swap' in highlights:
        indices = highlights['swap']
        # Handle single element moves (like in Insertion Sort)
        if len(indices) == 2:
             status_line += f"{Fore.RED}Swap/Move: Idx {indices[0]}({arr[indices[0]]}) <-> Idx {indices[1]}({arr[indices[1]]}) {Style.RESET_ALL} | "
        elif len(indices) == 1:
             status_line += f"{Fore.RED}Moving Value: {arr[indices[0]]} {Style.RESET_ALL} | "
    if 'pivot' in highlights:
         status_line += f"{Fore.MAGENTA}Current Key/Pivot: Idx {highlights['pivot']}({arr[highlights['pivot']]}) {Style.RESET_ALL} | "

    print(status_line.strip(" | "))
    print(f"Stats: Comparisons: {stats.get('comparisons', 0)}, Swaps/Moves: {stats.get('swaps_moves', 0)}")
    print("-" * (max(60, len(arr) * 3)))

    # --- Bar Scaling Logic (Refinement Area 3 from previous iteration) ---
    # Scales based on max_val, ensuring min bar length 1 for val > 0.
    scale = 1.0
    current_max = max(arr) if arr else 0 # Use current max for display alignment
    current_min = min(arr) if arr else 0 # Use current min for display alignment

    # Use the original max_val passed in for scaling calculations
    if max_val > 0:
       scale = MAX_BAR_WIDTH / max_val
    elif len(arr) > 0: # If original max_val is 0, but array not empty, all are 0.
        pass # Scale remains 1, bar_length will be 0

    # Find max digits based on original range for consistent alignment
    max_digits_orig = max(len(str(max_val)), len(str(min_val)))
    # Ensure current values also fit
    max_digits_curr = len(str(current_max if current_max>=0 else current_min))
    max_digits = max(max_digits_orig, max_digits_curr)


    sorted_idx = highlights.get('sorted', -1) # Elements up to this index are sorted

    for i, val in enumerate(arr):
        # Calculate bar length - ensure non-zero values < 1/scale get at least 1 block
        bar_length = int(val * scale)
        if val > 0 and bar_length == 0:
             bar_length = 1 # Minimum length for non-zero values
        # Handle negative values potentially, though current generation is positive
        if val < 0:
            bar_length = 0 # Or implement different visualization for negatives
        bar = '\u2588' * bar_length

        # Determine color based on state
        color = Fore.WHITE
        style = Style.NORMAL
        if i <= sorted_idx:
            color = Fore.GREEN # Mark sorted elements
        if 'compare' in highlights and i in highlights['compare']:
            color = Fore.YELLOW
            style = Style.BRIGHT
        if 'swap' in highlights and i in highlights['swap']:
            color = Fore.RED
            style = Style.BRIGHT
        if 'pivot' in highlights and i == highlights['pivot']:
            color = Fore.MAGENTA
            style = Style.BRIGHT

        # Print row: Index | Bar | Value
        print(f"{style}{color}{i:2d} | {bar:<{MAX_BAR_WIDTH}} | {val:<{max_digits}}{Style.RESET_ALL}")

    print("-" * (max(60, len(arr) * 3)))
    print("\\n")


# --- Sorting Algorithms ---
# Each sort function now accepts min_val and max_val for consistent visualization calls

def bubble_sort_visualized(arr, delay, interactive, min_val, max_val):
    """Performs bubble sort on the array with visualization."""
    n = len(arr)
    if n <= 1: return arr, {'comparisons': 0, 'swaps_moves': 0}

    stats = {'comparisons': 0, 'swaps_moves': 0}
    algo_name = 'bubble_sort'

    visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'sorted': -1})
    pause(delay * 3, interactive) # Initial view longer

    for i in range(n):
        pass_swapped = False
        for j in range(0, n - i - 1):
            stats['comparisons'] += 1
            # Visualize the comparison step
            visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'compare': (j, j + 1), 'sorted': n - i}) # Show sorted area shrinking
            pause(delay, interactive)

            # Compare adjacent elements
            if arr[j] > arr[j + 1]:
                # Swap elements
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                stats['swaps_moves'] += 1
                pass_swapped = True

                # Visualize the swap step
                visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'swap': (j, j + 1), 'sorted': n - i})
                pause(delay * 1.5, interactive) # Slightly longer pause after swap

        # Provide visual cue that the last element is now sorted
        visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'sorted': n - i - 1})
        pause(delay, interactive)

        # Optimization: If no swapping occurred, array is sorted
        if not pass_swapped:
            print(f"{Fore.GREEN}Optimization: Array sorted early! No swaps in pass {i + 1}.{Style.RESET_ALL}")
            pause(delay * 2, interactive)
            break

    return arr, stats


def insertion_sort_visualized(arr, delay, interactive, min_val, max_val):
    """Performs insertion sort on the array with visualization."""
    n = len(arr)
    if n <= 1: return arr, {'comparisons': 0, 'swaps_moves': 0}

    stats = {'comparisons': 0, 'swaps_moves': 0}
    algo_name = 'insertion_sort'

    visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'sorted': 0}) # First element is trivially sorted
    pause(delay * 3, interactive) # Initial view longer

    # Iterate from the second element (index 1)
    for i in range(1, n):
        key = arr[i]
        j = i - 1

        # Visualize the key selection
        visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'pivot': i, 'sorted': i - 1})
        pause(delay, interactive)

        # Compare key with elements in the sorted subarray arr[0..i-1]
        # Move elements of arr[0..i-1], that are greater than key,
        # to one position ahead of their current position
        compare_made = False # Track if any comparisons happened in the while loop for the current key
        while j >= 0:
            stats['comparisons'] += 1
            compare_made = True
            visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'pivot': i, 'compare': (i, j), 'sorted': i - 1})
            pause(delay, interactive)

            if arr[j] > key:
                stats['swaps_moves'] += 1 # Count shifts as moves
                arr[j + 1] = arr[j]
                # Visualize the shift
                visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'pivot': i, 'swap': (j+1,), 'sorted': i - 1}) # Highlight element being moved TO
                pause(delay * 1.5, interactive)
                j -= 1
            else:
                break # Found the correct position

        # Place key at after the element just smaller than it.
        key_moved = (j + 1 != i) # Did the key actually move from its original position?
        if key_moved:
             stats['swaps_moves'] += 1 # Count insertion as a move only if it changed position
             arr[j + 1] = key
             # Visualize the insertion
             visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'swap': (j + 1,), 'sorted': i})
             pause(delay * 1.5, interactive)
        elif compare_made: # If no move, but we compared, still show the updated sorted state
             visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'sorted': i}) # Ensure key[i] is green now
             pause(delay, interactive)
        # If no comparisons and no move (key was already in correct relative order), proceed without extra pause

    return arr, stats


def selection_sort_visualized(arr, delay, interactive, min_val, max_val):
    """Performs selection sort on the array with visualization."""
    n = len(arr)
    if n <= 1: return arr, {'comparisons': 0, 'swaps_moves': 0}

    stats = {'comparisons': 0, 'swaps_moves': 0}
    algo_name = 'selection_sort'

    visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'sorted': -1})
    pause(delay * 3, interactive)  # Initial view longer

    for i in range(n):
        min_idx = i
        # Visualize the start of the pass, highlighting the current position being filled
        visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'pivot': i, 'sorted': i - 1})
        pause(delay, interactive)

        # Find the minimum element in the remaining unsorted array
        current_min_highlight = min_idx # Track the index visually marked as current minimum
        for j in range(i + 1, n):
            stats['comparisons'] += 1
            # Highlight comparison: current min vs element being checked
            visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'compare': (current_min_highlight, j), 'pivot': i, 'sorted': i - 1})
            pause(delay, interactive)

            if arr[j] < arr[min_idx]:
                min_idx = j
                # Highlight the new minimum found (as the comparison target for next iteration)
                current_min_highlight = min_idx
                visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'compare': (current_min_highlight, j), 'pivot': i, 'sorted': i - 1})
                pause(delay*0.5, interactive) # Brief pause showing new min selected


        # Swap the found minimum element with the first element of the unsorted part
        if min_idx != i:
            stats['swaps_moves'] += 1
            arr[i], arr[min_idx] = arr[min_idx], arr[i]
            # Visualize the swap
            visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'swap': (i, min_idx), 'sorted': i - 1})
            pause(delay * 1.5, interactive)

        # Visualize the end of the pass - element 'i' is now sorted
        visualize_array(arr, max_val, min_val, algo_name, stats, highlights={'sorted': i})
        pause(delay * 1.5, interactive)

    return arr, stats

# --- Main Execution ---

if __name__ == "__main__":
    # --- Argument Parsing (Refinement Area 1 from previous iteration + Added Args) ---
    parser = argparse.ArgumentParser(description="Visualize sorting algorithms in the terminal.")
    parser.add_argument("-n", "--size", type=int, default=DEFAULT_ARRAY_SIZE,
                        help=f"Number of elements in the array (default: {DEFAULT_ARRAY_SIZE})")
    parser.add_argument("--min-value", type=int, default=DEFAULT_MIN_VALUE,
                        help=f"Minimum random value for array elements (default: {DEFAULT_MIN_VALUE})")
    parser.add_argument("--max-value", type=int, default=DEFAULT_MAX_VALUE,
                        help=f"Maximum random value for array elements (default: {DEFAULT_MAX_VALUE})")
    parser.add_argument("-a", "--algorithm", type=str, choices=['bubble', 'insertion', 'selection'],
                        default=DEFAULT_ALGORITHM,
                        help=f"Sorting algorithm to use (default: {DEFAULT_ALGORITHM})")
    parser.add_argument("-s", "--speed", type=float, default=DEFAULT_SPEED,
                        help=f"Animation speed (delay between steps in seconds) (default: {DEFAULT_SPEED})")
    parser.add_argument("-i", "--interactive", action='store_true',
                        help="Enable interactive mode (press Enter to advance steps)")
    parser.add_argument("-r", "--random-seed", type=int, default=None,
                        help="Seed for random number generator for reproducible arrays")


    args = parser.parse_args()

    # Validate inputs
    if args.size <= 0:
        print(f"{Fore.RED}Error: Array size must be positive.{Style.RESET_ALL}")
        sys.exit(1) # Use sys.exit
    if args.min_value > args.max_value:
        print(f"{Fore.RED}Error: Min value ({args.min_value}) cannot be greater than Max value ({args.max_value}).{Style.RESET_ALL}")
        sys.exit(1)
    if args.speed < 0:
        print(f"{Fore.RED}Error: Speed (delay) cannot be negative.{Style.RESET_ALL}")
        sys.exit(1)

    # Set random seed if provided
    if args.random_seed is not None:
        random.seed(args.random_seed)

    # Generate random array using min and max values
    random_array = [random.randint(args.min_value, args.max_value) for _ in range(args.size)]
    array_copy = random_array[:] # Work on a copy

    # Store min/max for visualization consistency
    initial_min_val = args.min_value if not array_copy else min(array_copy) # Get actual min if array exists
    initial_max_val = args.max_value if not array_copy else max(array_copy) # Get actual max if array exists


    # --- Algorithm Selection (Refinement Area 2 from previous iteration) ---
    sort_functions = {
        'bubble': bubble_sort_visualized,
        'insertion': insertion_sort_visualized,
        'selection': selection_sort_visualized
    }

    selected_sort_function = sort_functions.get(args.algorithm)

    if not selected_sort_function:
        print(f"{Fore.RED}Error: Unknown algorithm '{args.algorithm}'.{Style.RESET_ALL}")
        sys.exit(1)

    # Initial array print
    print(f"{Fore.WHITE}Algorithm: {args.algorithm.title()}, Size: {args.size}, Range: [{args.min_value}-{args.max_value}], Speed: {args.speed}, Interactive: {args.interactive}, Seed: {args.random_seed}{Style.RESET_ALL}")
    print(f"{Fore.CYAN}Initial array: {array_copy}{Style.RESET_ALL}")
    if not args.interactive:
      print("(Running automatically, press Ctrl+C to interrupt)")
    input("Press Enter to start visualization...") # Pause before starting

    # Run the visualized sort
    start_time = time.time()
    # Pass min_val and max_val to the sort function
    sorted_array, final_stats = selected_sort_function(array_copy, args.speed, args.interactive, initial_min_val, initial_max_val)
    end_time = time.time()

    # Final visualization
    final_max_val = max(sorted_array) if sorted_array else 1
    final_min_val = min(sorted_array) if sorted_array else 0
    visualize_array(sorted_array, initial_max_val, initial_min_val, args.algorithm, final_stats, highlights={'sorted': len(sorted_array) -1}) # Show all green

    print(f"{Fore.GREEN}--- {args.algorithm.replace('_', ' ').title()} Sort Complete! ---{Style.RESET_ALL}")
    print(f"Total Comparisons: {final_stats.get('comparisons', 0)}")
    print(f"Total Swaps/Moves: {final_stats.get('swaps_moves', 0)}")
    print(f"Time Taken: {end_time - start_time:.3f} seconds")
    print(f"{Fore.CYAN}Final Sorted array: {sorted_array}{Style.RESET_ALL}")

    print(f"\\n{Fore.WHITE}Visualization finished.{Style.RESET_ALL}")
    if args.interactive:
        input("Press Enter to exit...")