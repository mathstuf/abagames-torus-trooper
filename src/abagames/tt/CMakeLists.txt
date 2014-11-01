set(tt_srcs
    barrage.d
    bulletactor.d
    bulletactorpool.d
    bulletimpl.d
    bullettarget.d
    camera.d
    enemy.d
    floatletter.d
    gamemanager.d
    letter.d
    particle.d
    prefmanager.d
    replay.d
    screen.d
    shape.d
    ship.d
    shot.d
    soundmanager.d
    stagemanager.d
    title.d
    tunnel.d)

add_library(tt STATIC
    ${tt_srcs})
target_link_libraries(tt
    tt_util
    tt_util_bulletml
    tt_util_sdl
    Derelict::opengl3
    Derelict::sdl2
    Derelict::util)
set_target_properties(tt
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

add_executable(torus-trooper
    boot.d)
target_link_libraries(torus-trooper
    tt
    tt_util
    tt_util_bulletml
    tt_util_sdl)
set_target_properties(torus-trooper
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
