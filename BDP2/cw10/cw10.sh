#!/bin/bash

# Autor 290913
# Data utworzenia 24.01.2021

# Parametry programu 
# 1 - numer indeksu
# 2 - link do pliku zip 
# 3 - has³o do pliku zip
# 4 - iloœæ kolumn w pliku wejœciowym
# 5 - maksymalna wartoœæ kolumny OrderQuantity
# 6 - lokalizacja pliku InternetSales_old.txt
# 7 - nazwa bazy danych
# 8 - has³o do bazy danych
# 9 - hostname

# Uruchomienie: 
# bash cw10.sh <numer indeksu> <link do pliku zip> <has³o do pliku> <iloœæ kolumn> <max OrderQuantity> <lokalizacja InternetSales_old.txt> <nazwa bazy danych> <has³o bazy danych> <host>

# Stworzenie pliku z logami
mkdir PROCESSED
TIMESTAMP=$(date '+%d%m%Y')
logFileName="$0_$TIMESTAMP.log"
touch PROCESSED/$log_filename

# Pobranie pliku z linku
#-------------------------------------
wget $2
EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
 	echo "$TIME : Downloading error" >> PROCESSED/"$logFileName"
	exit 1
else
 	echo "$TIME : Downloading succesful" >> PROCESSED/"$logFileName"
fi


# Rozpakowanie pliku zip
#------------------------------------

fileName=$(basename $2)
password=$3
unzip -P $password $fileName

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
        echo "$TIME : Unzip error" >> PROCESSED/"$logFileName"
        exit 1
else
        echo "$TIME : Unzip success" >> PROCESSED/"$logFileName"
fi

# Sprawdzenie poprawnoœci pliku 
#------------------------------

fileName=$(basename $fileName .zip)
fileNameTxt="$fileName.txt"

fileNameBad=${fileName}".bad_"${TIMESTAMP}".txt"

# iloœæ linii przed usuniêciem pustych 
linesNumber=$(cat $fileNameTxt |wc -l)
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer of lines $linesNumber" >> PROCESSED/"$logFileName"

# Usuniêcie pustych linii
sed -i '/^$/d' "$fileNameTxt" 						
EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Remove empty lines error" >> PROCESSED/"$logFileName"
    exit 1
else
	echo "$TIME : Remove empty lines succesful" >> PROCESSED/"$logFileName"
fi

# Iloœæ linii usuniêtych 
linesNumberAfter=$(cat $fileNameTxt |wc -l)
emptyLines="$(($linesNumber-$linesNumberAfter))"
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer deleted empty lines: $emptyLines" >> PROCESSED/"$logFileName"

# Pozostawienie tylko unikalnych linii 
# ----------------------------------------
awk 'NR == 1; NR>1 {print $0 |"sort -n"}' "$fileNameTxt" > temp.txt
# wpisanie duplikatów do bad file
uniq -D temp.txt  >> "$fileNameBad"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Remove duplicated lines: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Remove duplicated lines: success" >> PROCESSED/"$logFileName"
fi

uniq -u temp.txt > "$fileNameTxt"
rm temp.txt

dulicatedLines=$(cat $fileNameBad |wc -l) 
badLines=$dulicatedLines
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer duplicated lines: $dulicatedLines" >> PROCESSED/"$logFileName"


# Usuniêcie lini z b³êdn¹ liczb¹ kolumn
#------------------------------------------

awk -v n="$4" -F'|' 'NF==n ' "$fileNameTxt" > temp.txt
awk -v n="$4" -F'|' 'NF!=n ' "$fileNameTxt" >> "$fileNameBad" 
mv temp.txt "$fileNameTxt" 

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Remove line with bad number of colmuns: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Remove line with bad number of colmuns: success" >> PROCESSED/"$logFileName"
fi

actualBadLines=$(cat $fileNameBad |wc -l)
badColumnsLines="$(($actualBadLines-$badLines))"
badLines=$actualBadLines	
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer lines with bad colmuns number: $badColumnsLines" >> PROCESSED/"$logFileName"

