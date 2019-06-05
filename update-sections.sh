#!/bin/bash

echo "Fix file $1"

sed -r -i ':a s/^([=,]*)[=]/\1#/; t a' $1
sed -r -i ':a s/^([\^,]*)[\^]/\1*/; t a' $1
sed -r -i ':a s/^([~,]*)[~]/\1=/; t a' $1
