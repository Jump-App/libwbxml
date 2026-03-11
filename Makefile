PRIV_DIR := $(MIX_APP_PATH)/priv
NIF_EXT := so
NIF_PATH := $(PRIV_DIR)/wbxml_nif.$(NIF_EXT)
BUILD_DIR := $(CURDIR)/_build/native/$(MIX_ENV)
SOURCE_DIR := $(CURDIR)/native
BUILD_FILES := $(BUILD_DIR)/CMakeCache.txt $(BUILD_DIR)/Makefile

all: $(NIF_PATH)
	@ echo > /dev/null

$(NIF_PATH): $(BUILD_FILES) $(SOURCE_DIR)/CMakeLists.txt $(SOURCE_DIR)/wbxml_nif.c $(SOURCE_DIR)/wbxml_config.h $(SOURCE_DIR)/wbxml_config_internals.h
	cmake --build "$(BUILD_DIR)" --target wbxml_nif

$(BUILD_DIR)/CMakeCache.txt $(BUILD_DIR)/Makefile: $(SOURCE_DIR)/CMakeLists.txt $(SOURCE_DIR)/wbxml_nif.c $(SOURCE_DIR)/wbxml_config.h $(SOURCE_DIR)/wbxml_config_internals.h
	mkdir -p "$(BUILD_DIR)"
	cmake -S "$(SOURCE_DIR)" -B "$(BUILD_DIR)"

clean:
	rm -rf "$(BUILD_DIR)"
	rm -f "$(PRIV_DIR)/wbxml_nif.so" "$(PRIV_DIR)/libwbxml2_static.a"
