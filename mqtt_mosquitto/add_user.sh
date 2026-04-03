#!/bin/bash

# --- Alapértelmezett értékek ---
INPUT_FILE="users.txt"
CONTAINER_NAME="mosquitto_broker"
PWFILE_PATH="/mosquitto/config/pwfile"

# --- Súgó funkció ---
show_help() {
    echo "Használat: $0 [OPCIÓK]"
    echo ""
    echo "Opciók:"
    echo "  -f, --file       Bemeneti fájl, amely tartalmazza a usereket (alapértelmezett: users.txt)"
    echo "  -c, --container  A Mosquitto Docker konténer neve (alapértelmezett: mosquitto_broker)"
    echo "  -h, --help       Ennek a súgónak a megjelenítése"
    echo ""
    echo "Példa:"
    echo "  $0 -f uj_eszkozok.txt -c my_mqtt_broker"
    exit 0
}

# --- Paraméterek feldolgozása ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -f|--file)
            INPUT_FILE="$2"
            shift
            ;;
        -c|--container)
            CONTAINER_NAME="$2"
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Hiba: Ismeretlen paraméter: $1"
            echo "A segítségért használd a --help kapcsolót."
            exit 1
            ;;
    esac
    shift
done

echo "=== Felhasználók beolvasása fájlból ($INPUT_FILE) ==="

# 1. Ellenőrzések
if [ ! -f "$INPUT_FILE" ]; then
    echo "Hiba: A bemeneti fájl ($INPUT_FILE) nem található!"
    exit 1
fi

if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Hiba: A $CONTAINER_NAME konténer nem fut! Indítsd el először."
    exit 1
fi

# Biztosítjuk, hogy a pwfile létezzen a konténeren belül
docker exec "$CONTAINER_NAME" touch "$PWFILE_PATH"

# 2. A fájl soronkénti beolvasása
# Az IFS=':' beállítja, hogy a kettőspont mentén vágja szét a sort USERNAME és PASSWORD változókra
while IFS=':' read -r USERNAME PASSWORD; do

    # Eltávolítjuk a felesleges szóközöket és a Windowsos sorvégeket (\r) a sorok elejéről/végéről
    USERNAME=$(echo "$USERNAME" | tr -d '\r' | xargs)
    PASSWORD=$(echo "$PASSWORD" | tr -d '\r' | xargs)

    # Üres sorok és kommentek ( # karakterrel kezdődő sorok) kihagyása
    if [[ -z "$USERNAME" ]] || [[ "$USERNAME" == \#* ]]; then
        continue
    fi

    # Ellenőrizzük, hogy van-e jelszó megadva a névhez
    if [[ -z "$PASSWORD" ]]; then
        echo "Figyelmeztetés: Nincs jelszó megadva a '$USERNAME' felhasználóhoz! (Kihagyva)"
        continue
    fi

    echo "Feldolgozás: $USERNAME ..."

    # 3. Felhasználó rögzítése a -b (batch) kapcsolóval
    docker exec "$CONTAINER_NAME" mosquitto_passwd -b "$PWFILE_PATH" "$USERNAME" "$PASSWORD"

    if [ $? -ne 0 ]; then
        echo "  -> Hiba történt a(z) $USERNAME hozzáadásakor!"
    fi

done < "$INPUT_FILE"

# 4. A bróker újraindítása, hogy a változások életbe lépjenek
echo "A Mosquitto konténer újraindítása..."
docker restart "$CONTAINER_NAME"

echo "Kész! Az összes érvényes felhasználó betöltve a fájlból."