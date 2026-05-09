InternetAddress fromAddr = new InternetAddress(
    "Victim\nBcc: all-users@corp.com", "noreply@corp.com");
msg.setFrom(fromAddr); // Delivers Bcc to all recipients
