import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helper: send FCM push notification ───────────────────────────────────
async function sendPush(token: string, title: string, body: string, data?: Record<string, string>) {
  if (!token) return;
  try {
    await messaging.send({ token, notification: { title, body }, data });
  } catch (err) {
    functions.logger.warn("FCM send failed", err);
  }
}

async function getAdminTokens(): Promise<string[]> {
  const snap = await db.collection("users").where("role", "==", "admin").get();
  return snap.docs.map((d) => d.get("fcmToken")).filter(Boolean) as string[];
}

async function getCustomerToken(customerId: string): Promise<string | null> {
  const doc = await db.collection("users").doc(customerId).get();
  return doc.exists ? (doc.get("fcmToken") as string | null) : null;
}

// ─── Trigger 1: New request created → notify all admins ───────────────────
export const onRequestCreated = functions
  .region("europe-west1")
  .firestore.document("requests/{requestId}")
  .onCreate(async (snap) => {
    const data = snap.data();
    const customerName: string = data.customerName ?? "Un client";
    const category: string = data.details?.category ?? data.details?.eventType ?? "Demande";

    const adminTokens = await getAdminTokens();
    await Promise.all(
      adminTokens.map((token) =>
        sendPush(
          token,
          "Nouvelle demande INWIN",
          `${customerName} — ${category}`,
          { requestId: snap.id, type: "new_request" }
        )
      )
    );

    // Notify customer that their request is received
    const customerToken = await getCustomerToken(data.customerId);
    if (customerToken) {
      await sendPush(
        customerToken,
        "Demande reçue",
        "Nous avons bien reçu votre demande. Un conseiller INWIN reviendra vers vous avec un devis sous 24h.",
        { requestId: snap.id, type: "request_received" }
      );
    }

    functions.logger.info(`New request ${snap.id} created by ${customerName}`);
  });

// ─── Trigger 2: Request status changed ─────────────────────────────────────
export const onRequestUpdated = functions
  .region("europe-west1")
  .firestore.document("requests/{requestId}")
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status === after.status) return;

    const customerId: string = after.customerId;
    const customerToken = await getCustomerToken(customerId);
    if (!customerToken) return;

    const statusMessages: Record<string, { title: string; body: string }> = {
      pending: {
        title: "Demande en attente devis",
        body: "Votre demande a été placée en attente de devis.",
      },
      reviewing: {
        title: "Votre demande est en cours de traitement",
        body: "Notre équipe examine votre demande. Vous serez informé(e) très bientôt.",
      },
      quoted: {
        title: "Votre devis est prêt",
        body: `Montant proposé : ${after.quotedPrice} TND. Ouvrez l'app pour confirmer ou refuser.`,
      },
      accepted: {
        title: "Devis accepté — Merci !",
        body: "Votre commande est confirmée et sera bientôt en production.",
      },
      inProduction: {
        title: "Votre commande est en production",
        body: "Nous travaillons sur votre projet. Vous serez notifié(e) à la livraison.",
      },
      delivered: {
        title: "Livraison effectuée",
        body: "Votre commande a été livrée. Merci de votre confiance !",
      },
      rejected: {
        title: "Devis refusé",
        body: "Vous avez refusé le devis. Contactez-nous pour toute question.",
      },
      cancelled: {
        title: "Commande annulée",
        body: "Votre demande a été annulée. Contactez-nous pour plus d'informations.",
      },
    };

    const msg = statusMessages[after.status as string];
    if (msg) {
      await sendPush(customerToken, msg.title, msg.body, {
        requestId: change.after.id,
        type: "status_update",
        status: after.status as string,
      });
    }
  });

// ─── Trigger 3: New message → notify the other party ──────────────────────
export const onMessageCreated = functions
  .region("europe-west1")
  .firestore.document("requests/{requestId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const msg = snap.data();
    const requestId: string = context.params.requestId;
    const isAdmin: boolean = msg.isAdmin ?? false;

    const requestDoc = await db.collection("requests").doc(requestId).get();
    if (!requestDoc.exists) return;
    const request = requestDoc.data()!;

    if (isAdmin) {
      // Admin sent → notify customer
      const token = await getCustomerToken(request.customerId as string);
      if (token) {
        await sendPush(
          token,
          "Nouveau message de INWIN",
          msg.text as string,
          { requestId, type: "new_message" }
        );
      }
    } else {
      // Customer sent → notify all admins
      const adminTokens = await getAdminTokens();
      await Promise.all(
        adminTokens.map((token) =>
          sendPush(
            token,
            `Message de ${request.customerName as string}`,
            msg.text as string,
            { requestId, type: "new_message" }
          )
        )
      );
    }
  });

// ─── HTTP: health check ────────────────────────────────────────────────────
export const healthCheck = functions
  .region("europe-west1")
  .https.onRequest((req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
  });
