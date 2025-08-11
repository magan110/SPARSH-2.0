# Numeric Conversion Fix Summary

## Problem
The API was returning the error: "Error converting data type nvarchar to numeric" because string values were being sent to numeric database columns.

## Root Cause
The Flutter app was sending all numeric values as strings instead of actual numbers, causing the database to fail when trying to insert string values into numeric columns.

## Fields Fixed

### 1. Enrolment Slabs
- `WcErlSlb`: String → Numeric
- `WpErlSlb`: String → Numeric  
- `VpErlSlb`: String → Numeric

### 2. BW Stock Values
- `BwStkWcc`: String → Numeric
- `BwStkWcp`: String → Numeric
- `BwStkVap`: String → Numeric

### 3. Market Averages
- `JkAvgWcc`: String → Numeric
- `JkAvgWcp`: String → Numeric
- `AsAvgWcc`: String → Numeric
- `AsAvgWcp`: String → Numeric
- `OtAvgWcc`: String → Numeric
- `OtAvgWcp`: String → Numeric

### 4. Volume Fields
- `SlWcVlum`: String → Numeric
- `SlWpVlum`: String → Numeric

### 5. GPS and Location
- `GeoLatit`: String → Numeric (decimal)
- `GeoLongt`: String → Numeric (decimal)
- `LtLgDist`: String → Numeric

### 6. Product Quantities
- `ProdQnty`: String → Numeric
- `ProjQnty`: String → Numeric

### 7. Market Intelligence Prices
- `PriceB`: String → Numeric (decimal)
- `PriceC`: String → Numeric (decimal)

### 8. Gift Distribution Quantities
- `IsueQnty`: String → Numeric

## Implementation
- Enhanced `_parseNumeric()` helper function to properly convert strings to appropriate numeric types (int or double)
- Applied numeric conversion to all relevant fields in the API data conversion methods
- Maintained backward compatibility by providing default values (0 or 0.0) for null/empty values

## Result
The API should now receive properly typed numeric values instead of strings, resolving the database insertion error.