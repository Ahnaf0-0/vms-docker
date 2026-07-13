# Place this Dockerfile at the ROOT of your actual Flutter project
# (this /flutter_app folder is just a placeholder location for the demo compose setup)

# Stage 1 - build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY . .
RUN flutter pub get
# ENABLE_DEVICE_PREVIEW is read in main.dart via bool.fromEnvironment
RUN flutter build web --release --dart-define=ENABLE_DEVICE_PREVIEW=true

# Stage 2 - serve the built static files
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
EXPOSE 80
