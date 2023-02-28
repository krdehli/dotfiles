cmake_minimum_required(VERSION 3.21)

#find_package(Catch2 CONFIG REQUIRED)

add_executable(tests test.cpp)
target_include_directories(tests
	PRIVATE
		# STUB
)
target_link_libraries(tests
	PRIVATE
		# Catch2::Catch2WithMain
)

#include(Catch)
#catch_discover_tests(tests)