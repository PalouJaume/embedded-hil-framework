# --- CONFIGURACIÓN
PROJECT_HOME_DIR := .
BUILD_DIR        := build
CC               := gcc
CFLAGS           := -Wall -Wextra -g -DUNITY_INCLUDE_CONFIG_H -MMD -MP

# -- FUENTES DE LA APLICACIÓN
SRC_DIRS := \
	$(PROJECT_HOME_DIR)/src/GuidanceSystem \

INC_DIRS := \
	$(PROJECT_HOME_DIR)/include/GuidanceSystem \

# -- FUENTES DE TEST (Unity)
TEST_SRC_DIRS := \
	$(PROJECT_HOME_DIR)/tests/GuidanceSystem \
    $(PROJECT_HOME_DIR)/tests \
	$(PROJECT_HOME_DIR)/mocks \
    $(PROJECT_HOME_DIR)/unity.framework

TEST_INC_DIRS := \
    $(PROJECT_HOME_DIR)/unity.framework \
	$(PROJECT_HOME_DIR)/mocks \
    $(PROJECT_HOME_DIR)/tests\testVectors \

# --- DESCUBRIMIENTO AUTOMÁTICO DE FUENTES
SRC_FILES  := $(foreach dir, $(SRC_DIRS),      $(wildcard $(dir)/*.c))
TEST_FILES := $(foreach dir, $(TEST_SRC_DIRS), $(wildcard $(dir)/*.c))
ALL_FILES  := $(SRC_FILES) $(TEST_FILES)

OBJ_FILES  := $(patsubst %.c, $(BUILD_DIR)/%.o, $(notdir $(ALL_FILES)))
DEP_FILES  := $(OBJ_FILES:.o=.d)

# --- FLAGS DE COMPILACIÓN
ALL_INC_FLAGS := $(addprefix -I, $(INC_DIRS) $(TEST_INC_DIRS))

# --- VPATH (para encontrar .c y .h)
vpath %.c $(SRC_DIRS) $(TEST_SRC_DIRS)
vpath %.h $(INC_DIRS) $(TEST_INC_DIRS)

# --- CONFIGURACIÓN MEX
MATLAB 		:= "C:\Program Files\MATLAB\R2026a\bin\matlab.exe"
MEX_DIR     := $(PROJECT_HOME_DIR)/mex
MEX_SCRIPT  := $(MEX_DIR)/build_mex.m
MEX_WRAPPER := $(MEX_DIR)/GuidanceLaw_sfcn.c
MEX_TARGET  := $(BUILD_DIR)/GuidanceLaw_sfcn.mexw64 $(BUILD_DIR)/HardSiL_sfcn.mexw64 $(BUILD_DIR)/PiL_sfcn.mexw64
MEX_CDEPS   := $(PROJECT_HOME_DIR)/src/GuidanceSystem/GuidanceLaw.c

# --- CONFIGURACIÓN SERVER
SERVER_LIBS  := -lws2_32 -lmswsock -ladvapi32
SERVER_SRC   := src
SERVER_BUILD := build/server

# =============================================================================
# RECETAS
# =============================================================================

.PHONY: all
all: test

.PHONY: test
test: $(BUILD_DIR)/unity_test
	@echo "[INFO] Ejecutando tests..."
	@./$(BUILD_DIR)/unity_test

$(BUILD_DIR)/unity_test: $(OBJ_FILES) | $(BUILD_DIR)
	@echo "[LINK] $@"
	$(CC) $(CFLAGS) $(ALL_INC_FLAGS) $^ -o $@

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	@echo "[CC]   $<"
	$(CC) $(CFLAGS) $(ALL_INC_FLAGS) -c $< -o $@

$(BUILD_DIR):
	@mkdir -p $@

$(BUILD_DIR)/GuidanceLaw_sfcn.mexw64: $(MEX_WRAPPER) $(MEX_CDEPS) $(MEX_SCRIPT) | $(BUILD_DIR)
	@echo "[MEX]  GuidanceLaw_sfcn"
	$(MATLAB) -batch "run('$(MEX_SCRIPT)')"

$(BUILD_DIR)/HardSiL_sfcn.mexw64: $(MEX_DIR)/HardSiL_sfcn.c $(MEX_DIR)/build_hardSil.m | $(BUILD_DIR)
	@echo "[MEX]  HardSiL_sfcn"
	$(MATLAB) -batch "run('$(MEX_DIR)/build_hardSil.m')"

$(BUILD_DIR)/PiL_sfcn.mexw64: $(MEX_DIR)/PiL_sfcn.c $(MEX_DIR)/build_Pil.m | $(BUILD_DIR)
	@echo "[MEX]  PiL_sfcn"
	$(MATLAB) -batch "run('$(MEX_DIR)/build_PiL.m')"

.PHONY: server
server: $(SERVER_BUILD)/server

$(SERVER_BUILD):
	@mkdir -p $(SERVER_BUILD)

$(SERVER_BUILD)/server: $(SERVER_SRC)/l1_server.c | $(SERVER_BUILD)
	@echo "[INFO] Compilando servidor de pruebas"
	$(CC) $(CFLAGS) $^ -o $@ $(SERVER_LIBS)

.PHONY: mex
mex: $(MEX_TARGET)

.PHONY: clean
clean:
	@echo "[CLEAN] Eliminando $(BUILD_DIR)/"
	@rm -rf $(BUILD_DIR)

# Incluir dependencias automáticas generadas por -MMD
-include $(DEP_FILES)