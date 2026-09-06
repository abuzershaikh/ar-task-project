# Build Error Fixes

## Main Issues Found

1. **Missing .g.dart files** - Code generation not run
2. **Missing required parameters** in home_page.dart
3. **Invalid constant in campaign_detail_bloc.dart**

## Quick Fix Strategy

Since code generation requires complex setup, we'll use a simpler approach:

### Option 1: Remove @JsonSerializable and use manual JSON parsing
### Option 2: Comment out models temporarily
### Option 3: Build without those features first

## Recommended Fix

Build without complex features first, then add them incrementally.

For now, let's build a working version without code generation.