# Usuniêcie linii gdzie kolumna OrderQuantity jest wiêksza od 100
#-------------------------------------------

awk -v maxVal=$5 -F'|' '$5 =="" || $5 >maxVal' "$fileNameTxt" | tail -n +2 >> "$fileNameBad"
head -n 1 "$fileNameTxt" > header.txt
cat header.txt > temp.txt
awk -v maxVal=$5 -F'|' '$5!=""  && $5 <=maxVal' "$fileNameTxt" >> temp.txt
mv temp.txt "$fileNameTxt"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Remove line with bad OrderQuantity values: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Remove line with bad OrderQuantity values: success" >> PROCESSED/"$logFileName"
fi

actualBadLines=$(cat $fileNameBad |wc -l)
badOrderQuatityLines="$(($actualBadLines-$badLines))"
badLines=$actualBadLines	
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer lines with bad OrderQuantity values: $badOrderQuatityLines" >> PROCESSED/"$logFileName"

# Porównanie pliku z plikiem InternetSales_old.txt
# -------------------------------------------------

tail -n +2 "$fileNameTxt" | sort > temp.txt
dos2unix -q "$6"
tail -n +2 "$6" | sort > temp_old.txt
diff temp_old.txt temp.txt  --changed-group-format=""  >> "$fileNameBad"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -gt 1 ];then
	echo "$TIME : Remove lines which exist in InternetSales_old.txt: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Remove lines which exist in InternetSales_old.txt: success" >> PROCESSED/"$logFileName"
fi

actualBadLines=$(cat $fileNameBad |wc -l)
linesInBothFiles="$(($actualBadLines-$badLines))"
badLines=$actualBadLines	
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer lines in both files: $linesInBothFiles" >> PROCESSED/"$logFileName"

cat header.txt > temp2.txt
diff temp_old.txt temp.txt --old-group-format=""  --unchanged-group-format=""  >> temp2.txt
mv temp2.txt "$fileNameTxt"

rm temp.txt
rm temp_old.txt

# Usuniêcie linii z wartoœciami SecretCode 
# ----------------------------------------
awk  -F'|' ' $7 !=""'  InternetSales_new.txt  | tail -n +2 | cut -d'|' -f -6 | awk '{print $0"|"}' >> "$fileNameBad"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Remove lines with SecretCode: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Remove lines with SecretCode: success" >> PROCESSED/"$logFileName"
fi

actualBadLines=$(cat $fileNameBad |wc -l)
linesWithSecretCode="$(($actualBadLines-$badLines))"
badLines=$actualBadLines	
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer lines with SecretCode: $linesWithSecretCode" >> PROCESSED/"$logFileName"

cat header.txt > temp.txt 
tail -n +2 $fileNameTxt | awk  -F'|' ' $7 ==""' >> temp.txt 
mv temp.txt  "$fileNameTxt"

# Usuniêcie linii gdzie nazwisko i imie nie s¹ rozdzielone przecinkiem
# --------------------------------------------

awk -F"|" '!match($3,",") ' "$fileNameTxt" | tail -n +2  >> "$fileNameBad"
cat header.txt > temp.txt 
awk -F"|" 'match($3,",") ' "$fileNameTxt"  >> temp.txt 
mv temp.txt "$fileName"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Remove lines where last and first name are not sprated by ',': error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Remove lines where last and first name are not sprated by ',': success" >> PROCESSED/"$logFileName"
fi

actualBadLines=$(cat $fileNameBad |wc -l)
linesWithBadCustomerName="$(($actualBadLines-$badLines))"
badLines=$actualBadLines	
TIME=$(date '+%H%M%S_%d%m%Y')
echo "$TIME : Numer lines with bad customer name: $linesWithBadCustomerName" >> PROCESSED/"$logFileName"

# Podzielenie Customer_Name na dwie kolumny
# ---------------------------------------

