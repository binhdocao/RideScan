const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const app = express();
app.use(bodyParser.json());

const corsOptions = {
    origin: process.env.ORIGIN_LINK, // Your Vercel app URL
    optionsSuccessStatus: 200
};

app.use(cors(corsOptions));

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


// Connect to MongoDB
mongoose.connect(process.env.MONGO_CONNECT);
console.log("process.env.MONGO_CONNECT: ", process.env.MONGO_CONNECT);


// Define a schema
const proposedServiceSchema = new mongoose.Schema({
    contactName: String,
    email: String,
    phoneNumber: String,
    user_proposed: Boolean,
    send_to_application: Boolean,
    serviceName: String,
    address: String,
    radius: String,
    comments: String
});

// Create a model for proposed services
const ProposedService = mongoose.model('ProposedService', proposedServiceSchema, 'proposedServices');

// Endpoint to handle proposed services data submission
app.post('/proposedServices', async (req, res) => {
    try {
        const newService = new ProposedService(req.body);
        await newService.save();

        const mailOptions = {
            from: 'ridescan.notifications@gmail.com',
            to: req.body.email, 
            subject: 'Submission Received',
            text: 'Your submission has been received. Please wait 1-2 business days for a response.'
        };
    
        transporter.sendMail(mailOptions, function(error, info) {
            if (error) {
                console.log(error);
                res.status(500).send('Error sending email');
            } else {
                console.log('Email sent: ' + info.response);
                res.status(201).send('Proposed service data saved and email sent');
            }
        });
    } catch (error) {
        console.log(error);
        res.status(500).send('Error saving data');
    }
});



const PORT = 5500;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
