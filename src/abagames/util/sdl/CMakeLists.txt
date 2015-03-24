set(util_sdl_srcs
    displaylist.d
    gamemanager.d
    input.d
    luminous.d
    mainloop.d
    pad.d
    recordablepad.d
    screen.d
    screen3d.d
    sdlexception.d
    shaderprogram.d
    sound.d
    texture.d)

add_library(tt_util_sdl STATIC
    ${util_sdl_srcs})
target_link_libraries(tt_util_sdl
    tt_util
    Derelict::opengl3
    Derelict::sdl2
    Derelict::util)
set_target_properties(tt_util_sdl
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
