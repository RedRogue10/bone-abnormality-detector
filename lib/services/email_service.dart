import 'package:cloud_firestore/cloud_firestore.dart';

class EmailService {
  Future<void> sendEmailLink(String email, String link) async {
    await FirebaseFirestore.instance.collection('mail').add({
      'to': email,
      'message': {
        'subject': 'Your X-Ray Results are Ready',
        'html':
            '''
        <div style="font-family: Arial; padding: 20px;">
          <h2 style="color:#1a73e8;">X-Ray Results Available</h2>

          <p>Your results are ready and available for the next <b>72 hours</b>.</p>

          <a href="$link"
             style="
              display:inline-block;
              padding:12px 18px;
              background:#1a73e8;
              color:white;
              text-decoration:none;
              border-radius:6px;
              font-weight:bold;
             ">
            View Results
          </a>

          <hr style="margin-top:20px;" />

          <p style="font-size:12px;color:gray;">
            This is an automated message from the Xray Reader. Please consult with your primary physician for a full clinical diagnosis.
          </p>

          <div style="text-align:center;">
            <img src="../../assets/images/logo.png" width="120" />
            <h2>X-Ray Scan Report</h2>
          </div>
        </div>
      ''',
      },
    });
    print("Email sent successfully!!!");
  }
}
