import React, { useState } from 'axios';

function Form() {
    const [userData, setUserData] = useState({
        name: '',
        phoneNumber: '',
        email: ''
    });

    const handleChange = (e) => {
        setUserData({...userData, [e.target.name]: e.target.value});
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await axios.post('http://localhost:5000/submit', userData);
            alert('Data submitted!');
        } catch (error) {
            console.error('Error submitting data', error);
        }
    };

    return (
        <form onSubmit={handleSubmit}>
            <input
                type="text"
                name="name"
                value={userData.name}
                onChange={handleChange}
                placeholder="Name"
            />
            <input
                type="text"
                name="phoneNumber"
                value={userData.phoneNumber}
                onChange={handleChange}
                placeholder="Phone Number"
            />
            <input
                type="email"
                name="email"
                value={userData.email}
                onChange={handleChange}
                placeholder="Email"
            />
            <button type="submit">Submit</button>
        </form>
    );
}

export default Form;
