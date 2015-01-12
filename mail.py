# -*- coding=utf-8 -*-
import sys
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import datetime
today = datetime.datetime.now()
yesterday = today + datetime.timedelta(days =-1)
DATE =  yesterday.strftime('%Y-%m-%d')
arg = sys.argv[1]

def sendEmail(msgTo, content, type):
    (attachment,html) = content
    msg = MIMEMultipart()
    msg['Subject'] = type
    msg['From'] = ''
    msg['To'] = msgTo
    html_att = MIMEText(html, 'html', 'utf-8')
    att = MIMEText(attachment, 'plain', 'utf-8')
    msg.attach(html_att)
    msg.attach(att)
    try:
        smtp = smtplib.SMTP()
        smtp.connect('', 25)
        smtp.login(msg['From'], 'passwd')
        smtp.sendmail(msg['From'], msg['To'].split(','), msg.as_string())
    except Exception,e:
        print e

if __name__ == '__main__':
    ToUser='users mail'
    filestr = 'mail.tmp'
    html =  file(filestr).read()
    sendEmail(ToUser, (filestr, html), u'[统计]' + "[" + "%s" %(arg) + "]" + u'[模块状态码响应时间]' + "%s" %(DATE))
