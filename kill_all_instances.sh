#!/bin/bash


echo "Terminating any running anvil instances..."
killall anvil

echo "Terminating any running fairyringd instances..."
killall fairyringd

echo "Terminating any running fairyport instances..."
killall fairyport

echo "Terminating any running fairyringclient instances..."
killall fairyringclient

echo "Terminating any running ShareGenerationClient instances..."
killall ShareGenerationClient

echo "Terminating any running hermes instances..."
killall hermes

killall privgovd

echo "Terminating any running ignite instances..."
killall ignite