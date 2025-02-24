import pygame
import random

pygame.init()
pygame.mixer.init()  ## inp nhạc

info = pygame.display.Info()  ## Lấy tt về size của man hinh
WIDTH, HEIGHT = info.current_w, info.current_h
screen = pygame.display.set_mode((WIDTH, HEIGHT), pygame.FULLSCREEN)
pygame.display.set_caption("Game khong hay thi lay tien")

clock = pygame.time.Clock()  # Clock set_up, for fps

WHITE = (255, 255, 255)
BLUE = (0, 0, 225)
RED = (255, 0, 0)
BLACK = (0, 0, 0)
CYAN = (102, 255, 217)

cur = 0
Score = 0
Highest_score = 0
Level = 1
player_speed = 12
player_size = 25
player_x, player_y = WIDTH // 2, HEIGHT - player_size
obstacle_speed = 10
obstacle_size = 30
num_of_obstacles = 12

collision_sound = pygame.mixer.Sound('collision.mp3')
dash = pygame.mixer.Sound('footstep.mp3')
pygame.mixer.music.load('background.flac')
pygame.mixer.music.play(-1) 

# Danh sách chứa các vị trí của nhân vật để tạo hiệu ứng trail
trail = []
max_trail_length = 15  # Số lượng điểm tối đa cho trail

# Các biến cho hiệu ứng explosion
explosion_active = False
explosion_counter = 0
explosion_position = (0, 0)

# Hàm vẽ hiệu ứng explosion
def draw_explosion(x, y, counter):
    explosion_radius = counter * 3  # Tăng kích thước theo số frame
    # Tạo surface hỗ trợ alpha
    explosion_surface = pygame.Surface((explosion_radius * 2, explosion_radius * 2), pygame.SRCALPHA)
    alpha = max(255 - counter * 10, 0)  # Giảm độ mờ theo thời gian
    explosion_color = (255, 165, 0, alpha)  # Màu cam cho hiệu ứng nổ
    pygame.draw.circle(explosion_surface, explosion_color, (explosion_radius, explosion_radius), explosion_radius)
    screen.blit(explosion_surface, (x - explosion_radius, y - explosion_radius))

# Hàm tạo danh sách các obstacle
def create_obstacles(num):
    obstacles = []
    for i in range(num):
        obs = {
            'x': random.randint(player_size, WIDTH - player_size),
            'y': -obstacle_size,
            'size': obstacle_size,
            'speed': obstacle_speed
        }
        obstacles.append(obs)
    return obstacles

# Khởi tạo danh sách obstacles
obstacles = create_obstacles(num_of_obstacles)

def Restart_game():
    global player_x, player_y, obstacles, Score, trail, obstacle_speed, num_of_obstacles, Level, cur, explosion_active, explosion_counter
    Score = 0
    obstacle_speed = 10
    num_of_obstacles = 12
    Level = 1
    cur = 0
    player_x, player_y = WIDTH // 2, HEIGHT - player_size
    obstacles = create_obstacles(num_of_obstacles)  # Tạo lại danh sách obstacles
    trail = []  # Reset lại trail
    explosion_active = False
    explosion_counter = 0

font = pygame.font.SysFont('Times New Roman', 40)
def Draw_Text(text, color, x, y):
    label = font.render(text, True, color)
    screen.blit(label, (x, y))

def Player():
    global player_x, player_y
    keys = pygame.key.get_pressed()
    if keys[pygame.K_LEFT]:
        player_x -= player_speed
    if keys[pygame.K_RIGHT]:
        player_x += player_speed
    if keys[pygame.K_UP]:
        player_y -= player_speed
    if keys[pygame.K_DOWN]:
        player_y += player_speed

    # Giới hạn chuyển động của player trong màn hình
    if player_x < player_size:
        player_x = player_size
    if player_x > WIDTH - player_size:
        player_x = WIDTH - player_size
    if player_y < player_size:
        player_y = player_size
    if player_y > HEIGHT - player_size:
        player_y = HEIGHT - player_size

# Hàm riêng để vẽ trail cho nhân vật
def draw_trail():
    for i, pos in enumerate(trail):
        alpha = int(255 * ((i + 1) / len(trail)))
        temp_surface = pygame.Surface((player_size * 2, player_size * 2), pygame.SRCALPHA)
        pygame.draw.circle(temp_surface, (CYAN[0], CYAN[1], CYAN[2], alpha), (player_size, player_size), player_size)
        screen.blit(temp_surface, (pos[0] - player_size, pos[1] - player_size))

running = True
game_over = False

while running:
    screen.fill(WHITE)

    # Nếu có hiệu ứng explosion đang hoạt động, xử lý riêng
    if explosion_active:
        draw_explosion(explosion_position[0], explosion_position[1], explosion_counter)
        explosion_counter += 1
        if explosion_counter > 30:  # Sau khi hiệu ứng hoàn thành, chuyển về trạng thái game over
            explosion_active = False
            game_over = True
        pygame.display.flip()
        clock.tick(60)
        continue

    if game_over:
        # Xử lý sự kiện trong trạng thái game over
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        
        Draw_Text("Làm lại thì nhấn R", BLACK, WIDTH // 3, HEIGHT // 5)
        Draw_Text("Sợ quá thì bấm Q", BLACK, WIDTH // 3, HEIGHT // 4)
        Draw_Text("Điểm: " + str(Score), BLACK, WIDTH // 3, HEIGHT // 2 - 100)
        Draw_Text("Highscore " + str(Highest_score), BLACK, WIDTH // 3, HEIGHT // 2)
        pygame.display.flip()
        keys = pygame.key.get_pressed()
        if keys[pygame.K_r] or keys[pygame.K_SPACE]:
            Restart_game()
            game_over = False
        if keys[pygame.K_q]:
            running = False
        continue

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

    Player()

    # Cập nhật danh sách trail
    trail.append((player_x, player_y))
    if len(trail) > max_trail_length:
        trail.pop(0)

    # Vẽ trail trước để nó nằm sau nhân vật (với hiệu ứng mờ dần)
    draw_trail()

    # Cập nhật vị trí của các obstacle
    for obs in obstacles:
        obs['y'] += random.randint(1, obstacle_speed + 10)
        if obs['y'] > HEIGHT:
            obs['y'] = -obstacle_size
            obs['x'] = random.randint(player_size, WIDTH - player_size)
    Score += 1

    if Score >= cur + 500:
        cur += 500
        Level += 1
        obstacle_speed += 5
        num_of_obstacles += 3
        dash.play()

    # Kiểm tra va chạm giữa player và các obstacle
    player_box = pygame.Rect(player_x - player_size, player_y - player_size, player_size * 2, player_size * 2)
    for obs in obstacles:
        obs_box = pygame.Rect(obs['x'], obs['y'], obs['size'], obs['size'])
        if player_box.colliderect(obs_box):
            collision_sound.play()
            # Kích hoạt hiệu ứng explosion thay vì chuyển game over ngay
            explosion_active = True
            explosion_counter = 0
            explosion_position = (player_x, player_y)
            Highest_score = max(Highest_score, Score)
            break

    Draw_Text("Điểm: " + str(Score), BLACK, 10, 10)
    Draw_Text("Level: " + str(Level), BLACK, WIDTH // 2 + 20, 10)

    # Vẽ player và các obstacle
    pygame.draw.circle(screen, BLUE, (player_x, player_y), player_size)
    for obs in obstacles:
        pygame.draw.rect(screen, RED, (obs['x'], obs['y'], obs['size'], obs['size']))

    pygame.display.flip()
    clock.tick(60)

pygame.quit()
