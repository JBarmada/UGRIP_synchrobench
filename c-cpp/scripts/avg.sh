#!/bin/bash

###
# This script computes the average throughput and other metrics
# from the log files and generates a CSV file in ../data/
#
# Set the parameters of your choice below:
#
#size="1024 4096 8192 16384 32768 65536"
size="1024"
#threads="1 4 8 12 16 20 24 28 32"
threads="4"
#updates="0 100"
updates="10"
#iterations="1 2 3 4 5 6 7 8 9 10"
iterations="1 2"

# --- MODIFIED: Added all your concurrent benchmarks here ---
benchs="
ESTM-hashtable lockfree-hashtable MUTEX-hashtable 
ESTM-skiplist lockfree-fraser-skiplist lockfree-rotating-skiplist lockfree-nohotspot-skiplist 
ESTM-linkedlist ESTM-rbtree"
# Add this back when you have fixed it: SPIN-skiplist

# --- MODIFIED: Defined sequential benchmarks separately ---
seqbenchs="sequential-hashtable sequential-linkedlist sequential-rbtree sequential-skiplist"

suffix="synchrobench-results-all"
###

if [ ! -d "../data" ]; then
        mkdir ../data
fi

echo "--- Processing Log Files and Calculating Averages ---"
echo ""

# The output file will be a CSV
file=../data/${suffix}.csv

# Create the CSV header. This will be written to the file only once.
printf "Benchmark,Threads,InitialSize,UpdateRate,AvgThroughput_Kops_s,AvgAborts\n" > $file

# === Main loop for CONCURRENT benchmarks ===
echo "--- Processing Concurrent Benchmarks ---"
for s in ${size}
do
for upd in ${updates}
do
for thread in ${threads}
do
  echo "--- Configuration: Threads=${thread}, Size=${s}, Updates=${upd}% ---"
  for bench in ${benchs}
  do
    cpt=0
    total_thgt=0
    total_aborts=0
    for iter in ${iterations}
    do
      log_file="../log/${bench}-n${thread}-i${s}-u${upd}.${iter}.log"
      if [ -f "$log_file" ]; then
          read -r thgt aborts <<< $(awk '/#txs/ {thgt=substr($4, 2)} /#aborts/ {aborts=$3} END {print thgt, aborts}' "$log_file")
          if [ -n "$thgt" ] && [ -n "$aborts" ]; then
              total_thgt=$(echo "scale=3; ${thgt} + ${total_thgt}" | bc)
              total_aborts=$(echo "scale=3; ${aborts} + ${total_aborts}" | bc)
              cpt=$(echo "${cpt} + 1" | bc)
          fi
      else
          echo "  WARNING: Log file not found: ${log_file}"
      fi
    done

    if [ "$cpt" -gt 0 ]; then
        avg_thgt=$(echo "scale=3; ${total_thgt}/${cpt}" | bc)
        avg_aborts=$(echo "scale=1; ${total_aborts}/${cpt}" | bc)
        avg_Kthgt=$(echo "scale=3; ${avg_thgt}/1000" | bc)
        is_zero=$(echo "${avg_aborts} == 0" | bc); if [ "$is_zero" -eq 1 ]; then display_aborts=""; else display_aborts=${avg_aborts}; fi
        printf "%s,%s,%s,%s,%s,%s\n" "${bench}" "${thread}" "${s}" "${upd}" "${avg_Kthgt}" "${display_aborts}" >> ${file}
    fi
  done
  echo ""
done
done
done

# === Main loop for SEQUENTIAL benchmarks ===
echo "--- Processing Sequential Benchmarks ---"
for s in ${size}
do
for upd in ${updates}
do
  # Thread count is always 1 for sequential
  thread=1
  echo "--- Configuration: Threads=1, Size=${s}, Updates=${upd}% ---"
  for bench in ${seqbenchs}
  do
    cpt=0
    total_thgt=0
    total_aborts=0
    for iter in ${iterations}
    do
      # --- MODIFIED: Using the correct filename pattern for sequential logs ---
      log_file="../log/${bench}-i${s}-u${upd}-sequential.${iter}.log"
      if [ -f "$log_file" ]; then
          read -r thgt aborts <<< $(awk '/#txs/ {thgt=substr($4, 2)} /#aborts/ {aborts=$3} END {print thgt, aborts}' "$log_file")
          if [ -n "$thgt" ] && [ -n "$aborts" ]; then
              total_thgt=$(echo "scale=3; ${thgt} + ${total_thgt}" | bc)
              total_aborts=$(echo "scale=3; ${aborts} + ${total_aborts}" | bc)
              cpt=$(echo "${cpt} + 1" | bc)
          fi
      else
          echo "  WARNING: Log file not found: ${log_file}"
      fi
    done

    if [ "$cpt" -gt 0 ]; then
        avg_thgt=$(echo "scale=3; ${total_thgt}/${cpt}" | bc)
        avg_aborts=$(echo "scale=1; ${total_aborts}/${cpt}" | bc)
        avg_Kthgt=$(echo "scale=3; ${avg_thgt}/1000" | bc)
        is_zero=$(echo "${avg_aborts} == 0" | bc); if [ "$is_zero" -eq 1 ]; then display_aborts=""; else display_aborts=${avg_aborts}; fi
        printf "%s,%s,%s,%s,%s,%s\n" "${bench}" "${thread}" "${s}" "${upd}" "${avg_Kthgt}" "${display_aborts}" >> ${file}
    fi
  done
  echo ""
done
done


echo "--- Processing Complete ---"
echo "Results saved to ${file}"
echo ""
echo "--- Final Data ---"
cat ${file}