
for f in `ls *.mobileprovision` 
do
 echo "Processing $f"

 for line in `awk 'NF>1{print $NF}' devices.txt`
 do
   `grep -q $line $f` || { echo "error $line not found"; exit 1; }    
 done
done

exit 0
