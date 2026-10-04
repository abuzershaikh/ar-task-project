class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    
    return null;
  }

  static String? minLength(String? value, int length, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    
    if (value.length < length) {
      return '${fieldName ?? 'This field'} must be at least $length characters';
    }
    
    return null;
  }

  static String? maxLength(String? value, int length, [String? fieldName]) {
    if (value != null && value.length > length) {
      return '${fieldName ?? 'This field'} must not exceed $length characters';
    }
    
    return null;
  }

  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Number is required';
    }
    
    if (int.tryParse(value) == null) {
      return 'Enter a valid number';
    }
    
    return null;
  }

  static String? minValue(String? value, int min) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Enter a valid number';
    }
    
    if (intValue < min) {
      return 'Value must be at least $min';
    }
    
    return null;
  }

  static String? maxValue(String? value, int max) {
    if (value == null || value.isEmpty) {
      return 'Value is required';
    }
    
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Enter a valid number';
    }
    
    if (intValue > max) {
      return 'Value must not exceed $max';
    }
    
    return null;
  }
}
