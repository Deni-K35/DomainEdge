#!/bin/bash 
# Define Color Variables
# Format: Escape_Code[Style_Code;Foreground_Color_Codem
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
ORANGE='\e[38;5;208m'
BGreen='\033[1;32m'
MAGENTA='\e[1;35m'
NC='\e[0m' # No Color (Reset)


function APP_CHECK()
{
sudo updatedb
	echo "______________________________________________"
	for TOOL in masscan nmap 
	do 
	CHECK=$(command -v $TOOL)
	if [ -z "$CHECK" ] #-z acts as zero 
	then
	echo 'The following tool is not instualled:' $TOOL
	echo "_______________________________________"
	echo
	echo '${MAGENTA}----Start the installation----${NC}'
	echo
	echo "_______________________________________"
sudo apt-get install $TOOL &>/dev/null
	else
	echo 
	echo -e "${CYAN} - The following tool is instualled: ${NC}" $TOOL
	fi
	done 
}
APP_CHECK


function IPINSERT()
{
	echo
    echo "______________________________________________"
    echo
    echo -e "${MAGENTA}------- Welcome to Explanation servise -------${NC}"
    echo
    echo "----- Please enter an IP or Range to scan ----"
    echo
    read -r ADDRESS
    echo
    echo "--- A folder name is required to save data --- "
    echo
    read -r FOLDER

    #Create folder use -p so it doesn't error if exists.
    mkdir -p "$FOLDER" || { echo "Could not create folder '$FOLDER'"; return 1; }

    echo "Scanning $ADDRESS ..."
    
    #Output and exit status of nmap
    output=$(nmap "$ADDRESS" -sL 2>&1)
    status=$?

    #Save parsed IPs to the file.
    echo "$output" | grep report | awk '{print $NF}' > .iplist 2>/dev/null

    #Decide failure or success:
    #- if nmap returned non-zero -> command failed
    #- OR if produced an empty .iplist -> treat as failure (no addresses found)
if [ $status -ne 0 ]; then
        echo
        echo "The nmap command failed for '$ADDRESS' (exit code $status)."
        echo "nmap output:FAILED"
        echo "______________________________________________"
        sleep 2
        echo "----Please try again with a valid address.----"
        rm -f "$FOLDER $.iplist"
        IPINSERT   # recursion is OK for retry but be mindful of infinite loops
        return
elif [ ! -s ".iplist" ]; then
        # file missing or zero size
        echo
        echo "No IPs were found for '$ADDRESS' (output empty)."
        echo "nmap output:FAILED"
        echo "______________________________________________"
        echo
        sleep 2
        echo "Please try again with a valid IP address or range."
        rm -f "$FOLDER $.iplist"
        IPINSERT
        return
else
        echo
        echo -e "${CYAN}----------------------- Success!! the IP list is saved to .iplist ------------------------${NC}"
        echo "------------------------------------------------------------------------------------------"
fi
}

IPINSERT


function BASIC()
{
	#Folder criation for Nmap and Masscan
	mkdir $FOLDER/nmap
	mkdir $FOLDER/masscan
	
for ip in $(cat .iplist)
do
	nmap -F $ip --open -sV > $FOLDER/nmap/$ip
	#sudo masscan -pU:1-65535 $ip --rate=10000 > $FOLDER/masscan/$ip
done
}


function FULL()
{
	mkdir $FOLDER/nmap
	mkdir $FOLDER/masscan
	
for ip in $(cat .iplist)
do
	nmap $ip --open -sV --script=defaul,discovery,vuln > $FOLDER/nmap/$ip
	sudo masscan -pU:1-65535 $ip --rate=10000 > $FOLDER/masscan/$ip
done
}


