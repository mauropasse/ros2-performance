cmake_minimum_required(VERSION 3.5)
project(irobot_benchmark)

# Default to C++14
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 14)
endif()

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wpedantic")
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)
find_package(performance_test REQUIRED)
find_package(performance_test_factory REQUIRED)
find_package(libyaml_vendor REQUIRED)
find_package(rcl_yaml_param_parser REQUIRED)
find_package(yaml REQUIRED)
ament_export_dependencies(rcl_yaml_param_parser)

add_executable(irobot_benchmark src/irobot_benchmark.cpp)
ament_target_dependencies(irobot_benchmark rclcpp rclcpp_lifecycle performance_test performance_test_factory yaml)

install(TARGETS
  irobot_benchmark
  DESTINATION lib/${PROJECT_NAME}
)

set(TOPOLOGY_FILES
  topology/sierra_nevada.json
  topology/cedar.json
  topology/mont_blanc.json
  topology/white_mountain.json
  topology/debug_sierra_nevada_reliable.json
  topology/debug_sierra_nevada_best_effort.json
  topology/debug_mont_blanc_reliable.json
  topology/debug_mont_blanc_best_effort.json
)

install(FILES
  ${TOPOLOGY_FILES}
  DESTINATION lib/${PROJECT_NAME}/topology)

set(SCRIPTS
  scripts/compare_latency.py
  scripts/plot_latency.py
  scripts/plot_cpu_memory.py
)

install(FILES
  ${SCRIPTS}
  DESTINATION lib/${PROJECT_NAME}/scripts)

# Communications benchamrk
set(SP comms_benchmark/topologies)

set(SP_TEST_TOPOLOGY_FILES
  # Full topologies
  ${SP}/sierra_nevada.json
  ${SP}/sierra_nevada_fixed_size.json
  ${SP}/sierra_nevada_fixed_size_loaned.json
  ${SP}/white_mountain.json
  ${SP}/white_mountain_fixed_size.json
  ${SP}/white_mountain_fixed_size_loaned.json

  # Simple pub / sub
  ${SP}/pub_sub_10b.json
  ${SP}/pub_sub_100kb.json
  ${SP}/pub_sub_1mb.json
  ${SP}/pub_sub_4mb.json

  # Publishers loaning messages
  ${SP}/pub_sub_10b_loaned.json
  ${SP}/pub_sub_100kb_loaned.json
  ${SP}/pub_sub_1mb_loaned.json
  ${SP}/pub_sub_4mb_loaned.json

  # Full topologies (remove the ones not needed)
  ${SP}/debug_sierra_nevada_fixed_size.json
  ${SP}/debug_white_mountain_fixed_size.json

  # Simple pub / sub
  ${SP}/pub_100kb.json
  ${SP}/pub_100kb_loaned.json
  ${SP}/pub_10b.json
  ${SP}/pub_10b_loaned.json
  ${SP}/pub_1mb.json
  ${SP}/pub_1mb_loaned.json
  ${SP}/pub_4mb.json
  ${SP}/pub_4mb_loaned.json
  ${SP}/sub_100kb.json
  ${SP}/sub_10b.json
  ${SP}/sub_1mb.json
  ${SP}/sub_4mb.json
)

install(FILES
  ${SP_TEST_TOPOLOGY_FILES}
  DESTINATION lib/${PROJECT_NAME}/${SP})

set(PROFILES
  comms_benchmark/profiles/ignore_local_endpoints.xml
  comms_benchmark/profiles/shared_memory_fastdds_preallocated_w_realloc.xml
  comms_benchmark/profiles/shared_memory_fastdds_dynamic_reusable.xml
  comms_benchmark/profiles/zero-copy-shm.xml
  comms_benchmark/profiles/roudi_config.toml
)

install(FILES
  ${PROFILES}
  DESTINATION lib/${PROJECT_NAME}/comms_benchmark/profiles)

set(COMMS_BENCHMARK_SCRIPTS
  comms_benchmark/scripts/run_single_process_benchmarks.sh
  comms_benchmark/scripts/run_multi_process_benchmarks.sh
  comms_benchmark/scripts/run_mix_process_benchmarks.sh
  comms_benchmark/scripts/parse_averages_single_process.py
  comms_benchmark/scripts/parse_latency_single_process.py
  comms_benchmark/scripts/parse_latency_multi_process.py
  comms_benchmark/scripts/parse_averages_multi_process.py
  comms_benchmark/scripts/split_latency_all.py
)

install(FILES
  ${COMMS_BENCHMARK_SCRIPTS}
  DESTINATION lib/${PROJECT_NAME}/comms_benchmark/scripts)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package()

