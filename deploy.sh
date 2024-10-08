#!/bin/bash

set -o

# Navigate to the project directory
cd src/

# Restore packages and build the application
dotnet restore sample-eval.sln
dotnet publish sample-eval.sln -c Release -o ./publish

# Navigate to the publish directory
cd ./publish

# Zip the published files
zip -r ../dotnet-app.zip .
