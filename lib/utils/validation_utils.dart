class ValidationUtils {
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email);
  }

  // Phone number validation (Moroccan format)
  static bool isValidPhoneNumber(String phone) {
    // Moroccan phone number format: +212XXXXXXXXX or 0XXXXXXXXX
    final phoneRegex = RegExp(
      r'^(\+212|0)[5-7][0-9]{8}$',
    );
    return phoneRegex.hasMatch(phone);
  }

  // Password validation
  static bool isValidPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    if (password.length < 8) return false;
    
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    
    return hasUppercase && hasLowercase && hasNumbers;
  }

  // Name validation
  static bool isValidName(String name) {
    // At least 2 characters, only letters and spaces
    if (name.length < 2) return false;
    
    final nameRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');
    return nameRegex.hasMatch(name);
  }

  // Property title validation
  static bool isValidPropertyTitle(String title) {
    return title.length >= 10 && title.length <= 100;
  }

  // Property description validation
  static bool isValidPropertyDescription(String description) {
    return description.length >= 20 && description.length <= 1000;
  }

  // Property price validation
  static bool isValidPropertyPrice(double price) {
    return price > 0 && price <= 10000; // Max 10,000 MAD per night
  }

  // Property capacity validation
  static bool isValidPropertyCapacity(int capacity) {
    return capacity >= 1 && capacity <= 20;
  }

  // Date validation
  static bool isValidDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  // Check-in date validation
  static bool isValidCheckInDate(DateTime checkIn) {
    return isValidDate(checkIn);
  }

  // Check-out date validation
  static bool isValidCheckOutDate(DateTime checkIn, DateTime checkOut) {
    if (!isValidDate(checkOut)) return false;
    return checkOut.isAfter(checkIn);
  }

  // Minimum stay validation
  static bool isValidMinimumStay(int nights) {
    return nights >= 1 && nights <= 30;
  }

  // Maximum stay validation
  static bool isValidMaximumStay(int nights) {
    return nights >= 1 && nights <= 90;
  }

  // City validation
  static bool isValidCity(String city) {
    final validCities = [
      'الدار البيضاء',
      'الرباط',
      'فاس',
      'مراكش',
      'طنجة',
      'أكادير',
      'مكناس',
      'وجدة',
      'القنيطرة',
      'تطوان',
      'سلا',
      'بني ملال',
      'خريبكة',
      'آسفي',
      'الجديدة',
      'تازة',
      'إفران',
      'وزان',
      'سيدي قاسم',
      'سيدي سليمان',
      'خنيفرة',
      'إفران',
      'إفران',
      'إفران',
      'إفران',
    ];
    
    return validCities.contains(city);
  }

  // Property type validation
  static bool isValidPropertyType(String type) {
    final validTypes = [
      'apartment',
      'villa',
      'riad',
      'studio',
      'house',
      'chalet',
      'farm',
      'castle',
    ];
    
    return validTypes.contains(type);
  }

  // Amenities validation
  static bool isValidAmenities(List<String> amenities) {
    if (amenities.isEmpty) return false;
    if (amenities.length > 20) return false; // Max 20 amenities
    
    final validAmenities = [
      'wifi',
      'air_conditioning',
      'heating',
      'kitchen',
      'washing_machine',
      'dryer',
      'parking',
      'pool',
      'gym',
      'spa',
      'garden',
      'balcony',
      'terrace',
      'elevator',
      'security',
      'breakfast',
      'cleaning',
      'linens',
      'towels',
      'shampoo',
      'soap',
      'tv',
      'netflix',
      'workspace',
      'pet_friendly',
      'smoking_allowed',
      'accessible',
      'family_friendly',
    ];
    
    return amenities.every((amenity) => validAmenities.contains(amenity));
  }

  // Image validation
  static bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return imageExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  // Rating validation
  static bool isValidRating(double rating) {
    return rating >= 0 && rating <= 5;
  }

  // Review validation
  static bool isValidReview(String review) {
    return review.length >= 10 && review.length <= 500;
  }

  // Payment method validation
  static bool isValidPaymentMethod(String method) {
    final validMethods = [
      'cash_on_delivery',
      'online',
      'bank_transfer',
      'mobile_money',
    ];
    
    return validMethods.contains(method);
  }

  // Booking status validation
  static bool isValidBookingStatus(String status) {
    final validStatuses = [
      'pending',
      'confirmed',
      'cancelled',
      'completed',
    ];
    
    return validStatuses.contains(status);
  }

  // User role validation
  static bool isValidUserRole(String role) {
    final validRoles = [
      'tenant',
      'host',
      'admin',
    ];
    
    return validRoles.contains(role);
  }

  // Notification type validation
  static bool isValidNotificationType(String type) {
    final validTypes = [
      'info',
      'success',
      'warning',
      'error',
      'booking',
      'payment',
      'system',
    ];
    
    return validTypes.contains(type);
  }

  // Get validation error message
  static String getValidationErrorMessage(String field, String error) {
    switch (error) {
      case 'required':
        return 'حقل $field مطلوب';
      case 'invalid_email':
        return 'البريد الإلكتروني غير صحيح';
      case 'invalid_phone':
        return 'رقم الهاتف غير صحيح';
      case 'invalid_password':
        return 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل مع حرف كبير وحرف صغير ورقم';
      case 'invalid_name':
        return 'الاسم يجب أن يحتوي على حروف فقط';
      case 'invalid_title':
        return 'العنوان يجب أن يكون بين 10 و 100 حرف';
      case 'invalid_description':
        return 'الوصف يجب أن يكون بين 20 و 1000 حرف';
      case 'invalid_price':
        return 'السعر يجب أن يكون أكبر من 0 وأقل من 10,000 درهم';
      case 'invalid_capacity':
        return 'السعة يجب أن تكون بين 1 و 20 شخص';
      case 'invalid_dates':
        return 'التواريخ غير صحيحة';
      case 'invalid_city':
        return 'المدينة غير صحيحة';
      case 'invalid_type':
        return 'نوع العقار غير صحيح';
      case 'invalid_amenities':
        return 'المرافق غير صحيحة';
      case 'invalid_rating':
        return 'التقييم يجب أن يكون بين 0 و 5';
      case 'invalid_review':
        return 'المراجعة يجب أن تكون بين 10 و 500 حرف';
      default:
        return 'قيمة غير صحيحة';
    }
  }

  // Validate form data
  static Map<String, String> validateForm(Map<String, dynamic> formData) {
    final errors = <String, String>{};

    // Required fields
    final requiredFields = [
      'email',
      'firstName',
      'lastName',
      'phone',
    ];

    for (final field in requiredFields) {
      if (formData[field] == null || formData[field].toString().isEmpty) {
        errors[field] = getValidationErrorMessage(field, 'required');
      }
    }

    // Email validation
    if (formData['email'] != null && !isValidEmail(formData['email'])) {
      errors['email'] = getValidationErrorMessage('email', 'invalid_email');
    }

    // Phone validation
    if (formData['phone'] != null && !isValidPhoneNumber(formData['phone'])) {
      errors['phone'] = getValidationErrorMessage('phone', 'invalid_phone');
    }

    // Name validation
    if (formData['firstName'] != null && !isValidName(formData['firstName'])) {
      errors['firstName'] = getValidationErrorMessage('firstName', 'invalid_name');
    }

    if (formData['lastName'] != null && !isValidName(formData['lastName'])) {
      errors['lastName'] = getValidationErrorMessage('lastName', 'invalid_name');
    }

    return errors;
  }

  // Validate property form data
  static Map<String, String> validatePropertyForm(Map<String, dynamic> formData) {
    final errors = <String, String>{};

    // Required fields
    final requiredFields = [
      'title',
      'description',
      'city',
      'propertyType',
      'price',
      'capacity',
    ];

    for (final field in requiredFields) {
      if (formData[field] == null || formData[field].toString().isEmpty) {
        errors[field] = getValidationErrorMessage(field, 'required');
      }
    }

    // Title validation
    if (formData['title'] != null && !isValidPropertyTitle(formData['title'])) {
      errors['title'] = getValidationErrorMessage('title', 'invalid_title');
    }

    // Description validation
    if (formData['description'] != null && !isValidPropertyDescription(formData['description'])) {
      errors['description'] = getValidationErrorMessage('description', 'invalid_description');
    }

    // City validation
    if (formData['city'] != null && !isValidCity(formData['city'])) {
      errors['city'] = getValidationErrorMessage('city', 'invalid_city');
    }

    // Property type validation
    if (formData['propertyType'] != null && !isValidPropertyType(formData['propertyType'])) {
      errors['propertyType'] = getValidationErrorMessage('propertyType', 'invalid_type');
    }

    // Price validation
    if (formData['price'] != null) {
      final price = double.tryParse(formData['price'].toString());
      if (price == null || !isValidPropertyPrice(price)) {
        errors['price'] = getValidationErrorMessage('price', 'invalid_price');
      }
    }

    // Capacity validation
    if (formData['capacity'] != null) {
      final capacity = int.tryParse(formData['capacity'].toString());
      if (capacity == null || !isValidPropertyCapacity(capacity)) {
        errors['capacity'] = getValidationErrorMessage('capacity', 'invalid_capacity');
      }
    }

    return errors;
  }

  // Validate booking form data
  static Map<String, String> validateBookingForm(Map<String, dynamic> formData) {
    final errors = <String, String>{};

    // Required fields
    final requiredFields = [
      'checkIn',
      'checkOut',
      'guests',
      'paymentMethod',
    ];

    for (final field in requiredFields) {
      if (formData[field] == null || formData[field].toString().isEmpty) {
        errors[field] = getValidationErrorMessage(field, 'required');
      }
    }

    // Date validation
    if (formData['checkIn'] != null && formData['checkOut'] != null) {
      final checkIn = DateTime.tryParse(formData['checkIn']);
      final checkOut = DateTime.tryParse(formData['checkOut']);

      if (checkIn == null || !isValidCheckInDate(checkIn)) {
        errors['checkIn'] = getValidationErrorMessage('checkIn', 'invalid_dates');
      }

      if (checkOut == null || !isValidCheckOutDate(checkIn!, checkOut)) {
        errors['checkOut'] = getValidationErrorMessage('checkOut', 'invalid_dates');
      }
    }

    // Payment method validation
    if (formData['paymentMethod'] != null && !isValidPaymentMethod(formData['paymentMethod'])) {
      errors['paymentMethod'] = getValidationErrorMessage('paymentMethod', 'invalid_payment_method');
    }

    return errors;
  }

  // Sanitize input
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Format phone number
  static String formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '+212${phone.substring(1)}';
    }
    return phone;
  }

  // Format price
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(2)} درهم';
  }

  // Format date
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format date range
  static String formatDateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    return '${formatDate(start)} - ${formatDate(end)} ($days ليلة)';
  }
}