function WEAKNESS()
{
	echo
	echo -e "Choose wihtch server to search for bf ${BGreen}rdp/telnet/ssh/ftp${NC}"
	echo
	read bfservice
	echo "The followig servers found with $bfservice open:"
	echo
for nmapfile in $(ls $FOLDER/nmap)
do
	cat $FOLDER/nmap/$nmapfile | grep -w $bfservice -B 100 | gerp -i report | awk '{print $NF}' | tee -a bftargets.txt
	#the tee command displays the results on the screen and inject to the file	
done

#Creating a User List
	echo
	read -p "- Press enter for Default -- USER -- list, press any other key to create your own:" bfchoose
	echo
if [ -z $bfchoose ]
then
	cat > bfusers.txt <<'EOF'
	admin
	malware
	guest
	root
	kali
	user
	techvoyager
	midnightwolf
	crimsonbyte
	silverhollow
	neonrider
EOF

else
	echo -e "${CYAN}Create your own, press CTRL+D when finished{NC}"
	cat > bfusers.txt
fi

#Creating a Password List
	echo
	read -p "- Press enter for Default -- PASSWORD -- list, press any other key to create your own:" bfchoose1
	echo
	echo
if [ -z $bfchoose1 ]
then
	cat > bfpass.txt <<'EOF'
	admin
	Passw0rd!
	root
	kali
	user
	Vq7$k9Pz*R2m
	32des
	hB8!xQ4w@L0s
	1234we
	1234
	9rT#fZ2uY6&d
	1
	Pm3^sW7e!K1q
	2
	
EOF

else
	echo -e "${CYAN}Create your own, press CTRL+D when finished${NC}"
	cat > bfpass.txt
fi
#After we got the SERVICE, the IP list, the USER list, the PASSWORD list, can prossed to Brute force
	echo
	echo -e "${CYAN}---------------------------- Starting Brute force using Hydra ----------------------------${NC}"
	echo
	hydra -L bfusers.txt -P bfpass.txt -M bftargets.txt $bfservice > $FOLDER/hydra-results

#option to add if statment to call the function again
}


function SERCHSPLOIT()
{
	cat $FOLDER/nmap/* | grep open | awk '{print $4,$5,$6}' | grep '\S'> .service-versions
	
for service in $(cat .service-versions)
do
#The Version of the service will be shown in the file
	echo " - Vulnerbabilities for $service - " >> $FOLDER/vuln-searchsploit
	echo "_________________________________________________________________________"
	echo
done
}


function REPORT()
{
	echo " - The main file gathered: "
	find $FOLDER -maxdepth 1 -type f #displays the main files (not the ones inside the nmap or masscan folders)
	echo " - The main directories gathered: "
	find $FOLDER -maxdepth 1 -type f | awk 'NR>1' #displys the folders created in the main folder.
	echo
	read -p " -------- Insert the IP you want to display results on: " IPRESULT
	echo
	cat $FOLDER/nmap/IPRESULT
}


function ZIP()
{
	#remove all the files that was created during the proses
	rm -f .iplist .service-versions bfusers.txt bfpass.txt bftargets.txt
	echo
	read -p " -------- Do you want to ZIP all the information? (y/n) " ZIP
	echo
if [ "$ZIP" == "y" ]
then
	zip -r "$FOLDER.zip" "$FOLDER" && rm -rf "$FOLDER" #after the zip created, remove the regular folder
	echo
	echo -e "${BGreen}------ Zipped!! and removed $FOLDER go check it out ------${NC}"
else
	echo
	echo -e "${BGreen}------------ NEVERMIND THE "$FOLDER" FOLDER IS READY ------------${NC}"
fi
}


function MAIN_MENU() 
{
	
	echo -e "${YELLOW}---------------- Choose the scan type - (B) for Basic - (F) for Full scan ----------------${NC}"
	echo
	read SCANCHOOSE
	
case $SCANCHOOSE in
	
	B) echo " - Basic scan has started - "
	BASIC
	WEAKNESS
	REPORT
	ZIP
	;;
	F) echo " - Full scan has started - "
	FULL
	WEAKNESS
	REPORT
	SEARCHSPLOIT
	ZIP
	;;
	*) echo "ERORR! TRY AGINE"
	sleep 2
	MAIN MENU
	;;
esac
}
MAIN_MENU

