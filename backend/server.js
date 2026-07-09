const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const Booking = require('./models/Booking');
const FoodOrder = require('./models/FoodOrder');
const User = require('./models/User');
const Review = require('./models/Review');
const Complaint = require('./models/Complaint');
const ContentItem = require('./models/ContentItem');

const app = express();
const PORT = process.env.PORT || 5000;

// Enable CORS and JSON parsing
app.use(cors());
app.use(express.json({ limit: '10mb' })); // support base64 attachments in JSON
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/admin', express.static(path.join(__dirname, 'public/admin')));

// Ensure uploads and public/admin directories exist
const uploadsDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir);
}
const adminDir = path.join(__dirname, 'public', 'admin');
if (!fs.existsSync(adminDir)) {
  fs.mkdirSync(adminDir, { recursive: true });
}

// In-Memory Database Fallbacks
let isUsingMongoDB = false;
const inMemoryBookings = [];
const inMemoryFoodOrders = [];
const inMemoryUsers = [];
const inMemoryReviews = [];
const inMemoryComplaints = [];

// Connect to MongoDB
const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/kuakata';
console.log(`Connecting to MongoDB at: ${mongoURI}`);

mongoose
  .connect(mongoURI, { serverSelectionTimeoutMS: 3000 })
  .then(() => {
    console.log('Successfully connected to MongoDB!');
    isUsingMongoDB = true;
    // Seed default content if MongoDB database is empty
    seedDefaultContent();
    seedTestUser();
    // Drop the unique mobile index if it exists to prevent E11000 duplicate key error for empty mobile fields
    mongoose.connection.db.collection('users').dropIndex('mobile_1')
      .then(() => {
        console.log('Successfully dropped legacy unique mobile_1 index');
      })
      .catch((err) => {
        // Index might not exist, which is fine and expected if it was already dropped or never created
        console.log('Unique mobile_1 index check/drop status:', err.message);
      });
  })
  .catch((err) => {
    console.warn('\n================================================================');
    console.warn('WARNING: Failed to connect to MongoDB!');
    console.warn('Reason:', err.message);
    console.warn('Running backend in OFFLINE/MOCK mode using in-memory store.');
    console.warn('Bookings and food orders will be saved in-memory and reset on restart.');
    console.warn('================================================================\n');
    isUsingMongoDB = false;
  });

// ==================== API ENDPOINTS ====================

// Privacy Policy Endpoint (Required for Google Play Store)
app.get('/privacy-policy', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Privacy Policy - Kuakata App</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            padding: 30px;
            color: #1e293b;
            max-width: 800px;
            margin: 0 auto;
        }
        h1 {
            color: #0ea5e9;
            font-size: 2.25rem;
            margin-bottom: 5px;
        }
        h2 {
            color: #0f172a;
            border-bottom: 1px solid #e2e8f0;
            padding-bottom: 8px;
            margin-top: 30px;
            font-size: 1.5rem;
        }
        p {
            margin: 15px 0;
        }
        .footer {
            margin-top: 40px;
            font-size: 0.875rem;
            color: #64748b;
            border-top: 1px solid #e2e8f0;
            padding-top: 15px;
        }
    </style>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p><strong>Last updated:</strong> July 10, 2026</p>
    <p>This privacy policy governs your use of the software application <strong>Kuakata</strong> ("Application") for mobile devices. The Application is a travel guide, tour support, and hotel/transport booking platform designed to enhance your travel experience in Kuakata, Bangladesh.</p>
    
    <h2>Information Collection and Use</h2>
    <p>We collect several types of information to provide and improve our service to you:</p>
    <ul>
        <li><strong>Personal Data:</strong> While using our Application, we may ask you to provide us with certain personally identifiable information, such as your Name, Phone number, and Profile image.</li>
        <li><strong>Usage Data:</strong> We may collect information about how the Application is accessed and used to help us improve user experience.</li>
    </ul>
    
    <h2>Permissions & Network Requirements</h2>
    <p>The Application requires <strong>Internet Access</strong> to connect to the backend server to process bookings, load listings (hotels, tour guides, transport, food), and submit complaints or feedback.</p>

    <h2>Security of Data</h2>
    <p>The security of your data is important to us. We implement industry-standard security measures to protect your information from unauthorized access, alteration, disclosure, or destruction.</p>

    <h2>Children's Privacy</h2>
    <p>Our Application does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.</p>

    <h2>Changes to This Privacy Policy</h2>
    <p>We may update our Privacy Policy from time to time. You are advised to review this page periodically for any changes.</p>

    <h2>Contact Us</h2>
    <p>If you have any questions about this Privacy Policy, you can contact us at:</p>
    <p><strong>Email:</strong> support@kuakatauide.com</p>
    <div class="footer">
        <p>&copy; 2026 Kuakata. All rights reserved.</p>
    </div>
</body>
</html>
  `);
});

// Root Landing Page
app.get('/', (req, res) => {
  res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kuakata API Portal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg-gradient: linear-gradient(135deg, #070B19 0%, #0F172A 100%);
            --card-bg: rgba(30, 41, 59, 0.7);
            --card-border: rgba(255, 255, 255, 0.08);
            --primary: #0EA5E9;
            --primary-glow: rgba(14, 165, 233, 0.15);
            --success: #10B981;
            --success-glow: rgba(16, 185, 129, 0.2);
            --text-main: #F8FAFC;
            --text-muted: #94A3B8;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: 'Outfit', sans-serif;
            background: var(--bg-gradient);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 2rem 1rem;
            overflow-x: hidden;
            position: relative;
        }

        body::before, body::after {
            content: '';
            position: absolute;
            width: 300px;
            height: 300px;
            border-radius: 50%;
            filter: blur(120px);
            z-index: -1;
            opacity: 0.15;
        }
        body::before {
            background: var(--primary);
            top: 10%;
            left: 10%;
        }
        body::after {
            background: #8B5CF6;
            bottom: 10%;
            right: 10%;
        }

        .container {
            max-width: 800px;
            width: 100%;
            background: var(--card-bg);
            border: 1px solid var(--card-border);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-radius: 24px;
            padding: 3rem;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            text-align: center;
            animation: fadeIn 0.8s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .logo-container {
            margin-bottom: 2rem;
            display: inline-flex;
            justify-content: center;
            align-items: center;
            background: radial-gradient(circle, var(--primary-glow) 0%, transparent 70%);
            width: 120px;
            height: 120px;
            border-radius: 50%;
        }

        .logo-icon {
            font-size: 3.5rem;
            animation: float 3s ease-in-out infinite;
        }

        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-10px); }
        }

        h1 {
            font-size: 2.5rem;
            font-weight: 800;
            background: linear-gradient(to right, #38BDF8, #818CF8);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 0.5rem;
            letter-spacing: -0.5px;
        }

        .subtitle {
            color: var(--text-muted);
            font-size: 1.1rem;
            margin-bottom: 2rem;
            font-weight: 300;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.75rem;
            background: rgba(16, 185, 129, 0.1);
            border: 1px solid rgba(16, 185, 129, 0.2);
            color: var(--success);
            padding: 0.5rem 1.25rem;
            border-radius: 100px;
            font-weight: 600;
            font-size: 0.9rem;
            margin-bottom: 3rem;
            box-shadow: 0 0 20px var(--success-glow);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            background-color: var(--success);
            border-radius: 50%;
            animation: pulse 1.5s infinite;
        }

        @keyframes pulse {
            0% { transform: scale(0.9); opacity: 0.6; }
            50% { transform: scale(1.3); opacity: 1; box-shadow: 0 0 10px var(--success); }
            100% { transform: scale(0.9); opacity: 0.6; }
        }

        .endpoints-title {
            text-align: left;
            font-size: 1.25rem;
            font-weight: 600;
            margin-bottom: 1.25rem;
            border-left: 4px solid var(--primary);
            padding-left: 0.75rem;
        }

        .endpoints-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 1rem;
            text-align: left;
            margin-bottom: 2rem;
        }

        @media(min-width: 600px) {
            .endpoints-grid {
                grid-template-columns: 1fr 1fr;
            }
        }

        .endpoint-card {
            background: rgba(15, 23, 42, 0.5);
            border: 1px solid rgba(255, 255, 255, 0.05);
            border-radius: 16px;
            padding: 1.25rem;
            transition: all 0.3s ease;
            cursor: pointer;
            text-decoration: none;
            display: block;
        }

        .endpoint-card:hover {
            transform: translateY(-3px);
            border-color: var(--primary);
            box-shadow: 0 10px 20px rgba(14, 165, 233, 0.05);
            background: rgba(15, 23, 42, 0.8);
        }

        .endpoint-header {
            display: flex;
            align-items: center;
            gap: 0.5rem;
            margin-bottom: 0.5rem;
        }

        .method {
            font-size: 0.75rem;
            font-weight: 800;
            padding: 0.25rem 0.5rem;
            border-radius: 6px;
            letter-spacing: 0.5px;
        }

        .method.get {
            background: rgba(16, 185, 129, 0.15);
            color: var(--success);
        }

        .method.post {
            background: rgba(245, 158, 11, 0.15);
            color: #F59E0B;
        }

        .path {
            font-family: monospace;
            font-size: 0.9rem;
            color: var(--text-main);
            font-weight: 600;
        }

        .desc {
            font-size: 0.85rem;
            color: var(--text-muted);
            line-height: 1.4;
        }

        footer {
            margin-top: 3rem;
            color: var(--text-muted);
            font-size: 0.85rem;
            font-weight: 300;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="logo-container">
            <span class="logo-icon">🌊</span>
        </div>
        <h1>Kuakata Travel Guide</h1>
        <p class="subtitle">Secure REST API Service for Android &amp; iOS App Clients</p>
        
        <div class="status-badge">
            <span class="status-dot"></span>
            <span>API Server Online &amp; Database Connected</span>
        </div>

        <h2 class="endpoints-title">Key Endpoints</h2>
        <div class="endpoints-grid">
            <a href="/api/health" class="endpoint-card" target="_blank">
                <div class="endpoint-header">
                    <span class="method get">GET</span>
                    <span class="path">/api/health</span>
                </div>
                <p class="desc">Verify system health, DB connection status, and server time.</p>
            </a>
            
            <a href="/api/content/hotel" class="endpoint-card" target="_blank">
                <div class="endpoint-header">
                    <span class="method get">GET</span>
                    <span class="path">/api/content/hotel</span>
                </div>
                <p class="desc">Fetch registered hotels and dynamic resort listings.</p>
            </a>

            <a href="/api/complaints" class="endpoint-card" target="_blank">
                <div class="endpoint-header">
                    <span class="method get">GET</span>
                    <span class="path">/api/complaints</span>
                </div>
                <p class="desc">View public complaints &amp; traveler feedback boards.</p>
            </a>

            <div class="endpoint-card">
                <div class="endpoint-header">
                    <span class="method post">POST</span>
                    <span class="path">/api/bookings</span>
                </div>
                <p class="desc">Submit hotel room booking or guide reservation requests.</p>
            </div>
        </div>

        <footer>
            Kuakata Travel App Backend Portal &bull; Running on Express Node.js &bull; Port ${PORT}
        </footer>
    </div>
</body>
</html>
  `);
});

// Test API Health
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    database: isUsingMongoDB ? 'MongoDB' : 'In-Memory Mock Database',
    timestamp: new Date()
  });
});

// Submit a Booking
app.post('/api/bookings', async (req, res) => {
  try {
    const bookingData = req.body;
    console.log('Received booking request:', bookingData);

    if (isUsingMongoDB) {
      const newBooking = new Booking(bookingData);
      const savedBooking = await newBooking.save();
      return res.status(201).json(savedBooking);
    } else {
      // Mock flow
      const mockBooking = {
        _id: 'mock_bk_' + Math.random().toString(36).substr(2, 9),
        ...bookingData,
        status: 'Pending',
        createdAt: new Date()
      };
      inMemoryBookings.push(mockBooking);
      return res.status(201).json(mockBooking);
    }
  } catch (error) {
    console.error('Error creating booking:', error);
    res.status(500).json({ error: 'Failed to create booking', details: error.message });
  }
});

// Get all Bookings
app.get('/api/bookings', async (req, res) => {
  try {
    if (isUsingMongoDB) {
      const bookings = await Booking.find().sort({ createdAt: -1 });
      return res.json(bookings);
    } else {
      return res.json(inMemoryBookings.slice().reverse());
    }
  } catch (error) {
    console.error('Error fetching bookings:', error);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
});

// Submit a Food Order
app.post('/api/orders', async (req, res) => {
  try {
    const orderData = req.body;
    console.log('Received food order:', orderData);

    if (isUsingMongoDB) {
      const newOrder = new FoodOrder(orderData);
      const savedOrder = await newOrder.save();
      return res.status(201).json(savedOrder);
    } else {
      // Mock flow
      const mockOrder = {
        _id: 'mock_ord_' + Math.random().toString(36).substr(2, 9),
        ...orderData,
        status: 'Ordered',
        createdAt: new Date()
      };
      inMemoryFoodOrders.push(mockOrder);
      return res.status(201).json(mockOrder);
    }
  } catch (error) {
    console.error('Error placing food order:', error);
    res.status(500).json({ error: 'Failed to place order', details: error.message });
  }
});

// Get all Food Orders
app.get('/api/orders', async (req, res) => {
  try {
    if (isUsingMongoDB) {
      const orders = await FoodOrder.find().sort({ createdAt: -1 });
      return res.json(orders);
    } else {
      return res.json(inMemoryFoodOrders.slice().reverse());
    }
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// ==================== USER REGISTRATION & LOGIN ====================

// Register a User
app.post('/api/users/register', async (req, res) => {
  try {
    const { name, address, mobile, hotelName, roomNumber, pin, email } = req.body;
    if (!name || !address || !mobile || !pin) {
      return res.status(400).json({ error: 'Name, address, mobile, and PIN/Password are required' });
    }
    if (pin.length < 6) {
      return res.status(400).json({ error: 'PIN/Password must be at least 6 characters' });
    }

    if (isUsingMongoDB) {
      const existingUser = await User.findOne({ mobile });
      if (existingUser) {
        return res.status(400).json({ error: 'An account with this mobile number already exists' });
      }

      if (email) {
        const existingEmail = await User.findOne({ email: email.trim().toLowerCase() });
        if (existingEmail) {
          return res.status(400).json({ error: 'An account with this email address already exists' });
        }
      }

      const newUser = new User({ name, address, mobile, hotelName, roomNumber, pin, email });
      const savedUser = await newUser.save();
      return res.status(201).json(savedUser);
    } else {
      const existingUser = inMemoryUsers.find(u => u.mobile === mobile);
      if (existingUser) {
        return res.status(400).json({ error: 'An account with this mobile number already exists' });
      }

      if (email) {
        const existingEmail = inMemoryUsers.find(u => u.email && u.email.toLowerCase() === email.trim().toLowerCase());
        if (existingEmail) {
          return res.status(400).json({ error: 'An account with this email address already exists' });
        }
      }

      const mockUser = {
        _id: 'mock_u_' + Math.random().toString(36).substr(2, 9),
        name,
        address,
        mobile,
        hotelName: hotelName || '',
        roomNumber: roomNumber || '',
        pin,
        email: email || '',
        role: 'user',
        managedHotelId: '',
        createdAt: new Date()
      };
      inMemoryUsers.push(mockUser);
      return res.status(201).json(mockUser);
    }
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ error: 'Failed to register user', details: error.message });
  }
});

// Login a User (by mobile number/email and PIN)
app.post('/api/users/login', async (req, res) => {
  try {
    const { identifier, pin } = req.body;
    if (!identifier || !pin) {
      return res.status(400).json({ error: 'Mobile number/Email and PIN are required' });
    }

    const trimmedIdentifier = identifier.trim();

    if (isUsingMongoDB) {
      const user = await User.findOne({
        $or: [
          { mobile: trimmedIdentifier },
          { email: trimmedIdentifier.toLowerCase() }
        ]
      });
      if (!user) {
        return res.status(444).json({ error: 'User not found with this mobile number or email' });
      }
      if (user.pin !== pin) {
        return res.status(401).json({ error: 'Incorrect PIN' });
      }
      return res.json(user);
    } else {
      const user = inMemoryUsers.find(u => 
        u.mobile === trimmedIdentifier || 
        (u.email && u.email.toLowerCase() === trimmedIdentifier.toLowerCase())
      );
      if (!user) {
        return res.status(444).json({ error: 'User not found with this mobile number or email' });
      }
      if (user.pin !== pin) {
        return res.status(401).json({ error: 'Incorrect PIN' });
      }
      return res.json(user);
    }
  } catch (error) {
    console.error('Error logging in:', error);
    res.status(500).json({ error: 'Failed to log in', details: error.message });
  }
});

// Google Login/Auto-Register endpoint
app.post('/api/users/google-login', async (req, res) => {
  try {
    const { email, name, googleId } = req.body;
    if (!email || !name) {
      return res.status(400).json({ error: 'Email and Name are required' });
    }

    const trimmedEmail = email.trim().toLowerCase();

    if (isUsingMongoDB) {
      let user = await User.findOne({ email: trimmedEmail });
      
      if (user) {
        if (!user.googleId && googleId) {
          user.googleId = googleId;
          await user.save();
        }
        let userObj = user.toObject();
        if (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') {
          userObj.isSuperAdmin = true;
        }
        return res.json(userObj);
      } else {
        const newUser = new User({
          name,
          email: trimmedEmail,
          googleId: googleId || 'mock_g_' + Math.random().toString(36).substr(2, 9),
          address: (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') ? 'Kuakata Admin Panel' : 'Google User',
          mobile: (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') ? 'admin' : '',
          pin: '000000',
          role: 'user'
        });
        const savedUser = await newUser.save();
        let userObj = savedUser.toObject();
        if (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') {
          userObj.isSuperAdmin = true;
        }
        return res.status(201).json(userObj);
      }
    } else {
      let user = inMemoryUsers.find(u => u.email && u.email.toLowerCase() === trimmedEmail);
      if (user) {
        if (!user.googleId && googleId) {
          user.googleId = googleId;
        }
        let userObj = { ...user };
        if (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') {
          userObj.isSuperAdmin = true;
        }
        return res.json(userObj);
      } else {
        const mockUser = {
          _id: 'mock_u_' + Math.random().toString(36).substr(2, 9),
          name,
          email: trimmedEmail,
          googleId: googleId || 'mock_g_' + Math.random().toString(36).substr(2, 9),
          address: (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') ? 'Kuakata Admin Panel' : 'Google User',
          mobile: (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') ? 'admin' : '',
          pin: '000000',
          role: 'user',
          managedHotelId: '',
          createdAt: new Date()
        };
        inMemoryUsers.push(mockUser);
        let userObj = { ...mockUser };
        if (trimmedEmail === 'admin@kuakata.com' || trimmedEmail === 'shuvokuakata27@gmail.com') {
          userObj.isSuperAdmin = true;
        }
        return res.status(201).json(userObj);
      }
    }
  } catch (error) {
    console.error('Error in Google login:', error);
    res.status(500).json({ error: 'Google authentication failed', details: error.message });
  }
});

// Update User Profile (e.g. for Google users filling in details)
app.put('/api/users/update-profile', async (req, res) => {
  try {
    const { email, mobile, address, hotelName, roomNumber } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const trimmedEmail = email.trim().toLowerCase();

    if (isUsingMongoDB) {
      const user = await User.findOne({ email: trimmedEmail });
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      if (mobile) {
        const existingMobile = await User.findOne({ mobile, email: { $ne: trimmedEmail } });
        if (existingMobile) {
          return res.status(400).json({ error: 'This mobile number is already in use by another account' });
        }
        user.mobile = mobile;
      }

      if (address) user.address = address;
      if (hotelName !== undefined) user.hotelName = hotelName;
      if (roomNumber !== undefined) user.roomNumber = roomNumber;

      await user.save();
      return res.json(user);
    } else {
      const userIndex = inMemoryUsers.findIndex(u => u.email && u.email.toLowerCase() === trimmedEmail);
      if (userIndex === -1) {
        return res.status(404).json({ error: 'User not found' });
      }

      if (mobile) {
        const existingMobile = inMemoryUsers.find(u => u.mobile === mobile && u.email.toLowerCase() !== trimmedEmail);
        if (existingMobile) {
          return res.status(400).json({ error: 'This mobile number is already in use by another account' });
        }
        inMemoryUsers[userIndex].mobile = mobile;
      }

      if (address) inMemoryUsers[userIndex].address = address;
      if (hotelName !== undefined) inMemoryUsers[userIndex].hotelName = hotelName;
      if (roomNumber !== undefined) inMemoryUsers[userIndex].roomNumber = roomNumber;

      return res.json(inMemoryUsers[userIndex]);
    }
  } catch (error) {
    console.error('Error updating user profile:', error);
    res.status(500).json({ error: 'Failed to update profile', details: error.message });
  }
});

// Reset User PIN (Forgot PIN recovery)
app.post('/api/users/reset-pin', async (req, res) => {
  try {
    const { mobile, name, newPin } = req.body;
    if (!mobile || !name || !newPin) {
      return res.status(400).json({ error: 'Mobile, name, and new PIN are required' });
    }
    if (newPin.length < 6) {
      return res.status(400).json({ error: 'New PIN/Password must be at least 6 characters' });
    }

    if (isUsingMongoDB) {
      const user = await User.findOne({ mobile });
      if (!user) {
        return res.status(404).json({ error: 'User not found with this mobile number' });
      }
      if (user.name.trim().toLowerCase() !== name.trim().toLowerCase()) {
        return res.status(400).json({ error: 'Verification failed. Name does not match.' });
      }

      user.pin = newPin;
      await user.save();
      return res.json({ message: 'PIN reset successfully' });
    } else {
      const user = inMemoryUsers.find(u => u.mobile === mobile);
      if (!user) {
        return res.status(404).json({ error: 'User not found with this mobile number' });
      }
      if (user.name.trim().toLowerCase() !== name.trim().toLowerCase()) {
        return res.status(400).json({ error: 'Verification failed. Name does not match.' });
      }

      user.pin = newPin;
      return res.json({ message: 'PIN reset successfully' });
    }
  } catch (error) {
    console.error('Error resetting PIN:', error);
    res.status(500).json({ error: 'Failed to reset PIN', details: error.message });
  }
});


// ==================== SUPER ADMIN LOGIN ====================

// Super Admin credentials (configurable via environment variables)
const SUPER_ADMIN_PASSWORD = process.env.SUPER_ADMIN_PASSWORD || 'KuakataAdmin@2026!Secure';

app.post('/api/admin/login', (req, res) => {
  try {
    const { username, password } = req.body;
    if (!password) {
      return res.status(400).json({ error: 'Password is required' });
    }

    const isValidAdmin = (username === 'adminkuakata' && password === 'W2bqZ1rzfFMe5dqN') ||
                          (!username && password === SUPER_ADMIN_PASSWORD);

    if (isValidAdmin) {
      return res.json({
        name: 'Super Admin',
        mobile: 'admin',
        address: 'Kuakata Admin Panel',
        hotelName: '',
        roomNumber: '',
        email: 'admin@kuakata.com',
        isSuperAdmin: true,
      });
    } else {
      return res.status(401).json({ error: 'Incorrect admin credentials' });
    }
  } catch (error) {
    console.error('Error in super admin login:', error);
    res.status(500).json({ error: 'Failed to authenticate', details: error.message });
  }
});



// Submit a review
app.post('/api/reviews', async (req, res) => {
  try {
    const { itemId, itemType, userName, rating, comment } = req.body;
    if (!itemId || !itemType || !userName || !rating || !comment) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    if (isUsingMongoDB) {
      const newReview = new Review({ itemId, itemType, userName, rating, comment });
      const savedReview = await newReview.save();
      return res.status(201).json(savedReview);
    } else {
      const mockReview = {
        _id: 'mock_rv_' + Math.random().toString(36).substr(2, 9),
        itemId,
        itemType,
        userName,
        rating: Number(rating),
        comment,
        createdAt: new Date()
      };
      inMemoryReviews.push(mockReview);
      return res.status(201).json(mockReview);
    }
  } catch (error) {
    console.error('Error submitting review:', error);
    res.status(500).json({ error: 'Failed to submit review', details: error.message });
  }
});

// Fetch reviews for a specific item
app.get('/api/reviews/:itemType/:itemId', async (req, res) => {
  try {
    const { itemType, itemId } = req.params;

    if (isUsingMongoDB) {
      const reviews = await Review.find({ itemType, itemId }).sort({ createdAt: -1 });
      return res.json(reviews);
    } else {
      const filtered = inMemoryReviews
        .filter(r => r.itemType === itemType && r.itemId === itemId)
        .slice()
        .reverse();
      return res.json(filtered);
    }
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});


// ==================== COMPLAINTS ====================

// Submit a complaint
app.post('/api/complaints', async (req, res) => {
  try {
    const { userName, userMobile, subject, description, image } = req.body;
    if (!userName || !userMobile || !subject || !description) {
      return res.status(400).json({ error: 'All fields except image are required' });
    }

    if (isUsingMongoDB) {
      const newComplaint = new Complaint({ userName, userMobile, subject, description, image: image || '' });
      const savedComplaint = await newComplaint.save();
      return res.status(201).json(savedComplaint);
    } else {
      const mockComplaint = {
        _id: 'mock_cp_' + Math.random().toString(36).substr(2, 9),
        userName,
        userMobile,
        subject,
        description,
        image: image || '',
        status: 'Pending',
        createdAt: new Date()
      };
      inMemoryComplaints.push(mockComplaint);
      return res.status(201).json(mockComplaint);
    }
  } catch (error) {
    console.error('Error creating complaint:', error);
    res.status(500).json({ error: 'Failed to create complaint', details: error.message });
  }
});

// Fetch complaints for a specific user
app.get('/api/complaints/:mobile', async (req, res) => {
  try {
    const { mobile } = req.params;

    if (isUsingMongoDB) {
      const complaints = await Complaint.find({ userMobile: mobile }).sort({ createdAt: -1 });
      return res.json(complaints);
    } else {
      const filtered = inMemoryComplaints
        .filter(c => c.userMobile === mobile)
        .slice()
        .reverse();
      return res.json(filtered);
    }
  } catch (error) {
    console.error('Error fetching complaints:', error);
    res.status(500).json({ error: 'Failed to fetch complaints' });
  }
});

// Fetch all reviews (Admin)
app.get('/api/admin/reviews', async (req, res) => {
  try {
    if (isUsingMongoDB) {
      const reviews = await Review.find().sort({ createdAt: -1 });
      return res.json(reviews);
    } else {
      const sorted = inMemoryReviews.slice().sort((a, b) => b.createdAt - a.createdAt);
      return res.json(sorted);
    }
  } catch (error) {
    console.error('Error fetching all reviews:', error);
    res.status(500).json({ error: 'Failed to fetch reviews' });
  }
});

// Fetch all complaints (Admin)
app.get('/api/admin/complaints', async (req, res) => {
  try {
    if (isUsingMongoDB) {
      const complaints = await Complaint.find().sort({ createdAt: -1 });
      return res.json(complaints);
    } else {
      const sorted = inMemoryComplaints.slice().sort((a, b) => b.createdAt - a.createdAt);
      return res.json(sorted);
    }
  } catch (error) {
    console.error('Error fetching all complaints:', error);
    res.status(500).json({ error: 'Failed to fetch complaints' });
  }
});

// Fetch all complaints (Public)
app.get('/api/complaints', async (req, res) => {
  try {
    if (isUsingMongoDB) {
      const complaints = await Complaint.find().sort({ createdAt: -1 });
      return res.json(complaints);
    } else {
      const sorted = inMemoryComplaints.slice().sort((a, b) => b.createdAt - a.createdAt);
      return res.json(sorted);
    }
  } catch (error) {
    console.error('Error fetching public complaints:', error);
    res.status(500).json({ error: 'Failed to fetch complaints' });
  }
});

// Reply to a review (Admin)
app.put('/api/admin/reviews/:id/reply', async (req, res) => {
  try {
    const { id } = req.params;
    const { reply } = req.body;

    if (isUsingMongoDB) {
      const updatedReview = await Review.findByIdAndUpdate(
        id,
        { adminReply: reply },
        { new: true }
      );
      if (!updatedReview) return res.status(404).json({ error: 'Review not found' });
      return res.json(updatedReview);
    } else {
      const reviewIndex = inMemoryReviews.findIndex(r => r._id === id);
      if (reviewIndex === -1) return res.status(404).json({ error: 'Review not found' });
      inMemoryReviews[reviewIndex].adminReply = reply;
      return res.json(inMemoryReviews[reviewIndex]);
    }
  } catch (error) {
    console.error('Error replying to review:', error);
    res.status(500).json({ error: 'Failed to reply to review' });
  }
});

// Reply to a complaint and update status (Admin)
app.put('/api/admin/complaints/:id/reply', async (req, res) => {
  try {
    const { id } = req.params;
    const { reply, status } = req.body;

    if (isUsingMongoDB) {
      const updateData = { adminReply: reply };
      if (status) updateData.status = status;

      const updatedComplaint = await Complaint.findByIdAndUpdate(
        id,
        updateData,
        { new: true }
      );
      if (!updatedComplaint) return res.status(404).json({ error: 'Complaint not found' });
      return res.json(updatedComplaint);
    } else {
      const complaintIndex = inMemoryComplaints.findIndex(c => c._id === id);
      if (complaintIndex === -1) return res.status(404).json({ error: 'Complaint not found' });
      
      inMemoryComplaints[complaintIndex].adminReply = reply;
      if (status) inMemoryComplaints[complaintIndex].status = status;
      
      return res.json(inMemoryComplaints[complaintIndex]);
    }
  } catch (error) {
    console.error('Error replying to complaint:', error);
    res.status(500).json({ error: 'Failed to reply to complaint' });
  }
});



// ==================== DYNAMIC CONTENT CRUD & SEEDING ====================

// Mock in-memory content storage
const inMemoryContent = [];

// Seed Data Definition
const seedContentData = {
  hotel: [
    {
      name_en: 'Kuakata Grand Hotel & Resort',
      name_bn: 'কুয়াকাটা গ্র্যান্ড হোটেল ও রিসোর্ট',
      image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
      rating: 4.8,
      reviews: 312,
      distance_en: '150m from Beach',
      distance_bn: 'সৈকত থেকে ১৫০ মিটার',
      priceRange: '৳5,000 - ৳12,000',
      phone: '01711223344',
      tags_en: ['5-Star', 'Pool', 'Sea View', 'Breakfast'],
      tags_bn: ['৫-তারকা', 'সুইমিং পুল', 'সী ভিউ', 'নাস্তা ফ্রি'],
      desc_en: 'Kuakata Grand Hotel & Resort offers high-end luxury with panoramic views of the Bay of Bengal. Features an infinity pool, fully equipped gym, spa, and fine dining.',
      desc_bn: 'কুয়াকাটা গ্র্যান্ড হোটেল ও রিসোর্ট বঙ্গোপসাগরের মনোরম দৃশ্য সহ বিলাসবহুল সেবা প্রদান করে। এখানে রয়েছে ইনফিনিটি পুল, জিম, স্পা এবং রেস্টুরেন্ট সুবিধা।',
      rooms: [
        {
          name_en: 'Deluxe Double Room',
          name_bn: 'ডিলাক্স ডাবল রুম',
          price: 5000,
          image: 'https://images.unsplash.com/photo-1611891405788-d130a84e2d9a?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['1 King Bed', 'AC', 'TV', 'Free Wi-Fi', 'Garden View'],
          amenities_bn: ['১টি কিং বেড', 'এসি', 'টিভি', 'ফ্রি ওয়াই-ফাই', 'গার্ডেন ভিউ']
        },
        {
          name_en: 'Ocean View Premier Room',
          name_bn: 'ওশেন ভিউ প্রিমিয়ার রুম',
          price: 8000,
          image: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['1 King Bed', 'AC', 'TV', 'Ocean View Balcony', 'Minibar'],
          amenities_bn: ['১টি কিং বেড', 'এসি', 'টিভি', 'সমুদ্রমুখী বারান্দা', 'মিনিবার']
        },
        {
          name_en: 'Presidential Ocean Suite',
          name_bn: 'প্রেসিডেন্সিয়াল ওশেন স্যুইট',
          price: 12000,
          image: 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['2 King Beds', 'Living Room', 'AC', 'Private Jacuzzi', 'Balcony'],
          amenities_bn: ['২টি কিং বেড', 'লিভিং রুম', 'এসি', 'প্রাইভেট জাকুজি', 'বারান্দা']
        }
      ]
    },
    {
      name_en: 'Hotel Graver Inn International',
      name_bn: 'হোটেল গ্রেভার ইন ইন্টারন্যাশনাল',
      image: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?auto=format&fit=crop&w=600&q=80',
      rating: 4.5,
      reviews: 240,
      distance_en: '200m from Beach',
      distance_bn: 'সৈকত থেকে ২০০ মিটার',
      priceRange: '৳3,500 - ৳7,500',
      phone: '01722334455',
      tags_en: ['Rooftop Cafe', 'AC Rooms', 'Conference Hall'],
      tags_bn: ['ছাদ ক্যাফে', 'এসি রুম', 'কনফারেন্স হল'],
      desc_en: 'Located in the popular hotel zone, Hotel Graver Inn is known for its warm hospitality, elegant rooms, and delicious seafood served at its rooftop BBQ restaurant.',
      desc_bn: 'জনপ্রিয় হোটেল জোনে অবস্থিত হোটেল গ্রেভার ইন তার চমৎকার আতিথেয়তা, সুন্দর সাজানো রুম এবং ছাদের ওপর সুস্বাদু সীফুড বারবিকিউ রেস্টুরেন্টের জন্য পরিচিত।',
      rooms: [
        {
          name_en: 'Standard Couple AC Room',
          name_bn: 'স্ট্যান্ডার্ড কাপল এসি রুম',
          price: 3500,
          image: 'https://images.unsplash.com/photo-1590490360182-c33d57733427?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['1 Double Bed', 'AC', 'TV', 'Free Wi-Fi'],
          amenities_bn: ['১টি ডাবল বেড', 'এসি', 'টিভি', 'ফ্রি ওয়াই-ফাই']
        },
        {
          name_en: 'Executive Deluxe Twin',
          name_bn: 'এক্সিকিউটিভ ডিলাক্স টুইন',
          price: 5500,
          image: 'https://images.unsplash.com/photo-1566665797739-1674de7a421a?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['2 Semi-Double Beds', 'AC', 'Work Desk', 'Breakfast Included'],
          amenities_bn: ['২টি সেমি-ডাবল বেড', 'এসি', 'ওয়ার্ক ডেস্ক', 'নাস্তা ফ্রি']
        },
        {
          name_en: 'Family Grand Suite',
          name_bn: 'ফ্যামিলি গ্র্যান্ড স্যুইট',
          price: 7500,
          image: 'https://images.unsplash.com/photo-1591088398332-8a7791972843?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['2 King Beds', 'AC', 'Balcony', 'Spacious Seating'],
          amenities_bn: ['২টি কিং বেড', 'এসি', 'বারান্দা', 'বসার জায়গা']
        }
      ]
    },
    {
      name_en: 'Hotel Sea Haven',
      name_bn: 'হোটেল সী হ্যাভেন',
      image: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?auto=format&fit=crop&w=600&q=80',
      rating: 4.1,
      reviews: 185,
      distance_en: '100m from Beach',
      distance_bn: 'সৈকত থেকে ১০০ মিটার',
      priceRange: '৳2,000 - ৳4,500',
      phone: '01733445566',
      tags_en: ['Beachfront', 'Budget Friendly', 'Tour Desk'],
      tags_bn: ['সৈকতের সামনে', 'সাশ্রয়ী বাজেট', 'ট্যুর ডেস্ক'],
      desc_en: 'An excellent budget-friendly choice right next to the beach access point. Clean, spacious rooms and helpful staff who can arrange local sightseeing boat tours.',
      desc_bn: 'সৈকতে প্রবেশের রাস্তার ঠিক পাশেই একটি চমৎকার বাজেট-বান্ধব হোটেল। পরিষ্কার-পরিচ্ছন্ন, প্রশস্ত রুম এবং চমৎকার সার্ভিস প্রদানকারী স্টাফ।',
      rooms: [
        {
          name_en: 'Budget Non-AC Couple',
          name_bn: 'বাজেট নন-এসি কাপল রুম',
          price: 2000,
          image: 'https://images.unsplash.com/photo-1596394516093-501ba68a0ba6?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['1 Double Bed', 'Ceiling Fan', 'Attached Bath', 'Wi-Fi'],
          amenities_bn: ['১টি ডাবল বেড', 'সিলিং ফ্যান', 'সংযুক্ত বাথরুম', 'ওয়াই-ফাই']
        },
        {
          name_en: 'Standard AC Couple Room',
          name_bn: 'স্ট্যান্ডার্ড এসি কাপল রুম',
          price: 3000,
          image: 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['1 King Bed', 'AC', 'TV', 'Free Wi-Fi'],
          amenities_bn: ['১টি কিং বেড', 'এসি', 'টিভি', 'ফ্রি ওয়াই-ফাই']
        },
        {
          name_en: 'Deluxe Family AC Room',
          name_bn: 'ডিলাক্স ফ্যামিলি এসি রুম',
          price: 4500,
          image: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=400&q=80',
          amenities_en: ['2 Double Beds', 'AC', 'TV', 'Balcony'],
          amenities_bn: ['২টি ডাবল বেড', 'এসি', 'টিভি', 'বারান্দা']
        }
      ]
    }
  ],
  bike: [
    {
      name_en: 'Rahat Hasan',
      name_bn: 'রাহাত হাসান',
      bike_en: 'Yamaha FZ-S v3 (150cc)',
      bike_bn: 'ইয়ামাহা এফজেড-এস ভার্সন ৩ (১৫০ সিসি)',
      price_en: '৳1,000 / day',
      price_bn: '৳১,০০০ / দিন',
      rating: 4.9,
      rides: 142,
      phone: '01744556677',
      image: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
      experience_en: '3+ years experience. English speaking guide.',
      experience_bn: '৩+ বছরের অভিজ্ঞতা। চমৎকার গাইড হিসেবে পরিচিত।',
    },
    {
      name_en: 'Sajid Ahmed',
      name_bn: 'সাজিদ আহমেদ',
      bike_en: 'Suzuki Gixxer SF (150cc)',
      bike_bn: 'সুজুকি জিক্সার এসএফ (১৫০ সিসি)',
      price_en: '৳1,200 / day',
      price_bn: '৳১,২০০ / দিন',
      rating: 4.8,
      rides: 118,
      phone: '01755667788',
      image: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80',
      experience_en: 'Safe rider. Knows all hidden spots in Kuakata.',
      experience_bn: 'নিরাপদ রাইডার। কুয়াকাটার সব দর্শনীয় স্থান চেনেন।',
    },
    {
      name_en: 'Kamrul Islam',
      name_bn: 'কামরুল ইসলাম',
      bike_en: 'Honda Hornet 160R',
      bike_bn: 'হোন্ডা হর্নেট ১৬০আর',
      price_en: '৳900 / day',
      price_bn: '৳৯০০ / দিন',
      rating: 4.7,
      rides: 95,
      phone: '01766778899',
      image: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80',
      experience_en: 'Very friendly and helpful. Low budget option.',
      experience_bn: 'খুবই বন্ধুত্বপূর্ণ ও সহায়তাকারী। কম বাজেট অপশন।',
    }
  ],
  van: [
    {
      name_en: 'Abul Kalam',
      name_bn: 'আবুল কালাম',
      van_en: 'Electric Easy Van (6 Seats)',
      van_bn: 'ইলেকট্রিক ইজি ভ্যান (৬ সিট)',
      price_en: '৳150 / hour',
      price_bn: '৳১৫০ / ঘণ্টা',
      rating: 4.7,
      trips: 185,
      phone: '01811223344',
      image: 'https://images.unsplash.com/photo-1542909168-82c3e7fdca5c?auto=format&fit=crop&w=300&q=80',
      details_en: 'Friendly local guide. Eco-friendly silent transit.',
      details_bn: 'বন্ধুত্বপূর্ণ আচরণ। পরিবেশবান্ধব ও নীরব গাড়ি।',
    },
    {
      name_en: 'Mizanur Rahman',
      name_bn: 'মিজানুর রহমান',
      van_en: 'Engine Rickshaw Van (8 Seats)',
      van_bn: 'ইঞ্জিন রিকশা ভ্যান (৮ সিট)',
      price_en: '৳120 / hour',
      price_bn: '৳১২০ / ঘণ্টা',
      rating: 4.8,
      trips: 210,
      phone: '01822334455',
      image: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      details_en: 'Knows all local spots. Best for gang/family tour.',
      details_bn: 'স্থানীয় সমস্ত এলাকা চেনেন। গ্রুপ/ফ্যামিলি ট্যুরের জন্য সেরা।',
    },
    {
      name_en: 'Solaiman Ali',
      name_bn: 'সোলায়মান আলী',
      van_en: 'Classic Cargo/Passenger Van',
      van_bn: 'ক্লাসিক কার্গো/প্যাসেঞ্জার ভ্যান',
      price_en: '৳100 / hour',
      price_bn: '৳১০০ / ঘণ্টা',
      rating: 4.6,
      trips: 94,
      phone: '01833445566',
      image: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
      details_en: 'Safe speed driving. Great for carrying heavy baggage.',
      details_bn: 'নিরাপদ গতিতে ড্রাইভ করেন। ভারী ব্যাগ বহনের জন্য উপযোগী।',
    }
  ],
  board: [
    {
      name_en: 'Milon Hossain',
      name_bn: 'মিলন হোসাইন',
      boat_en: 'Yamaha Outboard Speedboat (40 HP)',
      boat_bn: 'ইয়ামাহা আউটবোর্ড স্পিডবোট (৪০ হর্সপাওয়ার)',
      price_en: '৳1,500 / trip (Red Crab Island)',
      price_bn: '৳১,৫০০ / ট্রিপ (লাল কাঁকড়ার চর)',
      rating: 4.9,
      trips: 254,
      phone: '01911223344',
      image: 'https://images.unsplash.com/photo-1500048993953-d23a436266cf?auto=format&fit=crop&w=300&q=80',
      details_en: 'Certified life-guard driver. Safe and adventurous.',
      details_bn: 'সার্টিফাইড লাইফ-গার্ড চালক। নিরাপদ ও রোমাঞ্চকর রাইড।',
    },
    {
      name_en: 'Rubel Mia',
      name_bn: 'রুবেল মিয়া',
      boat_en: 'Mercury Speedboat (50 HP)',
      boat_bn: 'মার্কারি স্পিডবোট (৫০ হর্সপাওয়ার)',
      price_en: '৳1,800 / trip (Gangamati Point)',
      price_bn: '৳১,৮০০ / ট্রিপ (গঙ্গামতি পয়েন্ট)',
      rating: 4.8,
      trips: 198,
      phone: '01922334455',
      image: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=300&q=80',
      details_en: 'Great local guide. Provides premium life jackets.',
      details_bn: 'চমৎকার গাইড। প্রিমিয়াম লাইফ জ্যাকেট সুবিধা রয়েছে।',
    }
  ],
  boat: [
    {
      name_en: 'Kalam Majhi',
      name_bn: 'কালাম মাঝি',
      boat_en: 'Traditional Wooden Engine Boat (12 Seats)',
      boat_bn: 'ঐতিহ্যবাহী কাঠের ইঞ্জিন চালিত নৌকা (১২ সিট)',
      price_en: '৳800 / hour',
      price_bn: '৳৮০০ / ঘণ্টা',
      rating: 4.7,
      trips: 312,
      phone: '01511223344',
      image: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=300&q=80',
      details_en: '30+ years sailing in Kuakata. Great storyteller and local guide.',
      details_bn: 'কুয়াকাটায় ৩০+ বছরের নৌযান চালনার অভিজ্ঞতা। চমৎকার গল্পকার ও স্থানীয় গাইড।',
    },
    {
      name_en: 'Alom Majhi',
      name_bn: 'আলম মাঝি',
      boat_en: 'Large Tourist Trawler Boat (20 Seats)',
      boat_bn: 'বড় ট্যুরিস্ট ট্রলার বোট (২০ সিট)',
      price_en: '৳1,200 / hour',
      price_bn: '৳১,২০০ / ঘণ্টা',
      rating: 4.6,
      trips: 240,
      phone: '01522334455',
      image: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=300&q=80',
      details_en: 'Perfect for family and corporate group tours. Lifebuoys included.',
      details_bn: 'পারিবারিক এবং কর্পোরেট গ্রুপ ট্যুরের জন্য উপযুক্ত। লাইফবয়া সুবিধা সহ।',
    }
  ],
  food: [
    {
      id: 'dish_ilish',
      name_en: 'Shorshe Ilish (Hilsa Fish)',
      name_bn: 'সরিষা ইলিশ',
      desc_en: 'Traditional Bengali style Hilsa fish cooked with rich mustard gravy.',
      desc_bn: 'সরিষার ঝোল দিয়ে রান্না করা ঐতিহ্যবাহী ইলিশ মাছ।',
      image: 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?auto=format&fit=crop&w=400&q=80',
      offers: [
        {restaurant: 'Hotel Graver Inn Restaurant', price: 280, rating: 4.5},
        {restaurant: 'Kuakata Grand Resort Dining', price: 350, rating: 4.8},
        {restaurant: 'Shura Restaurant & BBQ Stalls', price: 220, rating: 4.4}
      ]
    },
    {
      id: 'dish_crab',
      name_en: 'Beachside Spicy Crab Fry',
      name_bn: 'স্পাইসি কাঁকড়া ফ্রাই',
      desc_en: 'Fresh sea crab fried with hot local spices and green chilies.',
      desc_bn: 'তাজা সামুদ্রিক কাঁকড়া ও দেশীয় মশলা দিয়ে ভাজা।',
      image: 'https://images.unsplash.com/photo-1553618551-fba689030290?auto=format&fit=crop&w=400&q=80',
      offers: [
        {restaurant: 'Shura Restaurant & BBQ Stalls', price: 160, rating: 4.3},
        {restaurant: 'Hotel Sea Girl Restaurant', price: 180, rating: 4.2},
        {restaurant: 'Kuakata Grand Resort Dining', price: 240, rating: 4.7}
      ]
    },
    {
      id: 'dish_koral',
      name_en: 'Grilled Koral Fish BBQ',
      name_bn: 'কোরাল ফিশ বারবিকিউ',
      desc_en: 'Freshly caught Koral fish marinated and grilled over charcoal.',
      desc_bn: 'তাজা কোরাল মাছ কয়লার আগুনে পোড়ানো বারবিকিউ।',
      image: 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?auto=format&fit=crop&w=400&q=80',
      offers: [
        {restaurant: 'Shura Restaurant & BBQ Stalls', price: 420, rating: 4.5},
        {restaurant: 'Hotel Graver Inn Restaurant', price: 480, rating: 4.4},
        {restaurant: 'Kuakata Grand Resort Dining', price: 580, rating: 4.8}
      ]
    },
    {
      id: 'dish_lobster',
      name_en: 'Grilled Lobster BBQ',
      name_bn: 'গ্রিলড লবস্টার বারবিকিউ',
      desc_en: 'Fresh lobster marinated in garlic butter sauce and barbecued.',
      desc_bn: 'রসুন-মাখনের সস দিয়ে প্রস্তুতকৃত তাজা গলদা চিংড়ি বারবিকিউ।',
      image: 'https://images.unsplash.com/photo-1559737633-8a1800839aba?auto=format&fit=crop&w=400&q=80',
      offers: [
        {restaurant: 'Hotel Graver Inn Restaurant', price: 950, rating: 4.6},
        {restaurant: 'Kuakata Grand Resort Dining', price: 1200, rating: 4.9},
        {restaurant: 'Shura Restaurant & BBQ Stalls', price: 850, rating: 4.2}
      ]
    },
    {
      id: 'dish_coconut',
      name_en: 'Fresh Green Coconut Water',
      name_bn: 'তাজা ডাবের পানি',
      desc_en: 'Sweet and refreshing natural green coconut water from Kuakata beach.',
      desc_bn: 'মিষ্টি ও স্বাস্থ্যকর তাজা সৈকতের ডাব।',
      image: 'https://images.unsplash.com/photo-1525385133512-2f3bdd039054?auto=format&fit=crop&w=400&q=80',
      offers: [
        {restaurant: 'Local Beach Umbrella Stalls', price: 60, rating: 4.8},
        {restaurant: 'Cafe de Kuakata', price: 80, rating: 4.6}
      ]
    }
  ],
  spot: [
    {
      title_en: 'Kuakata Sea Beach',
      title_bn: 'কুয়াকাটা সমুদ্র সৈকত',
      desc_en: 'The main sandy beach, famous for viewing both sunrise and sunset.',
      desc_bn: 'প্রধান সৈকত, যা সূর্যোদয় এবং সূর্যাস্ত উভয় দেখার জন্য বিখ্যাত।',
      image: 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?auto=format&fit=crop&w=500&q=80',
      about_en: 'Kuakata Beach is a panoramic sandy beach situated in southern Bangladesh. It is one of the rarest beaches in the world that allows visitors to witness both the sunrise and sunset over the Bay of Bengal. The beach is approximately 18 kilometers long and 3 kilometers wide. It is a holy site for both Hindu and Buddhist communities, who come here during festivals like Rash Purnima.',
      about_bn: 'কুয়াকাটা সমুদ্র সৈকত বাংলাদেশের দক্ষিণ-পশ্চিমাঞ্চলের একটি অপরূপ বালুময় সৈকত। এটি বিশ্বের অন্যতম বিরল সৈকত যা দর্শনার্থীদের বঙ্গোপসাগরের ওপর একই সাথে সূর্যোদয় এবং সূর্যাস্ত দেখার সুযোগ দেয়। এই সৈকতটি দৈর্ঘ্য প্রায় ১৮ কিলোমিটার এবং প্রস্থে ৩ কিলোমিটার। এটি হিন্দু ও বৌদ্ধ সম্প্রদায়ের জন্য একটি পবিত্র স্থান, যা রাস পূর্ণিমার মতো উত্সবের সময় মুখরিত হয়ে ওঠে।',
      tips_en: '• Best time for Sunrise is 5:00 AM - 6:00 AM.\n• Avoid littering on the beach to preserve its natural beauty.\n• Beach photography is widely available by local photographers.',
      tips_bn: '• সূর্যোদয়ের সবচেয়ে ভালো সময় হলো ভোর ৫:০০ টা থেকে ৬:০০ টা।\n• সৈকতের প্রাকৃতিক সৌন্দর্য রক্ষা করতে ময়লা-আবর্জনা ফেলা থেকে বিরত থাকুন।\n• স্থানীয় ফটোগ্রাফারদের মাধ্যমে ছবি তোলার সুবিধা রয়েছে।',
      location_en: 'Kuakata, Patuakhali, Bangladesh',
      location_bn: 'কুয়াকাটা, পটুয়াখালী, বাংলাদেশ',
      timings_en: 'Open 24 Hours',
      timings_bn: '২৪ ঘণ্টা খোলা',
      transport_en: 'Walking distance from the center, or local rickshaw.',
      transport_bn: 'কেন্দ্রীয় মোড় থেকে হাঁটার দূরত্ব, অথবা ভ্যানে যাওয়া যায়।'
    },
    {
      title_en: 'Gangamati Forest',
      title_bn: 'গঙ্গামতির জঙ্গল',
      desc_en: 'A dense evergreen forest on the eastern side, ideal for seeing sunrise.',
      desc_bn: 'পূর্ব দিকের একটি ঘন চিরহরিৎ বন, সূর্যোদয় দেখার জন্য আদর্শ।',
      image: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=500&q=80',
      about_en: 'Gangamati Protected Forest is located on the eastern side of the Kuakata beach. It is a dense mangrove forest that acts as a natural shield for the coastline. Visitors can reach here by walking or taking a motorcycle from the main beach. It is an excellent spot for bird watching, exploring local flora and fauna, and witnessing a pristine sunrise.',
      about_bn: 'গঙ্গামতি সংরক্ষিত বন কুয়াকাটা সৈকতের পূর্ব দিকে অবস্থিত। এটি একটি ঘন ম্যানগ্রোভ বন যা উপকূলের জন্য প্রাকৃতিক ঢাল হিসেবে কাজ করে। দর্শনার্থীরা হেঁটে বা প্রধান সৈকত থেকে মোটরসাইকেলে এখানে পৌঁছাতে পারেন। এটি পাখি দেখার, স্থানীয় উদ্ভিদ ও প্রাণী অন্বেষণ করার এবং আদিম সূর্যোদয় উপভোগ করার জন্য একটি চমৎকার স্থান।',
      tips_en: '• Ride a local motorcycle for a convenient and fast trip.\n• Visit early in the morning to catch the spectacular sunrise.\n• Carry drinking water and light snacks with you.',
      tips_bn: '• সুবিধাজনক ও দ্রুত যাতায়াতের জন্য স্থানীয় মোটরসাইকেল ব্যবহার করুন।\n• চমৎকার সূর্যোদয় দেখতে খুব ভোরে চলে যান।\n• সাথে খাবার পানি এবং হালকা খাবার রাখুন।',
      location_en: '10 km East from Kuakata Main Beach',
      location_bn: 'কুয়াকাটা মূল সৈকত থেকে ১০ কিমি পূর্বে',
      timings_en: '6:00 AM - 6:00 PM',
      timings_bn: 'সকাল ৬:০০ টা - সন্ধ্যা ৬:০০ টা',
      transport_en: 'Motorcycle rental, speedboat, or local tourist engine boat.',
      transport_bn: 'মোটরসাইকেল, স্পিডবোট অথবা ট্যুরিস্ট ট্রলার।'
    },
    {
      title_en: 'Jhau Forest',
      title_bn: 'ঝাউবন',
      desc_en: 'A beautiful forest of Casuarina trees offering fresh air and picnic spots.',
      desc_bn: 'ঝাউ গাছের একটি সুন্দর বন যা তাজা বাতাস এবং পিকনিকের স্পট প্রদান করে।',
      image: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=500&q=80',
      about_en: 'Jhau Forest (Casuarina Forest) is located near the beach on the eastern side. It was created by the forest department to prevent soil erosion. The forest provides a cool, shady canopy with the soothing sound of wind passing through the trees. It is a very popular spot for photography, walking, and family picnics.',
      about_bn: 'ঝাউবন (ঝাউগাছের বন) পূর্ব দিকের সৈকতের কাছে অবস্থিত। মাটির ক্ষয় রোধে বন বিভাগ এটি তৈরি করে। বনটি গাছের মধ্য দিয়ে বাতাস বয়ে যাওয়ার মৃদু শব্দের সাথে একটি শীতল, ছায়াময় পরিবেশ তৈরি করে। এটি ছবি তোলা, হাঁটাচলা এবং পারিবারিক পিকনিকের জন্য একটি অত্যন্ত জনপ্রিয় স্থান।',
      tips_en: '• Great spot for photography during late afternoon.\n• Walking through the pine-like trees is highly refreshing.\n• Respect nature and do not disturb the local wildlife.',
      tips_bn: '• শেষ বিকেলে ছবি তোলার জন্য এটি চমৎকার একটি স্থান।\n• ঝাউগাছের মধ্য দিয়ে হাঁটা অত্যন্ত সতেজ অনুভূতি দেয়।\n• প্রকৃতির প্রতি যত্নশীল হোন এবং বন্যপ্রাণীদের বিরক্ত করবেন না।',
      location_en: 'Eastern side of Kuakata Beach',
      location_bn: 'কুয়াকাটা সৈকতের পূর্ব প্রান্ত',
      timings_en: 'Sunrise to Sunset',
      timings_bn: 'সূর্যোদয় থেকে সূর্যাস্ত',
      transport_en: 'Walking distance, or local van/rickshaw.',
      transport_bn: 'সহজেই হেঁটে অথবা ভ্যানে যাওয়া যায়।'
    },
    {
      title_en: 'Red Crab Beach',
      title_bn: 'লাল কাঁকড়ার চর',
      desc_en: 'A serene beach where thousands of red crabs emerge, creating a red carpet.',
      desc_bn: 'একটি শান্ত সৈকত যেখানে হাজার হাজার লাল কাঁকড়া উঠে আসে, লাল গালিচা তৈরি করে।',
      image: 'https://images.unsplash.com/photo-1601662528567-526cd06f6582?auto=format&fit=crop&w=500&q=80',
      about_en: 'Red Crab Beach (Lal Kakrar Char) is a magical sanctuary situated near the Jhau forest. During low tide, millions of tiny red crabs emerge from their sand holes, coloring the entire beach in a vibrant crimson red. As soon as they sense footsteps, they quickly vanish back into the sand, creating a captivating spectacle.',
      about_bn: 'লাল কাঁকড়ার চর হলো ঝাউবনের কাছে অবস্থিত একটি জাদুকরী অভয়ারণ্য। জোয়ারের পর যখন পানি নেমে যায়, তখন লাখ লাখ ছোট লাল কাঁকড়া তাদের বালির গর্ত থেকে বের হয়ে আসে এবং পুরো সৈকতকে লাল গালিচায় রূপান্তর করে। মানুষের পায়ের শব্দ পাওয়া মাত্রই তারা বালির নিচে লুকিয়ে যায়, যা একটি চমৎকার দৃশ্য তৈরি করে।',
      tips_en: '• Walk quietly and avoid making loud noises to see the crabs up close.\n• Keep a distance and do not capture or step on the crabs.\n• Check the local tide table before planning your trip.',
      tips_bn: '• কাঁকড়াগুলোকে কাছ থেকে দেখতে শান্তভাবে হাঁটুন এবং জোরে শব্দ করা এড়িয়ে চলুন।\n• দূরত্ব বজায় রাখুন এবং কাঁকড়া ধরার বা তাদের উপর পা দেওয়ার চেষ্টা করবেন না।\n• ভ্রমণের পরিকল্পনা করার আগে স্থানীয় জোয়ার-ভাটার সময়সূচী দেখে নিন।',
      location_en: 'Near Jhau Forest, Patuakhali',
      location_bn: 'ঝাউবনের নিকটে, কুয়াকাটা',
      timings_en: 'Best viewed during low tide',
      timings_bn: 'ভাটার সময় সবচেয়ে ভালো দেখা যায়',
      transport_en: 'Local motor-bike or boat ride.',
      transport_bn: 'মোটরসাইকেল অথবা নৌকা চালকদের মাধ্যমে যাওয়া যায়।'
    },
    {
      title_en: 'Misripara Temple',
      title_bn: 'মিশ্রিপাড়া মন্দির',
      desc_en: 'Misripara Buddhist Temple housing the largest statue of Buddha in the region.',
      desc_bn: 'মিশ্রিপাড়া বৌদ্ধ মন্দির যেখানে এই অঞ্চলের সবচেয়ে বড় বুদ্ধ মূর্তি রয়েছে।',
      image: 'https://images.unsplash.com/photo-1609137144814-4c4f34cf33fb?auto=format&fit=crop&w=500&q=80',
      about_en: 'Misripara Buddhist Temple is located about 12 kilometers from Kuakata beach. It houses the largest Buddhist statue in the sub-continent, standing at approximately 30 feet tall. The temple reflects the rich cultural heritage and historical presence of the Rakhaine community in this region. There is also an ancient well inside the temple premises.',
      about_bn: 'মিশ্রিপাড়া বৌদ্ধ মন্দির কুয়াকাটা সৈকত থেকে প্রায় ১২ কিলোমিটার দূরে অবস্থিত। এতে উপমহাদেশে সবচেয়ে বড় বুদ্ধ মূর্তি রয়েছে, যা প্রায় ৩০ ফুট উঁচু। মন্দিরটি এই অঞ্চলে রাখাইন সম্প্রদায়ের সমৃদ্ধ সাংস্কৃতিক ঐতিহ্য এবং ঐতিহাসিক উপস্থিতি প্রতিফলিত করে। মন্দির প্রাঙ্গণে একটি প্রাচীন কূপও রয়েছে।',
      tips_en: '• Wear modest clothing and remove shoes before entering the temple.\n• Respect the religious practices of the devotees.\n• You can buy traditional Rakhaine handloom products nearby.',
      tips_bn: '• শালীন পোশাক পরিধান করুন এবং মন্দিরে প্রবেশের আগে জুতো খুলে নিন।\n• ভক্তদের ধর্মীয় আচার-অনুষ্ঠানের প্রতি শ্রদ্ধা প্রদর্শন করুন।\n• কাছেই ঐতিহ্যবাহী রাখাইন হস্তশিল্পের তৈরি পণ্য কেনাকাটা করতে পারেন।',
      location_en: 'Misripara Rakhaine Village, Patuakhali',
      location_bn: 'মিশ্রিপাড়া রাখাইন পল্লী, কুয়াকাটা',
      timings_en: '8:00 AM - 6:00 PM',
      timings_bn: 'সকাল ৮:০০ টা - সন্ধ্যা ৬:০০ টা',
      transport_en: 'Motorcycle or local auto-rickshaw (Tomtom).',
      transport_bn: 'মোটরসাইকেল বা ইজি-বাইক (টমটম) দিয়ে যাওয়া যায়।'
    }
  ],
  slider: [
    {
      title_en: 'Sunset at Kuakata Beach',
      title_bn: 'কুয়াকাটা সৈকতে মনোরম সূর্যাস্ত',
      image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80'
    },
    {
      title_en: 'Gangamati Mangrove Forest',
      title_bn: 'গঙ্গামতির সংরক্ষিত ম্যানগ্রোভ বন',
      image: 'https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=800&q=80'
    },
    {
      title_en: 'Scenic Jhau Forest',
      title_bn: 'মনোরম ঝাউবন ও ঝাউগাছের সৈকত',
      image: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?auto=format&fit=crop&w=800&q=80'
    },
    {
      title_en: 'Red Crab Beach Sanctuary',
      title_bn: 'লাল কাঁকড়ার অভয়ারণ্য সৈকত',
      image: 'https://images.unsplash.com/photo-1601662528567-526cd06f6582?auto=format&fit=crop&w=800&q=80'
    },
    {
      title_en: 'Misripara Buddhist Temple',
      title_bn: 'ঐতিহাসিক মিশ্রিপাড়া বৌদ্ধ মন্দির',
      image: 'https://images.unsplash.com/photo-1609137144814-4c4f34cf33fb?auto=format&fit=crop&w=800&q=80'
    }
  ]
};

// Seed in-memory mock store once on startup
function seedInMemoryContent() {
  console.log('Seeding in-memory content store...');
  for (const type of Object.keys(seedContentData)) {
    const defaultData = seedContentData[type] || [];
    defaultData.forEach(d => {
      inMemoryContent.push({
        _id: 'mock_ct_' + Math.random().toString(36).substr(2, 9),
        ...d,
        type,
        createdAt: new Date()
      });
    });
  }
}
seedInMemoryContent();

// Seed test user for Google Play Store review
async function seedTestUser() {
  try {
    // 1. Seed in-memory
    const testUserInMemory = inMemoryUsers.find(u => u.mobile === '01700000000');
    if (!testUserInMemory) {
      inMemoryUsers.push({
        _id: 'mock_user_test',
        name: 'Test User',
        mobile: '01700000000',
        pin: '1234',
        role: 'user',
        address: 'Kuakata',
      });
      console.log('Seeded in-memory test user: 01700000000 / 1234');
    }

    // 2. Seed MongoDB
    if (isUsingMongoDB) {
      const testUserMongo = await User.findOne({ mobile: '01700000000' });
      if (!testUserMongo) {
        const newUser = new User({
          name: 'Test User',
          mobile: '01700000000',
          pin: '1234',
          role: 'user',
          address: 'Kuakata',
        });
        await newUser.save();
        console.log('Seeded MongoDB test user: 01700000000 / 1234');
      }
    }
  } catch (error) {
    console.error('Error seeding test user:', error);
  }
}
seedTestUser();

// Seed MongoDB database with default content once on startup if empty
async function seedDefaultContent() {
  try {
    const count = await ContentItem.countDocuments();
    if (count === 0) {
      console.log('ContentItem collection in MongoDB is empty. Seeding default content...');
      for (const type of Object.keys(seedContentData)) {
        const defaultData = seedContentData[type] || [];
        if (defaultData.length > 0) {
          const seeded = defaultData.map(d => ({ ...d, type }));
          await ContentItem.insertMany(seeded);
          console.log(`Successfully seeded ${seeded.length} items of type: ${type} into MongoDB`);
        }
      }
    } else {
      console.log('MongoDB ContentItem collection already has data. Skipping seeding.');
    }
  } catch (error) {
    console.error('Error seeding default content in MongoDB:', error);
  }
}

// GET content by type
app.get('/api/content/:type', async (req, res) => {
  try {
    const { type } = req.params;

    if (isUsingMongoDB) {
      const items = await ContentItem.find({ type });
      return res.json(items);
    } else {
      const filtered = inMemoryContent.filter(c => c.type === type);
      return res.json(filtered);
    }
  } catch (error) {
    console.error('Error fetching content:', error);
    res.status(500).json({ error: 'Failed to fetch content', details: error.message });
  }
});

// CREATE content item
app.post('/api/content/:type', async (req, res) => {
  try {
    const { type } = req.params;
    const itemData = { ...req.body, type };

    if (isUsingMongoDB) {
      const newItem = new ContentItem(itemData);
      const saved = await newItem.save();
      return res.status(201).json(saved);
    } else {
      const mockItem = {
        _id: 'mock_ct_' + Math.random().toString(36).substr(2, 9),
        ...itemData,
        createdAt: new Date()
      };
      inMemoryContent.push(mockItem);
      return res.status(201).json(mockItem);
    }
  } catch (error) {
    console.error('Error creating content:', error);
    res.status(500).json({ error: 'Failed to create content', details: error.message });
  }
});

// UPDATE content item
app.put('/api/content/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (isUsingMongoDB) {
      const updated = await ContentItem.findByIdAndUpdate(id, updateData, { new: true });
      if (!updated) {
        return res.status(404).json({ error: 'Content item not found' });
      }
      return res.json(updated);
    } else {
      const index = inMemoryContent.findIndex(c => c._id === id);
      if (index === -1) {
        return res.status(404).json({ error: 'Content item not found' });
      }
      inMemoryContent[index] = {
        ...inMemoryContent[index],
        ...updateData,
        updatedAt: new Date()
      };
      return res.json(inMemoryContent[index]);
    }
  } catch (error) {
    console.error('Error updating content:', error);
    res.status(500).json({ error: 'Failed to update content', details: error.message });
  }
});

// DELETE content item
app.delete('/api/content/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (isUsingMongoDB) {
      const deleted = await ContentItem.findByIdAndDelete(id);
      if (!deleted) {
        return res.status(404).json({ error: 'Content item not found' });
      }
      return res.json({ success: true, message: 'Content deleted successfully' });
    } else {
      const index = inMemoryContent.findIndex(c => c._id === id);
      if (index === -1) {
        return res.status(404).json({ error: 'Content item not found' });
      }
      inMemoryContent.splice(index, 1);
      return res.json({ success: true, message: 'Content deleted successfully' });
    }
  } catch (error) {
    console.error('Error deleting content:', error);
    res.status(500).json({ error: 'Failed to delete content', details: error.message });
  }
});

// UPLOAD file via Base64 string
app.post('/api/upload', (req, res) => {
  try {
    const { image } = req.body;
    if (!image) {
      return res.status(400).json({ error: 'Image data is required' });
    }

    // Expect base64 format, which might start with data:image/png;base64, or similar
    const matches = image.match(/^data:image\/([A-Za-z-+\/]+);base64,(.+)$/);
    let base64Data = image;
    let ext = 'jpg';

    if (matches && matches.length === 3) {
      ext = matches[1];
      base64Data = matches[2];
    }

    const buffer = Buffer.from(base64Data, 'base64');
    const filename = `upload_${Date.now()}_${Math.floor(Math.random() * 1000)}.${ext}`;
    const filePath = path.join(__dirname, 'uploads', filename);

    fs.writeFileSync(filePath, buffer);

    // Return relative URL
    const fileUrl = `/uploads/${filename}`;
    res.json({ url: fileUrl });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: 'Failed to upload image', details: error.message });
  }
});

// ==================== HOTEL MANAGER MANAGEMENT ====================

// Get all managers (with hotel link metadata if possible)
app.get('/api/admin/managers', async (req, res) => {
  try {
    if (isUsingMongoDB) {
      const managers = await User.find({ role: 'manager' }).sort({ createdAt: -1 });
      return res.json(managers);
    } else {
      const managers = inMemoryUsers.filter(u => u.role === 'manager');
      return res.json(managers);
    }
  } catch (error) {
    console.error('Error fetching managers:', error);
    res.status(500).json({ error: 'Failed to fetch managers' });
  }
});

// Create a manager account
app.post('/api/admin/managers', async (req, res) => {
  try {
    const { name, address, mobile, pin, email, managedHotelId, hotelName } = req.body;
    if (!name || !address || !mobile || !pin || !managedHotelId) {
      return res.status(400).json({ error: 'Name, address, mobile, PIN, and managedHotelId are required' });
    }

    if (isUsingMongoDB) {
      const existingUser = await User.findOne({ mobile });
      if (existingUser) {
        return res.status(400).json({ error: 'An account with this mobile number already exists' });
      }

      const newManager = new User({
        name,
        address,
        mobile,
        pin,
        email: email || '',
        role: 'manager',
        managedHotelId,
        hotelName: hotelName || ''
      });
      const saved = await newManager.save();
      return res.status(201).json(saved);
    } else {
      const existingUser = inMemoryUsers.find(u => u.mobile === mobile);
      if (existingUser) {
        return res.status(400).json({ error: 'An account with this mobile number already exists' });
      }

      const mockManager = {
        _id: 'mock_mgr_' + Math.random().toString(36).substr(2, 9),
        name,
        address,
        mobile,
        pin,
        email: email || '',
        role: 'manager',
        managedHotelId,
        hotelName: hotelName || '',
        createdAt: new Date()
      };
      inMemoryUsers.push(mockManager);
      return res.status(201).json(mockManager);
    }
  } catch (error) {
    console.error('Error creating manager:', error);
    res.status(500).json({ error: 'Failed to create manager', details: error.message });
  }
});

