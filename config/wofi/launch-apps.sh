#!/bin/bash

killall wofi 2>/dev/null

wofi --show drun \
	--conf ~/.config/wofi/config \
	--style ~/.config/wofi/style.css \
	--cache-file=/dev/null
