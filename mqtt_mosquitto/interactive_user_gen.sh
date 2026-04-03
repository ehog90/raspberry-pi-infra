#!/bin/bash

# --- Alapértelmezett beállítások ---
OUTPUT_FILE="users.txt"
LENGTH=16

# --- Súgó és Paraméterek feldolgozása ---
show_help() {
    echo "Használat: $0 [OPCIÓK]"
    echo ""
    echo "Opciók:"
    echo "  -o, --out      Kimeneti fájl neve (alapértelmezett: users.txt)"
    echo "  -l, --length   A generált jelszó hossza (alapértelmezett: $LENGTH)"
    echo "  -h, --help     Ennek a súgónak a megjelenítése"
    exit 0
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -o|--out)
            OUTPUT_FILE="$2"
            shift
            ;;
        -l|--length)
            LENGTH="$2"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Hiba: Ismeretlen paraméter: $1"
            exit 1
            ;;
    esac
    shift
done

# --- Validáció ---
if ! [[ "$LENGTH" =~ ^[0-9]+$ ]] || [ "$LENGTH" -le 0 ]; then
    echo "Hiba: A jelszó hosszának (-l) pozitív egész számnak kell lennie!"
    exit 1
fi

echo "=== Interaktív Felhasználó és Jelszó Generáló ==="
echo " Kimeneti fájl : $OUTPUT_FILE"
echo " Jelszó hossza : $LENGTH karakter"
echo " (A kilépéshez csak nyomj egy Entert üres névvel!)"
echo "================================================="

# --- Bekérő ciklus ---
while true; do
    # Bekérjük a felhasználónevet
    read -p "Új felhasználónév: " USERNAME

    # Eltávolítjuk a felesleges szóközöket az elejéről és a végéről
    USERNAME=$(echo "$USERNAME" | xargs)

    # Ha a felhasználó nem írt be semmit (csak entert nyomott), kilépünk a ciklusból
    if [ -z "$USERNAME" ]; then
        echo "Kilépés..."
        break
    fi

    # Jelszó generálása (/dev/urandom használatával)
    PASSWORD=$(LC_ALL=C tr -dc 'A-Za-z0-9_!@#$%^&*()-+=' < /dev/urandom | head -c "$LENGTH")

    # Adatok hozzáfűzése a fájlhoz (a >> operátor nem írja felül a fájlt, hanem a végéhez fűz)
    echo "$USERNAME:$PASSWORD" >> "$OUTPUT_FILE"

    # Visszajelzés a terminálon
    echo "  -> Rögzítve: $USERNAME:$PASSWORD"
done

echo "-------------------------------------------------"
echo "Kész! A listát megtalálod a(z) '$OUTPUT_FILE' fájlban."