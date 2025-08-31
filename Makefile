CC := /usr/bin/gcc
CFLAGS := -std=c99 -Wall -Wpedantic -Wextra -D_THREAD_SAFE -O3
LIBS := -L/opt/homebrew/lib -lSDL3
INCLUDES := -I/opt/homebrew/include/
SRC_DIR := src
BUILD_DIR := build
BIN := $(BUILD_DIR)/sdl3_test

# Find all .c files in SRC_DIR
SRCS := $(wildcard $(SRC_DIR)/*.c)

# Turn each .c file into a .o file in BUILD_DIR
OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))

build: $(BIN)

# Link objects into final binary
$(BIN): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(OBJS) $(LIBS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

run: build
	./$(BIN)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean