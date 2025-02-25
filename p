import pygame
import sys
import random

# Cấu hình cơ bản
CELL_SIZE = 40
BOARD_SIZE = 15  # Bàn cờ 15x15
WIDTH = HEIGHT = CELL_SIZE * BOARD_SIZE
LINE_COLOR = (0, 0, 0)
BACKGROUND_COLOR = (255, 255, 255)
PLAYER_COLOR = (200, 0, 0)   # Người chơi: X
BOT_COLOR = (0, 0, 200)      # Bot hoặc Người chơi 2: O

# Giới hạn độ sâu cho thuật toán Minimax
MAX_DEPTH = 2  # Điều chỉnh sao cho cân bằng giữa tốc độ và chất lượng

# Khởi tạo Pygame và font chữ
pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Game Caro")
font = pygame.font.SysFont(None, 48)

# Khai báo biến bàn cờ toàn cục
board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]

# =====================================================
# Các hàm hỗ trợ vẽ bàn cờ, kiểm tra thắng cuộc, đánh giá ô

def draw_board(screen, board):
    """Vẽ bàn cờ và các quân cờ."""
    screen.fill(BACKGROUND_COLOR)
    # Vẽ lưới
    for x in range(BOARD_SIZE):
        pygame.draw.line(screen, LINE_COLOR, (x * CELL_SIZE, 0), (x * CELL_SIZE, HEIGHT))
    for y in range(BOARD_SIZE):
        pygame.draw.line(screen, LINE_COLOR, (0, y * CELL_SIZE), (WIDTH, y * CELL_SIZE))
    # Vẽ quân cờ
    for i in range(BOARD_SIZE):
        for j in range(BOARD_SIZE):
            center = (j * CELL_SIZE + CELL_SIZE // 2, i * CELL_SIZE + CELL_SIZE // 2)
            if board[i][j] == 1:
                offset = CELL_SIZE // 3
                pygame.draw.line(screen, PLAYER_COLOR, 
                                 (center[0] - offset, center[1] - offset), 
                                 (center[0] + offset, center[1] + offset), 3)
                pygame.draw.line(screen, PLAYER_COLOR, 
                                 (center[0] - offset, center[1] + offset), 
                                 (center[0] + offset, center[1] - offset), 3)
            elif board[i][j] == 2:
                pygame.draw.circle(screen, BOT_COLOR, center, CELL_SIZE // 3, 3)
    pygame.display.flip()

def check_win(board, player):
    """Kiểm tra xem 'player' có 5 quân liên tiếp theo bất kỳ hướng nào không."""
    for i in range(BOARD_SIZE):
        for j in range(BOARD_SIZE):
            if board[i][j] == player:
                directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
                for dx, dy in directions:
                    count = 1
                    x, y = i, j
                    # Hướng tiến
                    while True:
                        x += dx
                        y += dy
                        if 0 <= x < BOARD_SIZE and 0 <= y < BOARD_SIZE and board[x][y] == player:
                            count += 1
                        else:
                            break
                    x, y = i, j
                    # Hướng ngược
                    while True:
                        x -= dx
                        y -= dy
                        if 0 <= x < BOARD_SIZE and 0 <= y < BOARD_SIZE and board[x][y] == player:
                            count += 1
                        else:
                            break
                    if count >= 5:
                        return True
    return False

def evaluate_direction(board, i, j, dx, dy, player):
    """
    Đánh giá số quân liên tiếp theo một hướng và đếm số đầu bị chặn.
    Trả về: (count, block)
    """
    count = 0
    block = 0
    # Hướng tiến
    x, y = i + dx, j + dy
    while 0 <= x < BOARD_SIZE and 0 <= y < BOARD_SIZE:
        if board[x][y] == player:
            count += 1
            x += dx
            y += dy
        elif board[x][y] == 0:
            break
        else:
            block += 1
            break
    # Hướng lùi
    x, y = i - dx, j - dy
    while 0 <= x < BOARD_SIZE and 0 <= y < BOARD_SIZE:
        if board[x][y] == player:
            count += 1
            x -= dx
            y -= dy
        elif board[x][y] == 0:
            break
        else:
            block += 1
            break
    return count, block

def get_pattern_score(count, block):
    """Gán điểm cho pattern dựa trên số quân liên tiếp và số đầu bị chặn."""
    if count >= 4:
        return 10000
    if count == 3:
        if block == 0:
            return 1000
        elif block == 1:
            return 100
    if count == 2:
        if block == 0:
            return 100
        elif block == 1:
            return 10
    if count == 1:
        return 10
    return 0

def evaluate_cell(board, i, j, player):
    """Tính tổng điểm cho ô (i, j) theo 4 hướng."""
    score = 0
    directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
    for dx, dy in directions:
        count, block = evaluate_direction(board, i, j, dx, dy, player)
        score += get_pattern_score(count, block)
    return score

def evaluate_board(board):
    """Đánh giá trạng thái bàn cờ từ góc nhìn của bot."""
    score = 0
    for i in range(BOARD_SIZE):
        for j in range(BOARD_SIZE):
            if board[i][j] == 2:
                score += evaluate_cell(board, i, j, 2)
            elif board[i][j] == 1:
                score -= evaluate_cell(board, i, j, 1)
    return score

# =====================================================
# Các hàm cho Bot

def heuristic_bot_move(board, multiplier):
    """
    Bot sử dụng chiến lược heuristic: tính điểm cho từng ô trống.
    'multiplier' xác định mức độ ưu tiên chặn đối thủ.
    """
    best_score = -1
    best_move = None
    for i in range(BOARD_SIZE):
        for j in range(BOARD_SIZE):
            if board[i][j] == 0:
                bot_score = evaluate_cell(board, i, j, 2)
                human_score = evaluate_cell(board, i, j, 1)
                total_score = bot_score + human_score * multiplier
                if total_score > best_score:
                    best_score = total_score
                    best_move = (i, j)
    if best_move:
        board[best_move[0]][best_move[1]] = 2

def get_valid_moves(board, distance=1):
    """
    Lấy danh sách các nước đi khả thi:
    Chỉ xét các ô trống nằm trong khoảng cách 'distance' từ các quân cờ đã đánh.
    Nếu bàn cờ chưa có nước đi nào, trả về ô trung tâm.
    """
    moves = set()
    for i in range(BOARD_SIZE):
        for j in range(BOARD_SIZE):
            if board[i][j] != 0:
                for dx in range(-distance, distance+1):
                    for dy in range(-distance, distance+1):
                        x = i + dx
                        y = j + dy
                        if 0 <= x < BOARD_SIZE and 0 <= y < BOARD_SIZE and board[x][y] == 0:
                            moves.add((x, y))
    if not moves:
        moves.add((BOARD_SIZE//2, BOARD_SIZE//2))
    return list(moves)

def minimax(board, depth, is_maximizing, alpha, beta):
    """Hàm minimax có cắt tỉa alpha-beta với giới hạn độ sâu và chỉ duyệt nước đi khả thi."""
    # Trạng thái terminal
    if check_win(board, 2):
        return 10000 - depth  # Ưu tiên thắng sớm
    if check_win(board, 1):
        return -10000 + depth
    if all(board[i][j] != 0 for i in range(BOARD_SIZE) for j in range(BOARD_SIZE)):
        return 0

    # Giới hạn độ sâu
    if depth >= MAX_DEPTH:
        return evaluate_board(board)

    valid_moves = get_valid_moves(board, distance=1)  # Chỉ xét các nước đi gần quân cờ hiện có

    if is_maximizing:
        best_score = -float('inf')
        for i, j in valid_moves:
            board[i][j] = 2
            score = minimax(board, depth + 1, False, alpha, beta)
            board[i][j] = 0  # Undo move
            best_score = max(best_score, score)
            alpha = max(alpha, score)
            if beta <= alpha:
                break  # Cắt tỉa
        return best_score
    else:
        worst_score = float('inf')
        for i, j in valid_moves:
            board[i][j] = 1
            score = minimax(board, depth + 1, True, alpha, beta)
            board[i][j] = 0  # Undo move
            worst_score = min(worst_score, score)
            beta = min(beta, score)
            if beta <= alpha:
                break  # Cắt tỉa
        return worst_score

def minimax_bot_move(board):
    """Tìm nước đi tốt nhất cho bot dựa trên thuật toán Minimax."""
    best_score = -float('inf')
    best_move = None
    valid_moves = get_valid_moves(board, distance=1)
    for i, j in valid_moves:
        board[i][j] = 2
        score = minimax(board, 0, False, -float('inf'), float('inf'))
        board[i][j] = 0  # Undo move
        if score > best_score:
            best_score = score
            best_move = (i, j)
    if best_move:
        board[best_move[0]][best_move[1]] = 2

def bot_move(board, difficulty):
    """Lựa chọn chiến lược bot dựa trên độ khó."""
    if difficulty == 1:
        heuristic_bot_move(board, 1.2)
    elif difficulty == 2:
        heuristic_bot_move(board, 1.5)
    elif difficulty == 3:
        minimax_bot_move(board)

# =====================================================
# Các hàm hiển thị thông báo và menu

def show_message(text):
    """Hiển thị thông báo ở giữa màn hình."""
    text_surface = font.render(text, True, (0, 150, 0))
    rect = text_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2))
    screen.blit(text_surface, rect)
    pygame.display.flip()

def game_over_screen(message):
    """
    Màn hình kết thúc game: hiển thị thông báo và hướng dẫn.
    Nhấn R: chơi lại | M: menu | Q: thoát.
    """
    draw_board(screen, board)
    show_message(message)
    instruction = "Nhấn R: chơi lại | M: menu | Q: thoát"
    instr_surface = font.render(instruction, True, (0, 150, 0))
    instr_rect = instr_surface.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 50))
    screen.blit(instr_surface, instr_rect)
    pygame.display.flip()
    
    while True:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:
                    return "restart"
                elif event.key == pygame.K_m:
                    return "menu"
                elif event.key == pygame.K_q:
                    pygame.quit()
                    sys.exit()

