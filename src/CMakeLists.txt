find_package(bulletml REQUIRED)
find_package(GL3N REQUIRED)
find_package(Derelict REQUIRED
    COMPONENTS
        opengl3
        sdl2
        util)
include_directories(SYSTEM "${BULLETML_INCLUDE_DIR}")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")
include_directories("${CMAKE_CURRENT_BINARY_DIR}")
add_subdirectory(abagames)
