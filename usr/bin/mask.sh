#!/bin/bash
kworker=$(pwd)/gpelist.txt
echo "Check GPE..."
# Generates GPE list
grep enabled /sys/firmware/acpi/interrupts/* > $kworker
# Save in the variable $gpe the full address of the erroneous gpe
gpe=$(cat $kworker | egrep '[1-9][0-9][0-9][0-9]+ ' | sort -rnk 2 | head -n1 | cut -d":" -f1)
rm $kworker
if [ ! "$gpe" ]; then
   echo "No Kworker to Disable"
   echo Done
else
   echo "Send deactivation signal"
   echo "disable" > $gpe
   echo Done
fi
