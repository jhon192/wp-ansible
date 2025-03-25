#!/bin/bash
# Verifica que el script se ejecute como root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecute este script como root."
    exit 1
fi

# Variables de configuración
NEW_USER="ansible"       # Cambia el nombre del usuario si lo deseas
PASSWORD="1234"
USER_HOME="/home/$NEW_USER"
SSH_DIR="$USER_HOME/.ssh"
PRIVATE_KEY="$SSH_DIR/id_rsa"
PUBLIC_KEY="$SSH_DIR/id_rsa.pub"
SUDOERS_FILE="/etc/sudoers.d/$NEW_USER"

# Crear el usuario si no existe y asignarle la contraseña
if id "$NEW_USER" &>/dev/null; then
    echo "El usuario $NEW_USER ya existe."
else
    echo "Creando el usuario $NEW_USER..."
    useradd -m -s /bin/bash "$NEW_USER"
    echo "$NEW_USER:$PASSWORD" | chpasswd
fi

# Crear el directorio .ssh en el home del usuario
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chown "$NEW_USER":"$NEW_USER" "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Generar par de claves SSH (sin passphrase) si no existen
if [ ! -f "$PRIVATE_KEY" ]; then
    echo "Generando claves SSH para $NEW_USER..."
    sudo -u "$NEW_USER" ssh-keygen -t rsa -b 2048 -f "$PRIVATE_KEY" -N "" -q
fi

# Agregar la clave pública al archivo authorized_keys si aún no está añadida
if [ -f "$PUBLIC_KEY" ]; then
    if [ ! -f "$SSH_DIR/authorized_keys" ] || ! grep -q -F "$(cat "$PUBLIC_KEY")" "$SSH_DIR/authorized_keys"; then
        cat "$PUBLIC_KEY" >> "$SSH_DIR/authorized_keys"
        echo "Clave pública añadida a authorized_keys."
    fi
    chown "$NEW_USER":"$NEW_USER" "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"
else
    echo "No se encontró la clave pública."
fi

# Configurar SSH para que este usuario no pueda autenticarse por contraseña
SSHD_CONFIG="/etc/ssh/sshd_config"
MATCH_BLOCK="Match User $NEW_USER
    PasswordAuthentication no"

if ! grep -q "Match User $NEW_USER" "$SSHD_CONFIG"; then
    echo -e "\n$MATCH_BLOCK" >> "$SSHD_CONFIG"
    echo "Se ha actualizado la configuración SSH para el usuario $NEW_USER."
    # Reinicia el servicio SSH según el sistema
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart ssh
    else
        service ssh restart
    fi
fi

if [ ! -f "$SUDOERS_FILE" ]; then
    echo "$NEW_USER ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    echo "El usuario $NEW_USER ha sido agregado a sudoers sin requerir contraseña."
else
    echo "El usuario $NEW_USER ya se encuentra en sudoers."
fi 

echo "---------------------------------------------------------"
echo "Configuración completada."
echo "La clave privada para conectarte es la siguiente:"
echo "--------------------- CLAVE PRIVADA ---------------------"
cat "$PRIVATE_KEY"
echo "---------------------------------------------------------"
echo "Guarda esta clave en un lugar seguro y, para conectarte, usa:"
echo "ssh -i /ruta/a/la/clave_privada $NEW_USER@<IP_del_contenedor>"