echo "FIRST_NAME" > firstName
echo "LAST_NAME" > latName
cut -d'|' -f-2 "$fileNameTxt" > startCol
cut -d'|' -f3 "$fileNameTxt" | tr -d "\""| cut -d','  -f1 |tail -n +2 >> latName 
cut -d'|' -f3 "$fileNameTxt" | tr -d "\""| cut -d','  -f2 |tail -n +2 >> firstName
cut -d'|' -f4- "$fileNameTxt" > endCol
paste -d'|' startCol firstName latName endCol > "$fileNameTxt"
rm startCol firstName latName endCol header.txt

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
 if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Split customer name: error" >> PROCESSED/"$logFileName"
	exit 1
else
    echo "$TIME : Split customer name: success" >> PROCESSED/"$logFileName"
fi

# Utworzenie tabeli w bazie danych 
# --------------------------------------

column1=$(head -n1 "$fileNameTxt" |cut -d'|' -f1)
column2=$(head -n1 "$fileNameTxt" |cut -d'|' -f2)
column3=$(head -n1 "$fileNameTxt" |cut -d'|' -f3)
column4=$(head -n1 "$fileNameTxt" |cut -d'|' -f4)
column5=$(head -n1 "$fileNameTxt" |cut -d'|' -f5)
column6=$(head -n1 "$fileNameTxt" |cut -d'|' -f6)
column7=$(head -n1 "$fileNameTxt" |cut -d'|' -f7)
column8=$(head -n1 "$fileNameTxt" |cut -d'|' -f8)

password="'$8'"
tableName="CUSTOMERS_$1"

# Mia³em problem z wczytaniem poprawnie has³a z parametru, dlatego musia³em zrobiæ na sztywno
mysql -h "$9" -P 3306 -u "$7" -D "$7" -p'BJzz0xME5TuvKNEc' --silent -e "CREATE TABLE $tableName($column1 INTEGER,$column2 VARCHAR(20),$column3 VARCHAR(40),$column4 VARCHAR(40),$column5 VARCHAR(20),$column6 VARCHAR(20),$column7 FLOAT,$column8 VARCHAR(20) );"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Create table: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Create table: success" >> PROCESSED/"$logFileName"
fi

# Za³adowanie danych do bazy danych 
# ------------------------------------

tail -n +2 "$fileNameTxt" | tr ',' '.' > temp 
mysql -h "$9" -P 3306 -u "$7" -D "$7" -p'BJzz0xME5TuvKNEc' --silent -e "LOAD DATA LOCAL INFILE 'temp' INTO TABLE $tableName FIELDS TERMINATED BY '|';"
rm temp

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Insert data to table: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Insert data to table: success" >> PROCESSED/"$logFileName"
fi

# Przeniesienie pliku do PROCESSED/
#----------------------------------
mv "$fileNameTxt" PROCESSED/


# Zaktualizowanie kolumny SecretCode 
# ---------------------------------
value="$(openssl rand -hex 5)"
mysql -h "$9" -P 3306 -u "$7" -D "$7" -p'BJzz0xME5TuvKNEc' --silent -e "UPDATE $tableName SET $column8='$value';"

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Insert data to SecretCode column: error" >> PROCESSED/"$logFileName"
	exit 1
else
    echo "$TIME : Insert data to SecretCode column: success" >> PROCESSED/"$logFileName"
fi

# Wyeksportowanie tabeli do pliku
# ---------------------------------

mysql -h "$9" -P 3306 -u "$7" -D "$7" -p'BJzz0xME5TuvKNEc' --silent -e "SELECT * FROM $tableName;"|sed 's/\t/,/g' > $tableName.csv

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Export table to csv: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Export table to csv: success" >> PROCESSED/"$logFileName"
fi


# Skompresowanie pliku csv 
# ------------------------------

zip -q $tableName $tableName.csv  

EXITCODE=$?
TIME=$(date '+%H%M%S_%d%m%Y')
if [ $EXITCODE -ne 0 ];then
	echo "$TIME : Compress csv file: error" >> PROCESSED/"$logFileName"
	exit 1
else
	echo "$TIME : Compress csv file: success" >> PROCESSED/"$logFileName"
fi