def choose_mode_menu():
    """
    Menu chọn chế độ: 1 - Người vs Bot, 2 - Hai người chơi.
    """
    while True:
        screen.fill(BACKGROUND_COLOR)
        title = font.render("Chọn chế độ:", True, (0, 0, 0))
        mode1 = font.render("1 - Người vs Bot", True, (0, 0, 0))
        mode2 = font.render("2 - Hai người chơi", True, (0, 0, 0))
        screen.blit(title, (WIDTH//2 - title.get_width()//2, HEIGHT//2 - 100))
        screen.blit(mode1, (WIDTH//2 - mode1.get_width()//2, HEIGHT//2 - 30))
        screen.blit(mode2, (WIDTH//2 - mode2.get_width()//2, HEIGHT//2 + 10))
        pygame.display.flip()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    return "bot"
                elif event.key == pygame.K_2:
                    return "pvp"

def start_difficulty_menu():
    """
    Menu chọn độ khó (chỉ áp dụng cho chế độ Người vs Bot):
    1 - Vừa, 2 - Khó, 3 - Siêu Siêu Khó.
    """
    while True:
        screen.fill(BACKGROUND_COLOR)
        title = font.render("Chọn độ khó:", True, (0, 0, 0))
        diff1 = font.render("1 - Vừa", True, (0, 0, 0))
        diff2 = font.render("2 - Khó", True, (0, 0, 0))
        diff3 = font.render("3 - Siêu Siêu Khó", True, (0, 0, 0))
        screen.blit(title, (WIDTH//2 - title.get_width()//2, HEIGHT//2 - 100))
        screen.blit(diff1, (WIDTH//2 - diff1.get_width()//2, HEIGHT//2 - 30))
        screen.blit(diff2, (WIDTH//2 - diff2.get_width()//2, HEIGHT//2 + 10))
        screen.blit(diff3, (WIDTH//2 - diff3.get_width()//2, HEIGHT//2 + 50))
        pygame.display.flip()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    return 1
                elif event.key == pygame.K_2:
                    return 2
                elif event.key == pygame.K_3:
                    return 3

# =====================================================
# Hàm chạy game theo từng chế độ

def run_game_bot(difficulty):
    """
    Chế độ Người vs Bot.
    Người chơi (X) bắt đầu, sau đó bot (O) đánh theo chiến lược đã chọn.
    """
    global board
    board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
    game_over = False
    player_turn = True  # Người chơi bắt đầu
    while True:
        draw_board(screen, board)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            # Cho phép chuyển về menu khi game đang chạy (nhấn M)
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_m:
                    return "menu"
            if event.type == pygame.MOUSEBUTTONDOWN and not game_over:
                if player_turn:
                    x, y = pygame.mouse.get_pos()
                    col = x // CELL_SIZE
                    row = y // CELL_SIZE
                    if board[row][col] == 0:
                        board[row][col] = 1
                        if check_win(board, 1):
                            draw_board(screen, board)
                            result = game_over_screen("Người thắng!")
                            if result == "menu":
                                return "menu"
                            board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
                            game_over = False
                            player_turn = True
                        else:
                            player_turn = False
        # Lượt Bot
        if not player_turn and not game_over:
            pygame.time.delay(300)
            bot_move(board, difficulty)
            if check_win(board, 2):
                draw_board(screen, board)
                result = game_over_screen("Bot thắng!")
                if result == "menu":
                    return "menu"
                board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
                game_over = False
                player_turn = True
            else:
                player_turn = True
        # Kiểm tra hòa
        if not game_over and all(board[i][j] != 0 for i in range(BOARD_SIZE) for j in range(BOARD_SIZE)):
            draw_board(screen, board)
            result = game_over_screen("Hòa!")
            if result == "menu":
                return "menu"
            board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
            game_over = False
            player_turn = True

def run_game_pvp():
    """
    Chế độ Hai người chơi:
    Người chơi 1 (X) và Người chơi 2 (O) thay phiên đánh.
    """
    global board
    board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
    game_over = False
    current_player = 1  # Người chơi 1 bắt đầu
    while True:
        draw_board(screen, board)
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            # Cho phép chuyển về menu khi game đang chạy (nhấn M)
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_m:
                    return "menu"
            if event.type == pygame.MOUSEBUTTONDOWN and not game_over:
                x, y = pygame.mouse.get_pos()
                col = x // CELL_SIZE
                row = y // CELL_SIZE
                if board[row][col] == 0:
                    board[row][col] = current_player
                    if check_win(board, current_player):
                        draw_board(screen, board)
                        if current_player == 1:
                            result = game_over_screen("Người chơi 1 thắng!")
                        else:
                            result = game_over_screen("Người chơi 2 thắng!")
                        if result == "menu":
                            return "menu"
                        board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
                        game_over = False
                        current_player = 1
                    else:
                        current_player = 2 if current_player == 1 else 1
        # Kiểm tra hòa
        if not game_over and all(board[i][j] != 0 for i in range(BOARD_SIZE) for j in range(BOARD_SIZE)):
            draw_board(screen, board)
            result = game_over_screen("Hòa!")
            if result == "menu":
                return "menu"
            board = [[0 for _ in range(BOARD_SIZE)] for _ in range(BOARD_SIZE)]
            game_over = False
            current_player = 1

# =====================================================
# Hàm main

def main():
    while True:
        mode = choose_mode_menu()  # Chọn chế độ: Người vs Bot hoặc PvP
        if mode == "bot":
            difficulty = start_difficulty_menu()
            result = run_game_bot(difficulty)
            if result == "menu":
                continue
        elif mode == "pvp":
            result = run_game_pvp()
            if result == "menu":
                continue

if __name__ == "__main__":
    main()
