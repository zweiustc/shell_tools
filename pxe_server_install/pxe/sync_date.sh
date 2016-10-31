#!/bin/bash

cp -r /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

date -s $1
date -s $2
clock -w
