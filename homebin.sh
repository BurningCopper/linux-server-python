#!/bin/bash
# File to be added to /etc/profile.d in order to add customized bin directories for users at login

if [ -d "$HOME/bin" ]; then
	$PATH = $HOME/bin:$PATH

if [ -d "$HOME/.local/bin" ]; then
	$PATH = $HOME/.local/bin:$PATH

if [ -d "$HOME/homebrew/bin" ]; then
	$PATH = $HOME/homebrew/bin:$PATH

