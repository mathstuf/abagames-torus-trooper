cmake_minimum_required(VERSION 2.8.12)
list(APPEND CMAKE_MODULE_PATH
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

project(torus-trooper D)

set(CMAKE_D_FLAGS
    "${CMAKE_D_FLAGS} -Wall")

option(TORUS_TROOPER_INSTALL "Whether to build an installable Torus Trooper or not" OFF)
if (TORUS_TROOPER_INSTALL)
    set(CMAKE_D_FLAGS
        "${CMAKE_D_FLAGS} ${CMAKE_D_VERSION_FLAG}TorusTrooperInstall")
endif ()

get_filename_component(CMAKE_SYSTEM_ROOT "${CMAKE_D_COMPILER}" DIRECTORY)
get_filename_component(CMAKE_SYSTEM_ROOT "${CMAKE_SYSTEM_ROOT}" DIRECTORY)

include_directories(SYSTEM "${CMAKE_SYSTEM_ROOT}/include/d")

add_subdirectory(src)
