# 1. NVM letöltése és telepítése
echo "NVM telepítése..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# 2. NVM betöltése az aktuális munkamenetbe
echo "NVM környezet betöltése..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# 3. A legújabb stabil (LTS) Node.js telepítése
echo "Node.js (LTS) telepítése..."
nvm install --lts

# 4. Alapértelmezett verzió beállítása
nvm alias default 'lts/*'

# 5. Eredmény ellenőrzése
echo "Telepítés befejezve! A jelenlegi verziók:"
echo -n "Node: " && node -v
echo -n "NPM: " && npm -v
