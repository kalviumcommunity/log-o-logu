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

/**
 * Sends an FCM push notification to the resident when a new visitor log is created.
 * Trigger: Firestore document create on 'logs/{logId}'.
 * Payload: title "Visitor Arrived", body "{guestName} has entered the gate."
 */
exports.onLogCreated = functions.firestore
  .document('logs/{logId}')
  .onCreate(async (snap, context) => {
    const logData = snap.data();
    if (!logData) {
      console.log('onLogCreated: No data in log document.');
      return null;
    }

    const { residentUid, guestName, inviteId: logInviteId } = logData;
    if (!residentUid) {
      console.log('onLogCreated: No residentUid in log document.');
      return null;
    }

    try {
      // If this log was created from an invite, check notifyOnArrival preference
      if (logInviteId) {
        const inviteDoc = await admin.firestore().collection('invites').doc(logInviteId).get();
        if (inviteDoc.exists) {
          const inviteData = inviteDoc.data();
          if (inviteData.notifyOnArrival === false) {
            console.log(`onLogCreated: Notification suppressed for invite ${logInviteId} (notifyOnArrival=false).`);
            return null;
          }
        }
      }

      // Fetch the resident's FCM token
      const userDoc = await admin.firestore().collection('users').doc(residentUid).get();
      if (!userDoc.exists) {
        console.log(`onLogCreated: Resident user ${residentUid} not found.`);
        return null;
      }

      const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) {
        console.log(`onLogCreated: No FCM token for resident ${residentUid}. Skipping notification.`);
        return null;
      }

      const visitorName = guestName || 'A visitor';

      const message = {
        token: fcmToken,
        notification: {
          title: 'Visitor Arrived',
          body: `${visitorName} has entered the gate.`,
        },
        data: {
          logId: context.params.logId,
          type: 'visitor_arrival',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'visitor_alerts',
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      await admin.messaging().send(message);
      console.log(`onLogCreated: Notification sent to resident ${residentUid} for visitor "${visitorName}".`);
      return null;
    } catch (error) {
      // If the token is invalid/expired, clean it up
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log(`onLogCreated: Invalid FCM token for ${residentUid}. Clearing token.`);
        await admin.firestore().collection('users').doc(residentUid).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      } else {
        console.error('onLogCreated: Error sending notification:', error);
      }
      return null;
    }
  });
