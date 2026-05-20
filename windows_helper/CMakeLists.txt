cmake_minimum_required(VERSION 3.14)
project(auto_env_helper LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(auto_env_helper
  "main.cpp"
  "auto_env_helper.exe.manifest"
)

target_compile_definitions(auto_env_helper PRIVATE
  UNICODE
  _UNICODE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
)

if(MSVC)
  target_compile_options(auto_env_helper PRIVATE /W4 /EHsc /permissive-)
endif()

target_link_libraries(auto_env_helper PRIVATE shell32 rpcrt4)
