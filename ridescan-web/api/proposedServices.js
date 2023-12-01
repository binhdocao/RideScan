const mongoose = require('mongoose');
const ProposedService = require('../models/ProposedService'); // adjust path as necessary
const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    service: "gmail",
    host: "smtp.gmail.com",
    port: 587,
    secure: false,
    auth: {
      user: "ridescan.notifications@gmail.com",
      pass: process.env.EMAIL_APP_PASSWORD,
    },
});

mongoose.connect(process.env.MONGO_CONNECT);

module.exports = async (req, res) => {
    if (req.method === 'POST') {
        try {
            const newService = new ProposedService(req.body);
            await newService.save();

            const mailOptions = {
                from: 'ridescan.notifications@gmail.com',
                to: req.body.email, 
                subject: 'Submission Received',
                text: 'Your submission has been received. Please wait 1-2 business days for a response.'
            };

            await transporter.sendMail(mailOptions);
            res.status(201).send('Proposed service data saved and email sent');
        } catch (error) {
            console.error(error);
            res.status(500).send('Error saving data');
        }
    } else {
        res.status(405).send('Method Not Allowed');
    }
};
