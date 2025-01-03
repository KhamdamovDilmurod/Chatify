const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendVideoCallNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (data.type !== 'video_call') return null;

    const message = {
      token: data.token,
      notification: {
        title: 'Incoming Video Call',
        body: `${data.callData.callerName} is calling you`,
      },
      data: {
        type: 'video_call',
        channelId: data.callData.channelId,
      },
      android: {
        priority: 'high',
      },
    };

    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent notification:', response);
      return response;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
});

// Qo'ng'iroqni yakunlash uchun qo'shimcha funksiya
exports.endVideoCall = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { channelId } = data;

    try {
        await admin.firestore()
            .collection('video_calls')
            .doc(channelId)
            .update({
                isActive: false,
                endedAt: admin.firestore.FieldValue.serverTimestamp()
            });

        return { success: true };
    } catch (error) {
        console.error('Error ending call:', error);
        throw new functions.https.HttpsError('internal', 'Error ending call');
    }
});

// Qo'ng'iroqni boshlash uchun qo'shimcha funksiya
exports.initiateVideoCall = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { receiverId, callerName } = data;
    const callerId = context.auth.uid;

    try {
        // Receiver FCM tokenini olish
        const receiverDoc = await admin.firestore()
            .collection('users')
            .doc(receiverId)
            .get();

        if (!receiverDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Receiver not found');
        }

        const receiverToken = receiverDoc.data().fcmToken;
        const channelId = Date.now().toString();

        // Video call ma'lumotlarini saqlash
        await admin.firestore()
            .collection('video_calls')
            .doc(channelId)
            .set({
                callerId,
                receiverId,
                channelId,
                callerName,
                isActive: true,
                createdAt: admin.firestore.FieldValue.serverTimestamp()
            });

        // Notification yuborish
        if (receiverToken) {
            await admin.messaging().send({
                token: receiverToken,
                notification: {
                    title: 'Incoming Video Call',
                    body: `${callerName} is calling you`,
                },
                data: {
                    type: 'video_call',
                    channelId,
                },
                android: {
                    priority: 'high',
                }
            });
        }

        return { channelId };
    } catch (error) {
        console.error('Error initiating call:', error);
        throw new functions.https.HttpsError('internal', 'Error initiating call');
    }
});