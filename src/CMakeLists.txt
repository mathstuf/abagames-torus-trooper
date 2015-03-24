set(gl_impl opengl3)
if (TORUS_TROOPER_ANDROID)
    set(gl_impl gles)
endif ()

find_package(bulletml REQUIRED)
find_package(GL3N REQUIRED)
find_package(Derelict REQUIRED
    COMPONENTS
        ${gl_impl}
        sdl2
        util)
include_directories(SYSTEM "${BULLETML_INCLUDE_DIR}")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")
include_directories("${CMAKE_CURRENT_BINARY_DIR}")
add_subdirectory(abagames)
