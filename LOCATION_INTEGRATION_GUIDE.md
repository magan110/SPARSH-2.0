# Location Integration Guide for DSR Entry

This guide shows how to integrate location functionality into your DSR (Daily Sales Report) entry system.

## Overview

The location functionality has been added to validate that users are within an acceptable distance from the customer location when submitting DSR entries.

## Files Modified

1. **lib/data/services/dsr_activity_service.dart** - Already contains the `validateLocationDistance` method
2. **lib/features/dsr_entry/presentation/pages/DsrVisitScreen.dart** - Added location variables and methods

## Location Variables Added

```dart
// Add these variables to your state class
String? userLatitude;
String? userLongitude;
String? customerLatitude;
String? customerLongitude;
bool isValidLocation = false;
String? locationValidationMessage;
bool isLoadingLocation = false;
String? locationError;
```

## Location Methods Added

### 1. Get Current Location
```dart
Future<void> _getCurrentLocation() async {
  setState(() {
    isLoadingLocation = true;
    locationError = null;
  });

  try {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLatitude = position.latitude.toString();
    userLongitude = position.longitude.toString();

    // If we have customer coordinates, validate the distance
    if (customerLatitude != null && customerLongitude != null) {
      await _validateLocationDistance();
    }

    setState(() {
      isLoadingLocation = false;
    });
  } catch (e) {
    setState(() {
      isLoadingLocation = false;
      locationError = 'Failed to get location: $e';
    });
  }
}
```

### 2. Validate Location Distance
```dart
Future<void> _validateLocationDistance() async {
  if (userLatitude == null || 
      userLongitude == null || 
      customerLatitude == null || 
      customerLongitude == null) {
    return;
  }

  try {
    final result = await _dsrService.validateLocationDistance(
      userLatitude: userLatitude!,
      userLongitude: userLongitude!,
      customerLatitude: customerLatitude!,
      customerLongitude: customerLongitude!,
    );

    setState(() {
      isValidLocation = result['isValid'] ?? false;
      locationValidationMessage = result['message'];
    });
  } catch (e) {
    setState(() {
      isValidLocation = false;
      locationValidationMessage = 'Location validation failed: $e';
    });
  }
}
```

## Form Validation Integration

The location validation has been integrated into the form submission process:

```dart
Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;
  
  // Validate location if customer coordinates are available
  if (customerLatitude != null && customerLongitude != null) {
    if (userLatitude == null || userLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get your current location first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (!isValidLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationValidationMessage ?? 'Location validation failed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
  }
  
  setState(() => isSubmitting = true);
  // ... rest of form submission logic
}
```

## UI Components Example

Here's how you can add a location section to your form:

```dart
// Add this section to your form
const _SectionHeader(
  icon: Icons.location_on,
  label: 'Location Verification',
),
_FantasticCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Current Location Status
      Row(
        children: [
          Icon(
            userLatitude != null ? Icons.check_circle : Icons.location_off,
            color: userLatitude != null ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            userLatitude != null 
              ? 'Location captured' 
              : 'Location not captured',
            style: TextStyle(
              color: userLatitude != null ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 12),
      
      // Get Location Button
      ElevatedButton.icon(
        onPressed: isLoadingLocation ? null : _getCurrentLocation,
        icon: isLoadingLocation 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
        label: Text(isLoadingLocation ? 'Getting Location...' : 'Get Current Location'),
      ),
      
      // Location Error
      if (locationError != null) ...[
        const SizedBox(height: 8),
        Text(
          locationError!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ],
      
      // Location Validation Status
      if (customerLatitude != null && customerLongitude != null) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              isValidLocation ? Icons.check_circle : Icons.error,
              color: isValidLocation ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                locationValidationMessage ?? 'Location validation pending',
                style: TextStyle(
                  color: isValidLocation ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    ],
  ),
),
```

## Dependencies Required

Make sure you have the following dependency in your `pubspec.yaml`:

```yaml
dependencies:
  geolocator: ^14.0.2  # Already included in your project
```

## Permissions Required

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to verify your proximity to customers.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access to verify your proximity to customers.</string>
```

## Usage Flow

1. **Get Customer Coordinates**: When a customer is selected, set the `customerLatitude` and `customerLongitude` variables
2. **Get User Location**: Call `_getCurrentLocation()` to get the user's current position
3. **Validate Distance**: The system automatically validates the distance when both coordinates are available
4. **Form Submission**: The form validates location before allowing submission

## API Integration

The `validateLocationDistance` method in `DSRActivityService` calls the backend API:

```dart
POST /api/DSRActivity/ValidateLocationDistance
{
  "userLatitude": "28.6139",
  "userLongitude": "77.2090",
  "customerLatitude": "28.6140",
  "customerLongitude": "77.2091"
}
```

Expected response:
```json
{
  "success": true,
  "data": {
    "isValid": true,
    "message": "Location is within acceptable range",
    "distance": 15.5
  }
}
```

## Error Handling

The system handles various error scenarios:
- Location services disabled
- Location permissions denied
- GPS not available
- Network errors during validation
- Invalid coordinates

All errors are displayed to the user with appropriate messages and prevent form submission until resolved.