// Delete a manager account
app.delete('/api/admin/managers/:id', async (req, res) => {
  try {
    const { id } = req.params;

    if (isUsingMongoDB) {
      const deleted = await User.findByIdAndDelete(id);
      if (!deleted) {
        return res.status(404).json({ error: 'Manager not found' });
      }
      return res.json({ success: true, message: 'Manager deleted successfully' });
    } else {
      const index = inMemoryUsers.findIndex(u => u._id === id);
      if (index === -1) {
        return res.status(404).json({ error: 'Manager not found' });
      }
      inMemoryUsers.splice(index, 1);
      return res.json({ success: true, message: 'Manager deleted successfully' });
    }
  } catch (error) {
    console.error('Error deleting manager:', error);
    res.status(500).json({ error: 'Failed to delete manager', details: error.message });
  }
});

// Get bookings for a specific hotel (manager view)
app.get('/api/bookings/manager/:hotelId', async (req, res) => {
  try {
    const { hotelId } = req.params;
    let targetHotelName = '';

    // Find the hotel name associated with this hotelId
    if (isUsingMongoDB) {
      const hotel = await ContentItem.findById(hotelId);
      if (hotel) {
        targetHotelName = hotel.name_en;
      }
    } else {
      const hotel = inMemoryContent.find(c => c._id === hotelId);
      if (hotel) {
        targetHotelName = hotel.name_en;
      }
    }

    if (!targetHotelName) {
      // Fallback: search in seed data if inMemoryContent doesn't have it loaded yet
      const seedHotels = seedContentData['hotel'] || [];
      const mockH = seedHotels.find(h => h.id === hotelId || h._id === hotelId || h.name_en.toLowerCase().includes(hotelId.toLowerCase()));
      if (mockH) {
        targetHotelName = mockH.name_en;
      }
    }

    if (!targetHotelName) {
      return res.json([]);
    }

    // Filter bookings where serviceType is 'hotel' and serviceName contains the hotel name
    if (isUsingMongoDB) {
      const bookings = await Booking.find({
        serviceType: 'hotel',
        serviceName: { $regex: targetHotelName.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), $options: 'i' }
      }).sort({ createdAt: -1 });
      return res.json(bookings);
    } else {
      const filtered = inMemoryBookings.filter(b => 
        b.serviceType === 'hotel' && 
        b.serviceName.toLowerCase().includes(targetHotelName.toLowerCase())
      );
      return res.json(filtered.slice().reverse());
    }
  } catch (error) {
    console.error('Error fetching manager bookings:', error);
    res.status(500).json({ error: 'Failed to fetch bookings' });
  }
});

// Update booking status
app.put('/api/bookings/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['Pending', 'Confirmed', 'Cancelled'].includes(status)) {
      return res.status(400).json({ error: 'Valid status is required' });
    }

    if (isUsingMongoDB) {
      const updated = await Booking.findByIdAndUpdate(id, { status }, { new: true });
      if (!updated) {
        return res.status(404).json({ error: 'Booking not found' });
      }
      return res.json(updated);
    } else {
      const index = inMemoryBookings.findIndex(b => b._id === id || b.id === id);
      if (index === -1) {
        return res.status(404).json({ error: 'Booking not found' });
      }
      inMemoryBookings[index].status = status;
      return res.json(inMemoryBookings[index]);
    }
  } catch (error) {
    console.error('Error updating booking status:', error);
    res.status(500).json({ error: 'Failed to update booking status' });
  }
});


// Start the Express Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend server is running on http://localhost:${PORT}`);
  console.log(`To test from Android Emulator use: http://10.0.2.2:${PORT}`);
});
