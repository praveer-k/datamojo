import time
from sys import argv, exit
from builtin.simd import SIMD
from random import random_si64, seed

struct TicTacToe:
    var board: SIMD[DType.int8, 9]
    var player: Int8  # 1 for X, -1 for O
    var moves_made: Int

    fn __init__(mut self):
        self.board = SIMD[DType.int8, 9](0)
        self.player = 1  # X goes first
        self.moves_made = 0

    fn is_valid_move(self, position: Int) -> Bool:
        if position < 0 or position >= 9:
            return False
        return self.board[position] == 0

    fn make_move(mut self, position: Int) -> Bool:
        if not self.is_valid_move(position):
            return False

        self.board[position] = self.player
        self.moves_made += 1
        self.player *= -1  # Switch player
        return True

    fn check_win(self) -> Int8:
        # Check rows
        for i in range(0, 9, 3):
            var sum = self.board[i] + self.board[i+1] + self.board[i+2]
            if sum == 3:
                return 1  # X wins
            if sum == -3:
                return -1  # O wins

        # Check columns
        for i in range(3):
            var sum = self.board[i] + self.board[i+3] + self.board[i+6]
            if sum == 3:
                return 1
            if sum == -3:
                return -1

        # Check diagonals
        var diag1 = self.board[0] + self.board[4] + self.board[8]
        var diag2 = self.board[2] + self.board[4] + self.board[6]

        if diag1 == 3 or diag2 == 3:
            return 1
        if diag1 == -3 or diag2 == -3:
            return -1

        return 0  # No winner yet

    fn is_board_full(self) -> Bool:
        return self.moves_made == 9

    fn ai_move(mut self) -> Int:
        # First try to win using SIMD
        # var best_score: Int = -10
        # var best_move: Int = -1

        # Create masks for each winning line
        var win_masks = [
            SIMD[DType.int8, 9](1, 1, 1, 0, 0, 0, 0, 0, 0),  # Row 1
            SIMD[DType.int8, 9](0, 0, 0, 1, 1, 1, 0, 0, 0),  # Row 2
            SIMD[DType.int8, 9](0, 0, 0, 0, 0, 0, 1, 1, 1),  # Row 3
            SIMD[DType.int8, 9](1, 0, 0, 1, 0, 0, 1, 0, 0),  # Col 1
            SIMD[DType.int8, 9](0, 1, 0, 0, 1, 0, 0, 1, 0),  # Col 2
            SIMD[DType.int8, 9](0, 0, 1, 0, 0, 1, 0, 0, 1),  # Col 3
            SIMD[DType.int8, 9](1, 0, 0, 0, 1, 0, 0, 0, 1),  # Diag 1
            SIMD[DType.int8, 9](0, 0, 1, 0, 1, 0, 1, 0, 0)   # Diag 2
        ]

        # Evaluate all possible moves
        for pos in range(9):
            if not self.is_valid_move(pos):
                continue

            var temp_board = self.board
            temp_board[pos] = self.player

            # var score: Int = 0

            # Check if this move creates a win using SIMD dot products
            for i in range(8):  # 8 possible winning lines
                var player_count = (temp_board * win_masks[i]).reduce_add()

                # Prioritize winning moves
                if player_count == 3 * self.player:
                    return pos  # Immediate win found

                # Evaluate based on potential
                if player_count == 2 * self.player:
                    score += 5
                elif player_count == self.player:
                    score += 1

                # Block opponent's winning moves
                var opponent = -self.player
                var opp_board = temp_board * opponent.cast[DType.int8]() // self.player.cast[DType.int8]()
                var opp_count = (opp_board * win_masks[i]).reduce_add()
                if opp_count == 2 * opponent:
                    score += 4  # High priority for blocking

            # Consider center position as strategic
            if pos == 4:
                score += 2

            # Update best move if found
            if score > best_score:
                best_score = score
                best_move = pos

        # If no strategic move found, pick randomly among available
        if best_move == -1:
            seed(time.now())
            var available_moves = DynamicVector[Int]()
            for i in range(9):
                if self.is_valid_move(i):
                    available_moves.append(i)

            var random_index = Int(random_si64() % len(available_moves))
            best_move = available_moves[random_index]

        return best_move
        # Helper function to access elements in win_masks
        fn get_mask(self, masks: ListLiteral[SIMD[DType.int8, 9], SIMD[DType.int8, 9], SIMD[DType.int8, 9], SIMD[DType.int8, 9], SIMD[DType.int8, 9], SIMD[DType.int8, 9], SIMD[DType.int8, 9], SIMD[DType.int8, 9]], index: Int) -> SIMD[DType.int8, 9]:
            if index == 0:
                return masks[0]
            elif index == 1:
                return masks[1]
            elif index == 2:
                return masks[2]
            elif index == 3:
                return masks[3]
            elif index == 4:
                return masks[4]
            elif index == 5:
                return masks[5]
            elif index == 6:
                return masks[6]
            else:
                return masks[7]

    fn print_board(self):
        print("-------------")
        for i in range(3):
            var row = "| "
            for j in range(3):
                var idx = i * 3 + j
                var cell = self.board[idx]
                if cell == 1:
                    row += "X | "
                elif cell == -1:
                    row += "O | "
                else:
                    row += String(idx) + " | "
            print(row)
            print("-------------")

fn main():
    var game = TicTacToe()

    print("Welcome to Tic Tac Toe!")
    print("You are X, AI is O")
    print("Enter a number from 0-8 to make your move:")

    while True:
        game.print_board()

        # Check for win or draw
        var winner = game.check_win()
        if winner != 0:
            if winner == 1:
                print("X wins!")
            else:
                print("O wins!")
            break

        if game.is_board_full():
            print("It's a draw!")
            break

        # Player's turn
        if game.player == 1:
            print("Your move (0-8):")
            try:
                var position = atol(input())
                if not game.make_move(position):
                    print("Invalid move! Try again.")
                    continue
            except:
                print("Please enter a valid number.")
                continue
        # AI's turn
        else:
            print("AI is thinking...")
            var ai_position = game.ai_move()
            _ = game.make_move(ai_position)
            print("AI chose position", ai_position)

    # Show final board
    game.print_board()
    print("Game over!")
