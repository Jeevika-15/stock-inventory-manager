# Stockify – Smart Inventory Management

## Project Overview
Stockify is a Flutter-based inventory management application developed using Firebase Cloud Firestore. It allows retailers to add, retrieve, search, filter and sort stock records through a modern dark-themed interface.

## Technologies Used
- Flutter and Dart
- Firebase Cloud Firestore
- Firebase Core
- Android Studio

## Firestore Database Schema
Collection: `stockItems`

| Field | Data Type |
|---|---|
| sku | String |
| itemName | String |
| category | String |
| quantity | Integer |
| unitPrice | Number |
| reorderLevel | Integer |
| createdAt | Timestamp |

## Validation
The application validates SKU format (STK- followed by three digits), item name length (minimum three characters), category selection, non-negative integer quantity and reorder level, and a positive unit price. Invalid forms are prevented from being saved.

## Features
- Add stock records to Firestore.
- Retrieve saved inventory records.
- Search partially and case-insensitively by SKU or item name.
- Filter by category and low-stock status.
- Combine search and filters.
- Sort inventory by quantity in ascending or descending order.
- Clear all filters.

Low stock is identified when quantity is less than or equal to reorder level.

## Test Log

| Test | Expected Result | Actual Result |
|---|---|---|
| Blank form | Validation errors; no write | To be recorded |
| Valid stock entry | Record saved and retrieved | To be recorded |
| Combined search | Only STK-103 displayed | To be recorded |

## Setup and Execution
Install Flutter and Android Studio. Run `flutter pub get`, configure Firebase using FlutterFire CLI, and ensure Cloud Firestore is enabled. Run the application using `flutter run -d chrome` or an available emulator.

Firebase Project ID: `stock-inventory-manager`