#!/bin/bash

USER=dcorvino_hpc

echo -e "=== COLOR KEY ==="
echo -e "\033[32mGREEN\033[0m: Good usage (CPU ≥70% and RAM ≤80%)"
echo -e "\033[33mYELLOW\033[0m: Moderate (CPU 50–70% or RAM 80–90%)"
echo -e "\033[31mRED\033[0m: Concerning (CPU <50% or RAM >90%)"
echo ""

echo "=== SLURM Queue for $USER ==="
printf "%-10s %-12s %-20s %-12s %-4s %-10s %-6s %-15s\n" JobID Partition JobName User St Elapsed Nodes NodeList
squeue -u $USER --noheader -o "%i %P %j %u %t %M %D %R" \
 | awk '{printf "%-10s %-12s %-20s %-12s %-4s %-10s %-6s %-15s\n", $1,$2,$3,$4,$5,$6,$7,$8}'

echo ""
echo "=== Requested Resources per Job ==="
printf "%-10s %-6s %-10s %-12s %-10s %-10s\n" JobID Cores Memory Partition Node Elapsed
for JOBID in $(squeue -u $USER -h -o "%i"); do
    CORES=$(squeue -j $JOBID -h -o "%C")
    MEM=$(squeue -j $JOBID -h -o "%m")
    PARTITION=$(squeue -j $JOBID -h -o "%P")
    NODE=$(squeue -j $JOBID -h -o "%N")
    ELAPSED=$(squeue -j $JOBID -h -o "%M")
    printf "%-10s %-6s %-10s %-12s %-10s %-10s\n" $JOBID $CORES $MEM $PARTITION $NODE $ELAPSED
done

echo ""
echo "=== Resource Usage per Job ==="
printf "%-10s %-8s %-10s %-10s %-10s %-12s %-12s\n" "JobID" "CPUUtil" "AveRAM(GB)" "MaxRAM(GB)" "ReqRAM(GB)" "AveRAMUtil" "MaxRAMUtil"
for JOBID in $(squeue -u $USER -h -o "%i"); do
    ELAPSED=$(squeue -j $JOBID -h -o "%M")
    CORES=$(squeue -j $JOBID -h -o "%C")
    REQMEM_GB=$(squeue -j $JOBID -h -o "%m" | sed "s/[^0-9]//g")
    if [ -z "$REQMEM_GB" ]; then REQMEM_GB=0; fi
    sstat -j ${JOBID}.batch --noheader --format=JobID,AveCPU,AveRSS,MaxRSS \
    | awk -v jobid=$JOBID -v cores=$CORES -v elapsed=$ELAPSED -v reqmem=$REQMEM_GB '
        {
            split($2, t, ":")
            cpu_sec = t[1]*3600 + t[2]*60 + t[3]
            split(elapsed, e, ":")
            if(length(e)==3) elapsed_sec = e[1]*3600 + e[2]*60 + e[3]
            else elapsed_sec = e[1]*60 + e[2]
            util = (elapsed_sec > 0 && cores > 0) ? (cpu_sec / (elapsed_sec*cores)) * 100 : 0
            averam = $3/1024/1024
            maxram = $4/1024/1024
            aveutil = (reqmem > 0) ? (averam/reqmem)*100 : 0
            maxutil = (reqmem > 0) ? (maxram/reqmem)*100 : 0

            color = "\033[32m"  # GREEN default
            if(util < 50 || maxutil > 90) color = "\033[31m"  # RED
            else if(util < 70 || maxutil > 80) color = "\033[33m"  # YELLOW

            printf "%s%-10s %-8.1f %-10.1f %-10.1f %-10d %-12.1f %-12.1f\033[0m\n",
                   color, jobid, util, averam, maxram, reqmem, aveutil, maxutil
        }'
done
