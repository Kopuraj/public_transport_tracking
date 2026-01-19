// Auth routes for TransitLive Pro Backend

module.exports = function(app, admin, db, jwt) {
  // ============================================
  // SIGNUP ENDPOINT - Create new user
  // ============================================
  app.post('/api/auth/signup', async (req, res) => {
    try {
      const { email, password, fullName, role } = req.body;

      // Validate input
      if (!email || !password || !fullName) {
        return res.status(400).json({ 
          success: false, 
          error: 'Missing required fields: email, password, fullName' 
        });
      }

      if (password.length < 6) {
        return res.status(400).json({ 
          success: false, 
          error: 'Password must be at least 6 characters' 
        });
      }

      // Check if user already exists
      const existingUser = await db.collection('users')
        .where('email', '==', email)
        .limit(1)
        .get();

      if (!existingUser.empty) {
        return res.status(400).json({ 
          success: false, 
          error: 'Email already registered. Try logging in.' 
        });
      }

      // Create Firebase user
      const userRecord = await admin.auth().createUser({
        email: email,
        password: password,
        displayName: fullName
      });

      // Store user data in Firestore
      await db.collection('users').doc(userRecord.uid).set({
        uid: userRecord.uid,
        email: email,
        fullName: fullName,
        role: role || 'passenger',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        impactPoints: 0,
        status: 'active'
      });

      // Generate JWT token
      if (!process.env.JWT_SECRET) {
        console.error('❌ JWT_SECRET not configured in .env file');
        return res.status(500).json({ 
          success: false, 
          error: 'Server configuration error' 
        });
      }

      const token = jwt.sign(
        { uid: userRecord.uid, email: email },
        process.env.JWT_SECRET,
        { expiresIn: '24h' }
      );

      console.log(`✅ Signup successful: ${email}`);

      res.status(200).json({
        success: true,
        user: {
          uid: userRecord.uid,
          email: email,
          fullName: fullName,
          role: role || 'passenger'
        },
        token: token
      });

    } catch (error) {
      console.error('❌ Signup error:', error.message);

      if (error.code === 'auth/email-already-exists') {
        return res.status(400).json({ 
          success: false, 
          error: 'Email already registered' 
        });
      }
      if (error.code === 'auth/invalid-email') {
        return res.status(400).json({ 
          success: false, 
          error: 'Invalid email format' 
        });
      }
      if (error.code === 'auth/weak-password') {
        return res.status(400).json({ 
          success: false, 
          error: 'Password too weak. Use at least 6 characters' 
        });
      }

      res.status(400).json({ 
        success: false, 
        error: error.message || 'Signup failed' 
      });
    }
  });

  // ============================================
  // LOGIN ENDPOINT - Authenticate user
  // ============================================
  app.post('/api/auth/login', async (req, res) => {
    try {
      const { email, password } = req.body;

      // Validate input
      if (!email || !password) {
        return res.status(400).json({ 
          success: false, 
          error: 'Email and password required' 
        });
      }

      if (!process.env.JWT_SECRET) {
        console.error('❌ JWT_SECRET not configured in .env file');
        return res.status(500).json({ 
          success: false, 
          error: 'Server configuration error' 
        });
      }

      try {
        // Get user by email from Firebase Auth
        const userRecord = await admin.auth().getUserByEmail(email);

        // Verify password using Firebase REST API
        const firebaseRestApiUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${process.env.FIREBASE_WEB_API_KEY}`;
        
        const passwordVerificationResponse = await fetch(firebaseRestApiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            email: email,
            password: password,
            returnSecureToken: true
          })
        });

        const passwordVerificationData = await passwordVerificationResponse.json();

        if (!passwordVerificationResponse.ok || passwordVerificationData.error) {
          console.warn(`❌ Invalid password for user: ${email}`);
          return res.status(401).json({ 
            success: false, 
            error: 'Invalid email or password' 
          });
        }

        // Fetch user data from Firestore
        const userDoc = await db.collection('users').doc(userRecord.uid).get();

        if (!userDoc.exists) {
          return res.status(401).json({ 
            success: false, 
            error: 'User data not found' 
          });
        }

        const userData = userDoc.data();

        // Generate JWT token
        const token = jwt.sign(
          { uid: userRecord.uid, email: email },
          process.env.JWT_SECRET,
          { expiresIn: '24h' }
        );

        console.log(`✅ Login successful: ${email}`);

        res.status(200).json({
          success: true,
          user: {
            uid: userData.uid,
            email: userData.email,
            fullName: userData.fullName,
            role: userData.role
          },
          token: token
        });

      } catch (firebaseError) {
        if (firebaseError.code === 'auth/user-not-found') {
          return res.status(401).json({ 
            success: false, 
            error: 'No account found with this email' 
          });
        }
        console.error('Firebase error:', firebaseError.message);
        throw firebaseError;
      }

    } catch (error) {
      console.error('❌ Login error:', error.message);
      res.status(401).json({ 
        success: false, 
        error: error.message || 'Login failed' 
      });
    }
  });

  // ============================================
  // LOGOUT ENDPOINT - Clear token on client
  // ============================================
  app.post('/api/auth/logout', (req, res) => {
    try {
      console.log('✅ Logout successful');
      res.json({
        success: true,
        message: 'Logout successful'
      });
    } catch (error) {
      res.status(400).json({ 
        success: false, 
        error: error.message 
      });
    }
  });
};
