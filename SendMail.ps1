$SMTPServer = "130.212.96.31"
$SMTPPort = "25"
$MailSender = "TestSMTP@sfsu.edu"
$MailTo = "akmartin@sfsu.edu"
$MailSubject = "Test SMTP Email"
$MailBody = "WORKS!"
#$MailAttach = ""
Send-MailMessage -SmtpServer "130.212.96.31" -Port "25" -To $MailTo -From $MailSender -Subject $MailSubject -Body $MailBody #-Attachments $MailAttach