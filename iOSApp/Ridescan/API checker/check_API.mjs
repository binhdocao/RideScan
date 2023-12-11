
import fetch from 'node-fetch';
import dotenv from 'dotenv';
dotenv.config();

import mailgun from 'mailgun-js';
const mg = mailgun({
  apiKey: process.env.MAILGUN_API_KEY,
  domain: process.env.MAILGUN_DOMAIN
});

// Function to check the API status and send an email if it's down
async function checkAPIStatusAndNotify(apiUrl, method) {
  try {
    //const apiUrl = process.env.API_URL; // Use API URL from .env
    const response = await fetch(apiUrl , {
      method: method});

    if (!response.ok) {
      // If API is down, send email notification
      sendEmailNotification('API is down: ' + apiUrl);
    } else {
      //sendEmailNotification('API is down');
      console.log('API is up');
    }
  } catch (error) {
    console.error('Error:', error);
    sendEmailNotification('Error checking API status: ' + apiUrl);
  }
}

// Function to send an email notification using Mailgun
function sendEmailNotification(errorMessage) {
  const data = {
    from: process.env.EMAIL_USER,
    to: process.env.RECIPIENT_EMAIL,
    subject: 'API Check Failed',
    text: `API check failed with error: ${errorMessage}`
  };

  mg.messages().send(data, (error, body) => {
    if (error) {
      console.error('Error sending email notification:', error);
    } else {
      console.log('Email notification sent:', body);
    }
  });
}

// Run the API check every 30 minutes (adjust the interval as needed)
//setInterval(checkAPIStatusAndNotify, 30 * 60 * 1000);

// Optionally, you can also start an express server if needed
// ...

// Or, if you don't need the server, you can just run the API check continuously
checkAPIStatusAndNotify(process.env.API_URL_BUS,'GET');
checkAPIStatusAndNotify(process.env.API_URL_VEO,'GET');
checkAPIStatusAndNotify(process.env.API_URL_FETII,'OPTIONS');
