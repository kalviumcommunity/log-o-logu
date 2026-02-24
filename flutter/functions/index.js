const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

/**
 * Validates a guest invite based on the QR code data (inviteId).
 * Enforces time-bound validity and status check.
 */
exports.validateInvite = functions.https.onCall(async (data, context) => {
  // 1. Check authentication (Only guards should be able to call this)
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'The function must be called while authenticated.'
    );
  }

  const { inviteId } = data;
  if (!inviteId) {
    throw new functions.https.HttpsError(
      'invalid-argument', 
      'The function must be called with an inviteId.'
    );
  }

  try {
    // 2. Fetch invite document
    const inviteDoc = await admin.firestore().collection('invites').doc(inviteId).get();

    if (!inviteDoc.exists) {
      return { status: 'Denied', message: 'Invite not found' };
    }

    const invite = inviteDoc.data();
    const now = admin.firestore.Timestamp.now();

    // 3. Validate window
    // Firestore Timestamps can be compared directly in Node.js
    if (now.toMillis() < invite.validFrom.toMillis() || now.toMillis() > invite.validUntil.toMillis()) {
      return { status: 'Denied', message: 'Invite is outside of validity window (expired or not yet active)' };
    }

    // 4. Check status
    if (invite.status !== 'pending' && invite.status !== 'approved') {
      return { status: 'Denied', message: `Invite is no longer valid (Status: ${invite.status})` };
    }

    // 5. Success
    return { 
      status: 'Success', 
      message: 'Invite verified',
      data: {
        guestName: invite.guestName,
        guestPhone: invite.guestPhone,
        type: invite.type,
        residentUid: invite.residentUid
      }
    };
  } catch (error) {
    console.error('Error validating invite:', error);
    throw new functions.https.HttpsError('internal', 'Internal server error');
  }
});

/**
 * Scheduled job to mark pending invites as "expired" once they pass their validUntil timestamp.
 * Runs every hour.
 */
exports.autoExpireInvites = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  
  try {
    const expiredInvites = await admin.firestore().collection('invites')
      .where('status', '==', 'pending')
      .where('validUntil', '<', now)
      .get();

    if (expiredInvites.empty) {
      console.log('No invites to expire.');
      return null;
    }

    const batch = admin.firestore().batch();
    expiredInvites.docs.forEach(doc => {
      batch.update(doc.ref, { status: 'expired' });
    });

    await batch.commit();
    console.log(`Successfully auto-expired ${expiredInvites.size} invites.`);
    return null;
  } catch (error) {
    console.error('Error auto-expiring invites:', error);
    return null;
  }
});
