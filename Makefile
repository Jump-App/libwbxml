PRIV_DIR := $(MIX_APP_PATH)/priv
TARGET_NAME := wbxml_nif
TARGET_EXT := so
TARGET_TRIPLET := $(if $(CC_PRECOMPILER_CURRENT_TARGET),$(CC_PRECOMPILER_CURRENT_TARGET),host)
BUILD_DIR := $(CURDIR)/_build/native/$(MIX_ENV)/$(TARGET_TRIPLET)
OBJ_DIR := $(BUILD_DIR)/obj
TARGET_PATH := $(PRIV_DIR)/$(TARGET_NAME).$(TARGET_EXT)
ERTS_INCLUDE_DIR ?= $(ERL_INCLUDE_DIR)
EXPAT_CFLAGS ?= $(shell pkg-config --cflags expat 2>/dev/null)
EXPAT_LIBS ?= $(or $(shell pkg-config --libs expat 2>/dev/null),-lexpat)

WBXML_SOURCES := \
	vendor/libwbxml/src/wbxml_base64.c \
	vendor/libwbxml/src/wbxml_buffers.c \
	vendor/libwbxml/src/wbxml_charset.c \
	vendor/libwbxml/src/wbxml_conv.c \
	vendor/libwbxml/src/wbxml_elt.c \
	vendor/libwbxml/src/wbxml_encoder.c \
	vendor/libwbxml/src/wbxml_errors.c \
	vendor/libwbxml/src/wbxml_lists.c \
	vendor/libwbxml/src/wbxml_log.c \
	vendor/libwbxml/src/wbxml_mem.c \
	vendor/libwbxml/src/wbxml_parser.c \
	vendor/libwbxml/src/wbxml_tables.c \
	vendor/libwbxml/src/wbxml_tree.c \
	vendor/libwbxml/src/wbxml_tree_clb_wbxml.c \
	vendor/libwbxml/src/wbxml_tree_clb_xml.c

NIF_SOURCE := native/wbxml_nif.c
SOURCES := $(WBXML_SOURCES) $(NIF_SOURCE)
OBJECTS := $(patsubst %.c,$(OBJ_DIR)/%.o,$(SOURCES))

CPPFLAGS += -Inative -Ivendor/libwbxml/src -I$(ERTS_INCLUDE_DIR) $(EXPAT_CFLAGS)
CFLAGS ?= -O2 -fPIC

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
	LDFLAGS += -dynamiclib -undefined dynamic_lookup
else
	LDFLAGS += -shared
endif

all: $(TARGET_PATH)

$(TARGET_PATH): $(OBJECTS)
	@mkdir -p "$(PRIV_DIR)"
	$(CC) $(OBJECTS) $(LDFLAGS) $(EXPAT_LIBS) -o "$@"

$(OBJ_DIR)/%.o: %.c
	@if [ -z "$(ERTS_INCLUDE_DIR)" ]; then echo "ERTS_INCLUDE_DIR or ERL_INCLUDE_DIR must be set"; exit 1; fi
	@mkdir -p "$(dir $@)"
	$(CC) $(CPPFLAGS) $(CFLAGS) -c "$<" -o "$@"

clean:
	rm -rf "$(CURDIR)/_build/native"
	rm -f "$(PRIV_DIR)/$(TARGET_NAME).so" "$(PRIV_DIR)/$(TARGET_NAME).dylib"
