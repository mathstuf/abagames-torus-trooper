set(util_srcs
    actor.d
    logger.d
    math.d
    prefmanager.d
    rand.d
    tokenizer.d)

add_library(tt_util STATIC
    ${util_srcs})
target_link_libraries(tt_util
    LINK_PUBLIC
        gl3n)
set_target_properties(tt_util
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

add_subdirectory(support)
add_subdirectory(bulletml)
add_subdirectory(sdl)
