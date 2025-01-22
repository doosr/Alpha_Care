class ApiConstants {
  static const String baseUrl = 'http://192.168.1.41:5000';

  static const String loginUrl = '$baseUrl/login';
  static const String resetPasswordUrl = '$baseUrl/reset-password';
  static const String registredUrl = '$baseUrl/registre';
  static const String imageUploadUrl = '$baseUrl/upload-image';
  static const String profilUrl = '$baseUrl/profile';
  static const String updateprofilUrl = '$baseUrl/profilee';
  static const String TypesMedecinsUrl = '$baseUrl/TypesMedecins';
  static const String sendUrl = '$baseUrl/invitation/send';
  static const String acceptInvitationUrl ='$baseUrl/invitation/accept'; // Add AcceptInvitationUrl here
  static const String invitationsUrl = '$baseUrl/invitations/received';
  static const String rejectInvitationUrl = '$baseUrl/invitation/reject';
  static const String babyDetailsUrl = '$baseUrl/getBabyDetails';
  static const String acceptedInvitationsUrl = '$baseUrl/invitations/accepted';
  static const String deleteInvitationUrl = '$baseUrl/invitation/delete';
  static const String measurementsUrl = '$baseUrl/api/measurements';
  static const String temperaturepostUrl = '$baseUrl/temperature';
  static const String temperaturegetUrl = '$baseUrl/temperature';
  static const String notificationsUrl ='$baseUrl/notifications'; // Endpoint pour récupérer les notifications
  static const String calendarUrl ='$baseUrl/calendar'; // Endpoint pour récupérer les notifications
  static const String pageUrl = '$baseUrl/page';
  static const String appointmentsUrl ='$baseUrl/appointments'; // Endpoint pour récupérer les notifications
  static const String babyIdUrl ='$baseUrl/babyId'; // Endpoint pour récupérer les notifications
  static const String rendez_vousUrl ='$baseUrl/last-visit-datetime'; // Endpoint pour récupérer les notifications
  static const String sendBabyIdUrl ='$baseUrl/send-babyid'; // Endpoint pour récupérer les notifications
  static const String userimage =  '$baseUrl//user-image'; // Endpoint pour récupérer les notifications
  static const String doctorsUrl ='$baseUrl/doctors'; // Endpoint pour récupérer les notifications

  static const String spo2hrpostUrl = '$baseUrl/heartbeat';

  static String invitationsWithUserUrl(String userId) =>
      '$baseUrl/invitations?user=$userId';
  static String invitationsWithReceiverUrl(String userId) =>
      '$baseUrl/invitations?receiver=$userId';

// Ajoutez d'autres URL API ici
}
