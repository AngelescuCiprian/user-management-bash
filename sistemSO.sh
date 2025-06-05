#!/bin/bash
CSV_FILE="users.csv"

# Daca nu exista fisierul, il creez
if [ ! -f "$CSV_FILE" ]; then
    echo "Username,Email,Password(Criptata),ID unic,Last_Login" > "$CSV_FILE"
fi

# Mesaj de intampinare
toilet -f mono9 -F gay "Login"

# Functie pentru validarea emailului
validate_mail() {
    if [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Functie pentru validarea parolei
validate_password() {
    if [[ ${#1} -ge 8 && "$1" =~ [A-Z] && "$1" =~ [0-9] ]]; then
        return 0
    else
        return 1
    fi
}

# Functie pentru resetarea parolei
resetare_parola() {
    email="$1"
    linie=$(grep ",$email," "$CSV_FILE")
    if [ -z "$linie" ]; then
        echo "Email inexistent in baza de date!"
        return
    fi

    username=$(echo "$linie" | cut -d ',' -f1)
    cod_reset=$RANDOM

    # Trimite codul de resetare pe email
    echo -e "Subject: Resetare parola\n\nSalut, $username!\n\nCodul tau de resetare este: $cod_reset\nIgnora acest mesaj daca nu ai cerut resetarea parolei." | msmtp "$email"

    echo "Un email cu codul de resetare a fost trimis la $email"
    read -p "Introdu codul primit: " cod_introdus

    if [ "$cod_introdus" = "$cod_reset" ]; then
        echo "Cod corect. Introdu o noua parola."
        while true; do
            read -s -p "Noua parola: " new
            echo
            if validate_password "$new"; then
                new_hash=$(echo -n "$new" | sha256sum | cut -d ' ' -f1)
                id=$(echo "$linie" | cut -d ',' -f4)
                lastLogin=$(date "+%d-%m-%Y %H:%M:%S")
                newLine="$username,$email,$new_hash,$id,$lastLogin"
                sed -i "s|^$linie\$|$newLine|" "$CSV_FILE"

                # Email de confirmare
                echo -e "Subject: Parola schimbata\n\nSalut, $username!\n\nParola ta a fost resetata cu succes." | msmtp "$email"

                echo "Parola a fost resetata cu succes. Vei fi redirectionat pentru autentificare..."
                sleep 1
                authenticate_user
                return
            else
                echo "Parola invalida. Minim 8 caractere, o litera mare si o cifra."
            fi
        done
    else
        echo "Cod incorect. Resetare esuata."
    fi
}

# Inregistrare utilizator
register_user() {
    while true; do
        read -p "Introdu username: " username
        if ! grep -q "^$username," "$CSV_FILE"; then
            break
        else
            echo "Username deja existent! Va rog introduceti altul!"
        fi
    done

    while true; do
        read -p "Introduceti mail-ul: " email
        if validate_mail "$email"; then
            break
        else
            echo "Mail invalid!"
        fi
    done

    while true; do
        read -s -p "Introduceti parola: " password
        echo
        hash=$(echo -n "$password" | sha256sum | cut -d ' ' -f1)
        if validate_password "$password"; then
            break
        else
            echo "Parola invalida (minim 8 caractere, o litera mare, o cifra)!"
        fi
    done

    id=$(date +%d%m%Y%M%s)
    echo "$username,$email,$hash,$id," >> "$CSV_FILE"
    echo "Utilizator inregistrat cu succes!"

    mkdir -p "./home/$username"

    creation_date=$(date "+%d-%m-%Y")
    echo -e "Subject: Cont creat cu succes pentru sistemul de management utilizatori\n\nSalut $username,\n\nContul tau a fost inregistrat cu succes!\nEmail: $email\nID unic: $id\nData crearii: $creation_date\n\nCu prietenie,\nEchipa SO1013" | msmtp "$email"
}

# Autentificare utilizator
authenticate_user() {
    read -p "Introduceti username: " usernameIntrodus
    linie=$(grep "^$usernameIntrodus," "$CSV_FILE")

    if [ -z "$linie" ]; then
        echo "Utilizatorul nu exista! Va rog sa va inregistrati!"
        return
    fi

    storedHash=$(echo "$linie" | cut -d ',' -f3)
    email=$(echo "$linie" | cut -d ',' -f2)
    incercari=0

    while [ $incercari -lt 3 ]; do
        read -s -p "Introduceti parola: " passwd
        echo
        enteredHash=$(echo -n "$passwd" | sha256sum | cut -d ' ' -f1)

        if [ "$storedHash" = "$enteredHash" ]; then
            lastLogin=$(date "+%d-%m-%Y %H:%M:%S")
            id=$(echo "$linie" | cut -d ',' -f4)
            newLine="$usernameIntrodus,$email,$storedHash,$id,$lastLogin"
            sed -i "s|^$linie\$|$newLine|" "$CSV_FILE"

            echo "Autentificare reusita!"
            echo "$usernameIntrodus" >> loggedUsers.txt

            cp logout.sh "./home/$usernameIntrodus/"
            chmod +x "./home/$usernameIntrodus/logout.sh"
            cp utilizatoriConectati.sh "./home/$usernameIntrodus/"
            chmod +x "./home/$usernameIntrodus/utilizatoriConectati.sh"

            cd "./home/$usernameIntrodus" || { echo "Eroare: Directorul utilizatorului nu exista!"; return; }

            GREEN='\033[0;32m'
            NC='\033[0m'
            echo "Bine ai venit $usernameIntrodus!"
            echo -e "Pentru a te deconecta scrie: ${GREEN}logout${NC}"
            echo -e "Pentru a vedea utilizatorii conectati scrie: ${GREEN}utilizatori${NC}"
            exec bash
            return
        else
            echo "Parola incorecta!"
            ((incercari++))
            echo "Incercare $incercari din 3"
        fi
    done

    echo -e "\nAi introdus parola gresit de 3 ori."
    read -p "Vrei sa resetezi parola? (da/nu): " raspuns
    if [[ "$raspuns" =~ ^[Dd][Aa]$ ]]; then
        resetare_parola "$email"
    else
        echo "Resetarea parolei a fost anulata."
    fi
}

# Functie pentru generarea raportului
generare_raport() {
    read -p "Introdu username-ul pentru care se genereaza raportul: " USER_NAME
    HOME_DIR="./home/$USER_NAME"
    RAPORT_FILE="$HOME_DIR/raport.txt"
    if [ ! -d "$HOME_DIR" ]; then
        echo "Utilizator inexistent!"
        return
    fi
    (
        NUM_FISIERE=$(find "$HOME_DIR" -type f | wc -l)
        NUM_DIRECTOARE=$(($(find "$HOME_DIR" -type d | wc -l) - 1))
        DIMENSIUNE=$(du -sh "$HOME_DIR" | cut -f1)
        {
            echo "Raport pentru utilizatorul: $USER_NAME"
            echo "Numar fisiere: $NUM_FISIERE"
            echo "Numar directoare: $NUM_DIRECTOARE"
            echo "Dimensiunea totala: $DIMENSIUNE"
        } > "$RAPORT_FILE"
        echo -e "\nRaport generat pentru $USER_NAME in $RAPORT_FILE\nAlegeti o optiune in continuare:"
    ) &
}

# Meniu principal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LGBT='\033[0;35m'
NC='\033[0m'

while true; do
    echo " "
    echo -e "${GREEN}====== MENIU ======${NC}"
    echo -e "${YELLOW}1. Inregistrare utilizator nou${NC}"
    echo -e "${BLUE}2. Autentificare utilizator${NC}"
    echo -e "${LGBT}3. Generare rapoarte utilizatori${NC}"
    echo -e "${RED}4. Iesire${NC}"
    read -p "Alege o optiune: " option

    case $option in
        1) register_user ;;
        2) authenticate_user ;;
        3) generare_raport ;;
        4) cowsay "La revedere!"
           exit 0 ;;
        *) echo -e "${RED}Optiune invalida!${NC}" ;;
    esac
done
