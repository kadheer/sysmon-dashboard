#!/bin/bash
echo "Dashboard Updated. Starting HTTP Server on port 8080..."
echo "Open Http://localhost8080 in your local browser"
cd docs
python3 -m http.server 8080 

