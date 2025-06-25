#!/bin/bash

###
# This script run synchrobench c-cpp with different data structures
# and synchronization techniques as 'benchs' executables, with thread
# counts 'threads', inital structure sizes 'sizes', update ratio 'updates'
# sequential benchmarks 'seqbenchs', dequeue benchmarks 'deqbenchs' and
# outputs the throughput in separate log files
# '../log/${bench}-n${thread}-i${size}-u${upd}.${iter}.log'
#
# Select appropriate parameters below
#
threads="4"
benchs="
ESTM-hashtable lockfree-hashtable MUTEX-hashtable 
ESTM-skiplist lockfree-fraser-skiplist lockfree-rotating-skiplist lockfree-nohotspot-skiplist 
ESTM-linkedlist ESTM-rbtree"
# SPIN-skiplist is commented out as it is known to hang. Re-enable to test.

  #  * ESTM-linkedlist
  #  * ESTM-rbtree
  #  * ESTM-skiplist
  #  * 
  #  * MUTEX-linkedlist <- Does not exist when compiling with 'make'
  #  * MUTEX-skiplist <- takes longer than 20 seconds or doesn't run at all!

  #    sequential-linkedlist
  #  * sequential-rbtree
  #  * sequential-skiplist

seqbenchs="sequential-hashtable sequential-linkedlist sequential-rbtree sequential-skiplist"
iterations="1 2"
updates="10"
sizes="1024"
deqbenchs="" # Disabled as these were not found in the 'make' log. Re-enable if you build them.
###

# set a memory allocator here
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
echo "LD_PATH:" $LD_LIBRARY_PATH

# path to binaries
bin=../bin

if [ ! -d "../log" ]; then
  mkdir ../log
fi

# --- Added for clarity ---
echo "--- Starting Concurrent Benchmarks ---"

for size in ${sizes}
do
# make the range twice as large as initial size to maintain size expectation
r=`echo "2*${size}" | bc`
for upd in ${updates}
do
 for thread in ${threads}
 do
  for iter in ${iterations}
  do
   for bench in ${benchs}
   do
     log_file="../log/${bench}-n${thread}-i${size}-u${upd}.${iter}.log"
     echo "Running: ${bench} | Threads=${thread} | Size=${size} | Updates=${upd}% | Iteration=${iter}"

     # --- MODIFIED: Added timeout and status check ---
     timeout 20 ${bin}/${bench} -u ${upd} -i ${size} -r ${r} -d 5000 -t ${thread} -f 0 > ${log_file}
     status=$?
     if [ $status -eq 124 ]; then
        echo "  -> KILLED (Timeout after 20 seconds)"
        echo "TIMEOUT" >> ${log_file}
     elif [ $status -ne 0 ]; then
        echo "  -> FAILED (Exit code: $status)"
     fi
     # --- END MODIFICATION ---

   done
   echo "    -> Done with iteration ${iter} for T=${thread}, U=${upd}%"
   echo ""
  done
 done
done
done

# --- Added for clarity ---
echo "--- Starting Sequential Benchmarks ---"

# for sequential
for size in ${sizes}
do
r=`echo "2*${size}" | bc`
 for upd in ${updates}
 do
  for iter in ${iterations}
  do
   for bench in ${seqbenchs}
   do
     log_file="../log/${bench}-i${size}-u${upd}-sequential.${iter}.log"
     echo "Running: ${bench} | Size=${size} | Updates=${upd}% | Iteration=${iter}"

     # --- MODIFIED: Added timeout and status check ---
     timeout 20 ${bin}/${bench} -u ${upd} -i ${size} -r ${r} -d 5000 -t 1 -f 0 > ${log_file}
     status=$?
     if [ $status -eq 124 ]; then
        echo "  -> KILLED (Timeout after 20 seconds)"
        echo "TIMEOUT" >> ${log_file}
     elif [ $status -ne 0 ]; then
        echo "  -> FAILED (Exit code: $status)"
     fi
     # --- END MODIFICATION ---
   done
  done
 done
done

# for dequeue
if [ ! -z "$deqbenchs" ]; then
    # --- Added for clarity ---
    echo "--- Starting Dequeue Benchmarks ---"
    for upd in ${updates}
    do
     for thread in ${threads}
     do
      for iter in ${iterations}
      do
       for bench in ${deqbenchs}
       do
         log_file="../log/${bench}-n${thread}.${iter}.log"
         echo "Running: ${bench} | Threads=${thread} | Updates=${upd}% | Iteration=${iter}"

         # --- MODIFIED: Added timeout and status check ---
         timeout 20 ${bin}/${bench} -i 128 -r 256 -d 5000 -t ${thread} > ${log_file}
         status=$?
         if [ $status -eq 124 ]; then
            echo "  -> KILLED (Timeout after 20 seconds)"
            echo "TIMEOUT" >> ${log_file}
         elif [ $status -ne 0 ]; then
            echo "  -> FAILED (Exit code: $status)"
         fi
         # --- END MODIFICATION ---
       done
      done
     done
    done
fi

echo "--- All tests complete! ---"