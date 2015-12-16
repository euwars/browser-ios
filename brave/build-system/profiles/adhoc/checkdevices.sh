[[ -e ~/.brave-apple-login ]] && source ~/.brave-apple-login

ios devices:list --team 9Y996D6DTQ $USER $PASS > /tmp/devices.txt

lines=`awk 'NF>3{print $(NF-3)}' /tmp/devices.txt | egrep -v 'Listing|Identifier'`

for f in `ls *.mobileprovision` 
do
 echo "Processing $f"

 for line in $lines
 do
   `grep -q $line $f` || { echo "error $line not found"; exit 1; }    
 done
done

exit 0
