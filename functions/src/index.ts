/**
 * Stripe Integration for Orça+
 * Handles subscriptions, webhooks, and customer portal
 */

import {setGlobalOptions} from "firebase-functions";
import {onRequest, onCall} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import Stripe from "stripe";

admin.initializeApp();

setGlobalOptions({maxInstances: 10});

// Initialize Stripe
const stripeKey = process.env.STRIPE_SECRET_KEY || "sk_test_placeholder";
const stripe = new Stripe(stripeKey, {
  apiVersion: "2025-02-24.acacia",
});

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

// Price ID to Tier Mapping
// TODO: Update these with actual Price IDs from Stripe Dashboard
const PRICE_TO_TIER: { [key: string]: string } = {
  "price_pro": "pro", // Replace with actual Pro price ID
  "price_premium": "premium", // Replace with actual Premium price ID
};

/**
 * Stripe Webhook Handler
 * Processes all subscription events
 */
export const stripeWebhook = onRequest(async (request, response) => {
  const sig = request.headers["stripe-signature"] as string;

  let event: Stripe.Event;

  try {
    event = stripe.webhooks.constructEvent(
      request.rawBody,
      sig,
      endpointSecret
    );
  } catch (err: unknown) {
    const error = err as Error;
    logger.error(`Webhook Error: ${error.message}`);
    response.status(400).send(`Webhook Error: ${error.message}`);
    return;
  }

  logger.info(`Webhook received: ${event.type}`);

  try {
    switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object as Stripe.Checkout.Session;
      await handleCheckoutCompleted(session);
      break;
    }

    case "customer.subscription.updated":
      await handleSubscriptionUpdated(event.data.object as Stripe.Subscription);
      break;

    case "customer.subscription.deleted":
      await handleSubscriptionDeleted(event.data.object as Stripe.Subscription);
      break;

    case "invoice.payment_succeeded":
      await handlePaymentSucceeded(event.data.object as Stripe.Invoice);
      break;

    case "invoice.payment_failed":
      await handlePaymentFailed(event.data.object as Stripe.Invoice);
      break;

    default:
      logger.info(`Unhandled event type: ${event.type}`);
    }

    response.json({received: true});
  } catch (error) {
    logger.error("Error processing webhook:", error);
    response.status(500).send("Internal server error");
  }
});

/**
 * Handle successful checkout
 * @param {Stripe.Checkout.Session} session
 */
async function handleCheckoutCompleted(session: Stripe.Checkout.Session) {
  const userId = session.client_reference_id;

  if (!userId) {
    logger.error("No user ID found in checkout session");
    return;
  }

  const subscriptionId = session.subscription as string;
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const customerId = subscription.customer as string;

  // Determine tier from price ID
  const priceId = subscription.items.data[0].price.id;
  const tier = PRICE_TO_TIER[priceId] || "pro";

  await admin.firestore().collection("subscriptions").doc(userId).set({
    tier: tier,
    isActive: true,
    expiryDate: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_end * 1000
    ),
    periodStart: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_start * 1000
    ),
    stripeSubscriptionId: subscriptionId,
    stripeCustomerId: customerId,
    stripePriceId: priceId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  logger.info(`Subscription activated: user=${userId}, tier=${tier}`);
}

/**
 * Handle subscription updates (upgrade/downgrade)
 * @param {Stripe.Subscription} subscription
 */
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  // Find user by customer ID
  const subscriptionsRef = admin.firestore().collection("subscriptions");
  const snapshot = await subscriptionsRef
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.error(`No user found for customer: ${customerId}`);
    return;
  }

  const userId = snapshot.docs[0].id;
  const priceId = subscription.items.data[0].price.id;
  const tier = PRICE_TO_TIER[priceId] || "pro";

  await admin.firestore().collection("subscriptions").doc(userId).update({
    tier: tier,
    isActive: subscription.status === "active",
    expiryDate: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_end * 1000
    ),
    periodStart: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_start * 1000
    ),
    stripePriceId: priceId,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Subscription updated: user=${userId}, tier=${tier}, ` +
    `status=${subscription.status}`);
}

/**
 * Handle subscription cancellation
 * @param {Stripe.Subscription} subscription
 */
async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  const subscriptionsRef = admin.firestore().collection("subscriptions");
  const snapshot = await subscriptionsRef
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.error(`No user found for customer: ${customerId}`);
    return;
  }

  const userId = snapshot.docs[0].id;

  await admin.firestore().collection("subscriptions").doc(userId).update({
    tier: "free",
    isActive: false,
    expiryDate: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_end * 1000
    ),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(`Subscription cancelled: user=${userId}`);
}

/**
 * Handle successful payment (renewal)
 * @param {Stripe.Invoice} invoice
 */
async function handlePaymentSucceeded(invoice: Stripe.Invoice) {
  if (!invoice.subscription) return;

  const subscription = await stripe.subscriptions.retrieve(
    invoice.subscription as string
  );

  await handleSubscriptionUpdated(subscription);
  logger.info(`Payment succeeded for subscription: ${subscription.id}`);
}

/**
 * Handle failed payment
 * @param {Stripe.Invoice} invoice
 */
async function handlePaymentFailed(invoice: Stripe.Invoice) {
  const customerId = invoice.customer as string;

  const subscriptionsRef = admin.firestore().collection("subscriptions");
  const snapshot = await subscriptionsRef
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (snapshot.empty) return;

  const userId = snapshot.docs[0].id;

  logger.warn(`Payment failed for user: ${userId}`);
  // Stripe will retry payments automatically
  // You can add notification logic here if needed
}

/**
 * Create Stripe Customer Portal Session
 * Allows users to manage their subscription
 */
export const createStripePortalSession = onCall(async (request) => {
  const userId = request.auth?.uid;

  if (!userId) {
    throw new Error("Unauthorized");
  }

  // Get user's subscription
  const subscriptionDoc = await admin.firestore()
    .collection("subscriptions")
    .doc(userId)
    .get();

  const subscriptionData = subscriptionDoc.data();

  if (!subscriptionData?.stripeCustomerId) {
    throw new Error("No active subscription found");
  }

  // Create portal session
  const session = await stripe.billingPortal.sessions.create({
    customer: subscriptionData.stripeCustomerId,
    return_url: `${process.env.APP_URL || "https://orcafacil.app"}/settings/subscription`,
  });

  logger.info(`Portal session created for user: ${userId}`);

  return {url: session.url};
});
