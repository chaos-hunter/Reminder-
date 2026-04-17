# Reminder_app

## Getting Started

This app was designed around andriod devices to use full features run on an andriod phone.

 - First enable developer mode on your phone, and laptop
 - Then turn on USB debugging on your phone
 - Then plug a usb to your laptop and connect it your phone
 - To make sure it is connected Run Flutter devices and see if it is listed under it
 - Then run flutter run this should download the app on your phone which you can now run
 - You have to enable permissions for the app to work

## Environment Variables

This project requires a `.env` file at the root of the project to securely store API keys and other sensitive configuration.

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in the missing `your_*_key` values with your actual Firebase and Google Maps credentials.

**Note:** The `.env` file is ignored by Git to prevent exposing your secrets, but `.env.example` is tracked to help developers know what variables are needed.

The file is able to be downloaded on andriod as .apk file `app-release.apk`