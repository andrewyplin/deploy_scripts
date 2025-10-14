#!/bin/bash
set -e

driver_package=$1

sudo apt update
sudo apt upgrade -y
sudo apt remove nvidia-* -y || true
sudo apt autoremove -y --purge || true
sudo apt install $driver_package -y
sudo reboot now
