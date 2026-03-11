cmake_minimum_required(VERSION 3.15)

# -----------------------------------------------------------------------------
# Top-level CMake configuration that
#   * Fetches and builds the libwbxml static library (unless SKIP_WBXML=ON)
#   * Builds the wbxml_nif shared library used by the Elixir wrapper
# -----------------------------------------------------------------------------

project(libwbxml_elixir_nif LANGUAGES C)


# Force CMake to re-configure when this script changes by copying a stamp file
# into the build directory.
configure_file(${CMAKE_CURRENT_LIST_FILE} ${CMAKE_BINARY_DIR}/libwbxml_elixir_stamp COPYONLY)

# Set output directory for built artifacts
set(PRIV_DIR "$ENV{MIX_APP_PATH}/priv")
if(NOT DEFINED ENV{MIX_APP_PATH})
  set(PRIV_DIR "${CMAKE_BINARY_DIR}/priv")
endif()

file(MAKE_DIRECTORY ${PRIV_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PRIV_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PRIV_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PRIV_DIR})

# Check if we should skip building libwbxml and use system version instead
set(SKIP_WBXML OFF)
if(DEFINED ENV{SKIP_WBXML} AND NOT "$ENV{SKIP_WBXML}" STREQUAL "0")
  set(SKIP_WBXML ON)
endif()

# Position-independent code is required so that the static archive can be
# linked into the shared NIF on Linux.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# -----------------------------------------------------------------------------
# Erlang/OTP includes
# -----------------------------------------------------------------------------

# elixir_cmake injects ERTS_INCLUDE_DIR into the environment.  Fall back to a
# user-provided ERL_INCLUDE_DIR for forward-compatibility.

if(DEFINED ENV{ERL_INCLUDE_DIR})
  set(ERLANG_INCLUDE_DIR $ENV{ERL_INCLUDE_DIR})
else()
  set(ERLANG_INCLUDE_DIR $ENV{ERTS_INCLUDE_DIR})
endif()

if(NOT ERLANG_INCLUDE_DIR)
  message(FATAL_ERROR "Could not determine Erlang include directory - set ERL_INCLUDE_DIR or rely on elixir_cmake's defaults.")
endif()

include_directories(SYSTEM ${ERLANG_INCLUDE_DIR})

# -----------------------------------------------------------------------------
# Fetch & build libwbxml unless the caller opted to skip it
# -----------------------------------------------------------------------------

if(NOT SKIP_WBXML)
  # CMake 4.2's FetchContent expects Git_VERSION to already be populated.
  find_package(Git REQUIRED)
  include(FetchContent)

  # Fetch libwbxml source code
  FetchContent_Declare(
    libwbxml
    GIT_REPOSITORY https://github.com/libwbxml/libwbxml.git
    GIT_TAG master
  )

  # Suppress deprecation warning for FetchContent_Populate since we manually build libwbxml
  if(POLICY CMP0169)
    cmake_policy(SET CMP0169 OLD)
  endif()
  FetchContent_Populate(libwbxml)

  # Copy config header files to build directory
  file(COPY "${CMAKE_CURRENT_LIST_DIR}/wbxml_config.h" DESTINATION "${CMAKE_BINARY_DIR}")
  file(COPY "${CMAKE_CURRENT_LIST_DIR}/wbxml_config_internals.h" DESTINATION "${CMAKE_BINARY_DIR}")

  # Build libwbxml static library ourselves (simpler than using their complex build system)
  set(LIBWBXML_SOURCES
    ${libwbxml_SOURCE_DIR}/src/wbxml_base64.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_buffers.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_charset.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_conv.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_elt.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_encoder.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_errors.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_lists.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_log.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_mem.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_parser.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_tables.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_tree.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_tree_clb_wbxml.c
    ${libwbxml_SOURCE_DIR}/src/wbxml_tree_clb_xml.c
  )

  add_library(wbxml2_static STATIC ${LIBWBXML_SOURCES})
  target_include_directories(wbxml2_static PUBLIC ${libwbxml_SOURCE_DIR}/src ${CMAKE_BINARY_DIR})

  # Set up variables for linking
  set(WBXML_TARGET wbxml2_static)
  set(LIBWBXML_PUBLIC_INCLUDES ${libwbxml_SOURCE_DIR}/src ${CMAKE_BINARY_DIR})
endif()

# -----------------------------------------------------------------------------
# Find Expat and build the NIF shared library
# -----------------------------------------------------------------------------

find_package(EXPAT REQUIRED)

add_library(wbxml_nif SHARED "${CMAKE_CURRENT_LIST_DIR}/wbxml_nif.c")
set_target_properties(wbxml_nif PROPERTIES PREFIX "" OUTPUT_NAME "wbxml_nif")

# Set appropriate shared library suffix for each platform
if(WIN32)
  set_target_properties(wbxml_nif PROPERTIES SUFFIX ".dll")
elseif(APPLE)
  set_target_properties(wbxml_nif PROPERTIES SUFFIX ".so")
else()
  set_target_properties(wbxml_nif PROPERTIES SUFFIX ".so")
endif()

# Link against libwbxml (either built or system) and Expat
if(NOT SKIP_WBXML)
  target_link_libraries(wbxml_nif PRIVATE ${WBXML_TARGET} ${EXPAT_LIBRARIES})
  target_include_directories(wbxml_nif PRIVATE ${LIBWBXML_PUBLIC_INCLUDES})
  # Link libwbxml2 against Expat too
  target_link_libraries(wbxml2_static PRIVATE ${EXPAT_LIBRARIES})
else()
  find_library(WBXML2_LIB NAMES wbxml2 REQUIRED)
  target_link_libraries(wbxml_nif PRIVATE ${WBXML2_LIB} ${EXPAT_LIBRARIES})

  # Try common system include paths for libwbxml
  find_path(WBXML_INCLUDE_DIR wbxml.h
    PATHS
      /usr/include/libwbxml-1.1/wbxml
      /usr/local/include/libwbxml-1.1/wbxml
      /opt/local/include/libwbxml-1.1/wbxml
    NO_DEFAULT_PATH
  )
  if(WBXML_INCLUDE_DIR)
    target_include_directories(wbxml_nif PRIVATE ${WBXML_INCLUDE_DIR})
  else()
    message(WARNING "Could not find system libwbxml headers - compilation may fail")
  endif()
endif()

# Platform-specific linker options for NIFs
if(APPLE)
  # macOS: Allow unresolved Erlang NIF symbols to be resolved at runtime
  target_link_options(wbxml_nif PRIVATE "-undefined" "dynamic_lookup")
elseif(UNIX AND NOT APPLE)
  # Linux: For NIFs, we need to allow undefined symbols since they're provided by the Erlang runtime
  # Remove the --no-undefined flag and ensure shared library behavior
  set_target_properties(wbxml_nif PROPERTIES
    LINK_FLAGS "-shared"
    POSITION_INDEPENDENT_CODE ON
  )
endif()
