CC := /usr/bin/gcc
CFLAGS := -std=c23 -Wall -Wpedantic -Wextra -D_THREAD_SAFE -O3
LIBS := -L/opt/homebrew/lib -lSDL3
INCLUDES := -I/opt/homebrew/include
SRC_DIR := src
BUILD_DIR := build
BIN := $(BUILD_DIR)/sdl3

# Find all .c files in SRC_DIR
SRCS := $(wildcard $(SRC_DIR)/*.c)

# Turn each .c file into a .o file in BUILD_DIR
OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))

.PHONY: all
all: $(BIN)

# Link objects into final binary
$(BIN): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OBJS) $(LIBS) -o $@

# Build objects
$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.PHONY: run
run: all
	./$(BIN)

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)
