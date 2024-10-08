# Use the official Windows image for .NET Framework 4.8
FROM mcr.microsoft.com/dotnet/framework/aspnet:4.8.1 AS build

# Set the working directory
WORKDIR /app

# Copy the project files
COPY src/sample-eval.sln ./
COPY src/ ./

# Restore packages and build the application
RUN nuget restore sample-eval.sln
RUN msbuild sample-eval.sln /p:Configuration=Release

# Publish the application
RUN msbuild sample-eval.sln /p:Configuration=Release /p:OutputPath=./publish

# Zip the published files
RUN powershell -Command "Compress-Archive -Path ./publish/* -DestinationPath ../dotnet-app.zip"
