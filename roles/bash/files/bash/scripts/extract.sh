#!/bin/bash

for i in "$@"; do
    tar -xvzf $i
    break
done
