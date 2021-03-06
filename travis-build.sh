#!/bin/bash

cd /build/esp-idf
git checkout --track origin/$1
git reset --recurse --hard HEAD
git pull -p
git submodule sync
git submodule update --recursive
git clean -fdx
git status

cd /build/project/main/certs

if [ -f CA.crt -o -f esp32.crt -o -f esp32.key ]; then
    echo "Certificates already exist. Not overwriting"
else
    certstrap init --common-name "CA" --passphrase "test"
    certstrap request-cert --passphrase "test" -cn esp32
    certstrap sign esp32 --passphrase "test" --CA "CA"

    cp out/CA.crt .
    cp out/esp32.crt .
    cp out/esp32.key .
    chmod u+w,a+r *.crt *.key
fi

cd /build/project

cat >> sdkconfig.default <<EOF
CONFIG_MQTT_USER=""
CONFIG_MQTT_PASSWORD=""
CONFIG_MQTT_TOPIC_PREFIX="esp"
CONFIG_MQTT_CLIENTID_PREFIX="beaconscanner"
CONFIG_MQTT_TLS=y
CONFIG_CA_CERTIFICATE=y
CONFIG_CLIENT_CERTIFICATES=y
CONFIG_EMBEDDED_CERTIFICATES=y
CONFIG_DEFAULT_BLE_SCANNER=y
CONFIG_ESPTOOLPY_FLASHSIZE_4MB=y
EOF

export PATH=$PATH:/build/$2/xtensa-esp32-elf/bin:$IDF_PATH/tools

rm -rf build

case "$3" in
    cmake)
        idf.py build
        ;;
    make)
        make defconfig
        make all
        ;;
    "*")
        ;;
esac
