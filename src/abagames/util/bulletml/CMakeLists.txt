set(util_bulletml_srcs
    bullet.d
    bulletsmanager.d)

add_library(tt_util_bulletml STATIC
    ${util_bulletml_srcs})
target_link_libraries(tt_util_bulletml
    tt_util
    BulletML::bulletml)
set_target_properties(tt_util_bulletml
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
