cmake_minimum_required(VERSION 3.13)

project({{PROJECT_NAME}}
	LANGUAGES CXX
)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake/modules")

add_executable({{PROJECT_NAME}}
	src/{{PROJECT_NAME}}.cpp
)
target_compile_features({{PROJECT_NAME}}
	PRIVATE
		cxx_std_17
)
target_include_directories({{PROJECT_NAME}}
	PRIVATE
		include
)
target_link_libraries({{PROJECT_NAME}}
	PRIVATE
		# STUB
)
