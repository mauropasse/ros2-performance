#!/bin/bash
# scp -P 2222 -r root@192.168.1.113:/data/ros2-application-qcs40x-2024_04_02/irobot_benchmark/all_results .

# Set governor to performance
echo "echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
echo performance > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor

# Get the directory where the script is located
script_dir=$(dirname "$(readlink -f "$0")")
irobot_benchmark="${script_dir}/../../irobot_benchmark"
topologies_dir="${script_dir}/../topologies"
profiles_dir="${script_dir}/../profiles"

# Create a directory to store log folders
MP="${PWD}/results_multi_process"
rm -rf $MP && mkdir -p $MP

# Define message sizes and communication types
# comms=("ipc_off" "loaned_fastdds" "loaned_cyclone")
comms=("ipc_off_fast" "ipc_off_cyclone" "ipc_off_zenoh")

# Define topologies pairs
results=("10b" "100kb" "1mb" "4mb")
topology1=("pub_10b" "pub_100kb" "pub_1mb" "pub_4mb")
topology2=("sub_10b" "sub_100kb" "sub_1mb" "sub_4mb")


# Check if rmw_zenohd is running
if pgrep -x "rmw_zenohd" > /dev/null
then
    echo "rmw_zenohd is running."
else
    echo "rmw_zenohd is NOT running. Run as: ros2 run rmw_zenoh_cpp rmw_zenohd"
    exit 1
fi

# Check if iox-roudi is running
if pgrep -x "iox-roudi" > /dev/null
then
    echo "iox-roudi is running."
else
    echo "iox-roudi is NOT running. Run as: ./iox-roudi -c roudi_config.toml"
    # exit 1
fi


# Loop through each index in the topology1 array
for i in "${!topology1[@]}"; do
    t1=${topology1[i]}
    t2=${topology2[i]}
    res=${results[i]}

    for comm in "${comms[@]}"; do
        mkdir -p $MP/${res}/${comm}

        # Set environment variables for "loaned" communication type
        export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

        case "$comm" in
            ipc_off_cyclone)
                export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
                ;;
            ipc_off_zenoh)
                export RMW_IMPLEMENTATION=rmw_zenoh_cpp
                ;;
            loaned_fastdds)
                export FASTRTPS_DEFAULT_PROFILES_FILE="${profiles_dir}/shared_memory_fastdds_preallocated_w_realloc.xml"
                export RMW_FASTRTPS_USE_QOS_FROM_XML=1
                ;;
            loaned_cyclone)
                export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
                export CYCLONEDDS_URI="${profiles_dir}/zero-copy-shm.xml"
                ;;
        esac


        # Topology
        if [[ "$comm" == "loaned_fastdds" || "$comm" == "loaned_cyclone" ]]; then
            top="${topologies_dir}/${t1}_loaned.json"
        else
            top="${topologies_dir}/${t1}.json"
        fi

        debug_topology="${topologies_dir}/${t2}.json"

        # Results folder

        # Run the command
        COMMAND="${irobot_benchmark} $top $debug_topology -x 3 --ipc off -t 10 -s 1000 --csv-out on"
        echo -e "\nCommand: \n$COMMAND\n"
        eval $COMMAND

        # Move log folders
        mv *log $MP/${res}/${comm}

        # Unset environment variables after running "loaned" command
        if [[ "$comm" == "loaned_fastdds" || "$comm" == "loaned_cyclone" ]]; then
            unset FASTRTPS_DEFAULT_PROFILES_FILE
            unset RMW_FASTRTPS_USE_QOS_FROM_XML
        fi
    done
done
