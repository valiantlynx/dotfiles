#!/bin/bash
# Logout the current user and return to the login screen
ls
echo "Logging out..."
loginctl terminate-user $USER
