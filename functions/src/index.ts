/**
 * Stripe Integration for Orça+
 * Handles subscriptions, webhooks, and customer portal
 */

import { setGlobalOptions } from "firebase-functions";
import { onRequest, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import Stripe from "stripe";
import * as express from "express";

admin.initializeApp();

setGlobalOptions({
  maxInstances: 10,
  secrets: ["STRIPE_SECRET_KEY", "STRIPE_WEBHOOK_SECRET"],
});

// Initialize Stripe
const stripeKey = process.env.STRIPE_SECRET_KEY || "sk_test_placeholder";
const stripe = new Stripe(stripeKey, {
  apiVersion: "2025-02-24.acacia",
});

const endpointSecret = process.env.STRIPE_WEBHOOK_SECRET || "";

// Price ID to Tier Mapping
// TODO: Update these with actual Price IDs from Stripe Dashboard
const proProductId = process.env.STRIPE_PRODUCT_ID_PRO || "prod_pro";
const premiumProductId =
  process.env.STRIPE_PRODUCT_ID_PREMIUM || "prod_premium";

const PRODUCT_TO_TIER: { [key: string]: string } = {
  [proProductId]: "pro",
  [premiumProductId]: "premium",
};

/**
 * Stripe Webhook Handler
 * Processes all subscription events
 */
export const stripeWebhook = onRequest(
  async (request: express.Request, response: express.Response) => {
    const sig = request.headers["stripe-signature"] as string;

    let event: Stripe.Event;

    try {
      event = stripe.webhooks.constructEvent(
        request.body,
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
          const session =
            event.data.object as Stripe.Checkout.Session;
          await handleCheckoutCompleted(session);
          break;
        }

        case "customer.subscription.updated":
          await handleSubscriptionUpdated(
            event.data.object as Stripe.Subscription);
          break;

        case "customer.subscription.deleted":
          await handleSubscriptionDeleted(
            event.data.object as Stripe.Subscription);
          break;

        case "invoice.payment_succeeded":
          await handlePaymentSucceeded(
            event.data.object as Stripe.Invoice);
          break;

        case "invoice.payment_failed":
          await handlePaymentFailed(
            event.data.object as Stripe.Invoice);
          break;

        default:
          logger.info(`Unhandled event type: ${event.type}`);
      }

      response.json({ received: true });
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

  logger.info(`Processing checkout for user: ${userId}`);

  const subscriptionId = session.subscription as string;
  const subscription = await stripe.subscriptions.retrieve(subscriptionId);
  const customerId = subscription.customer as string;

  // Determine tier from product ID
  const productId = subscription.items.data[0].price.product as string;
  const tier = PRODUCT_TO_TIER[productId] || "pro";

  // Log product ID mapping for debugging
  logger.info(`Product ID: ${productId}`);
  logger.info(`Configured Pro Product ID: ${proProductId}`);
  logger.info(`Configured Premium Product ID: ${premiumProductId}`);
  logger.info(`Mapped tier: ${tier}`);

  if (!PRODUCT_TO_TIER[productId]) {
    logger.warn(
      `WARNING: Product ID ${productId} not found in mapping! ` +
      `Defaulting to 'pro'. Please check STRIPE_PRODUCT_ID_PRO and ` +
      `STRIPE_PRODUCT_ID_PREMIUM environment variables.`
    );
  }

  const subscriptionData = {
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
    stripeProductId: productId,
    stripeStatus: subscription.status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await admin.firestore().collection("subscriptions").doc(userId).set(
    subscriptionData,
    { merge: true }
  );

  logger.info(
    `✅ Subscription activated: user=${userId}, tier=${tier}, ` +
    `status=${subscription.status}, productId=${productId}`
  );
}

/**
 * Handle subscription updates (upgrade/downgrade)
 * @param {Stripe.Subscription} subscription
 */
async function handleSubscriptionUpdated(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  logger.info(`Processing subscription update for customer: ${customerId}`);

  // Find user by customer ID
  const subscriptionsRef = admin.firestore().collection("subscriptions");
  const snapshot = await subscriptionsRef
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.error(`❌ No user found for customer: ${customerId}`);
    return;
  }

  const userId = snapshot.docs[0].id;
  const productId = subscription.items.data[0].price.product as string;
  const tier = PRODUCT_TO_TIER[productId] || "pro";

  // Log product ID mapping for debugging
  logger.info(`Product ID: ${productId}`);
  logger.info(`Mapped tier: ${tier}`);
  logger.info(`Subscription status: ${subscription.status}`);

  if (!PRODUCT_TO_TIER[productId]) {
    logger.warn(
      `WARNING: Product ID ${productId} not found in mapping! ` +
      `Defaulting to 'pro'. Please verify environment variables.`
    );
  }

  // A subscription is considered active for these statuses:
  // - active: subscription is paid and active
  // - trialing: in trial period (still has access)
  // - past_due: payment failed but still has grace period access
  const validActiveStatuses = ["active", "trialing", "past_due"];
  const isActive = validActiveStatuses.includes(subscription.status);

  const updateData = {
    tier: tier,
    isActive: isActive,
    expiryDate: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_end * 1000
    ),
    periodStart: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_start * 1000
    ),
    stripeProductId: productId,
    stripeStatus: subscription.status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await admin.firestore().collection("subscriptions").doc(userId).update(
    updateData
  );

  logger.info(
    `✅ Subscription updated: user=${userId}, tier=${tier}, ` +
    `status=${subscription.status}, isActive=${isActive}, productId=${productId}`
  );
}

/**
 * Handle subscription cancellation
 * @param {Stripe.Subscription} subscription
 */
async function handleSubscriptionDeleted(subscription: Stripe.Subscription) {
  const customerId = subscription.customer as string;

  logger.info(`Processing subscription deletion for customer: ${customerId}`);

  const subscriptionsRef = admin.firestore().collection("subscriptions");
  const snapshot = await subscriptionsRef
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (snapshot.empty) {
    logger.error(`❌ No user found for customer: ${customerId}`);
    return;
  }

  const userId = snapshot.docs[0].id;
  const previousData = snapshot.docs[0].data();

  logger.info(
    `User ${userId} subscription being cancelled. ` +
    `Previous tier: ${previousData.tier}`
  );

  await admin.firestore().collection("subscriptions").doc(userId).update({
    tier: "free",
    isActive: false,
    expiryDate: admin.firestore.Timestamp.fromMillis(
      subscription.current_period_end * 1000
    ),
    stripeStatus: subscription.status,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  logger.info(
    `✅ Subscription cancelled: user=${userId}, ` +
    `tier changed from ${previousData.tier} to free`
  );
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
export const createStripePortalSession = onCall(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async (request: any) => {
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

    return { url: session.url };
  });

/**
 * Manually sync subscription from Stripe
 * Useful for debugging subscription issues
 */
export const syncSubscriptionFromStripe = onCall(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async (request: any) => {
    const userId = request.auth?.uid;

    if (!userId) {
      throw new Error("Unauthorized");
    }

    logger.info(`Manual sync requested for user: ${userId}`);

    try {
      // Get current subscription doc
      const subscriptionDoc = await admin.firestore()
        .collection("subscriptions")
        .doc(userId)
        .get();

      const subscriptionData = subscriptionDoc.data();

      if (!subscriptionData?.stripeSubscriptionId) {
        logger.warn(`No Stripe subscription ID found for user: ${userId}`);
        return {
          success: false,
          message: "Nenhuma assinatura Stripe encontrada para este usuário",
          currentData: subscriptionData || { tier: "free" },
        };
      }

      // Retrieve subscription from Stripe
      const subscription = await stripe.subscriptions.retrieve(
        subscriptionData.stripeSubscriptionId
      );

      logger.info(
        `Retrieved subscription from Stripe: ${subscription.id}, ` +
        `status: ${subscription.status}`
      );

      // Determine tier from product ID
      const productId = subscription.items.data[0].price.product as string;
      const tier = PRODUCT_TO_TIER[productId] || "pro";

      logger.info(`Product ID from Stripe: ${productId}, mapped tier: ${tier}`);

      if (!PRODUCT_TO_TIER[productId]) {
        logger.warn(
          `Product ID ${productId} not found in mapping! ` +
          `Using default 'pro'.`
        );
      }

      const validActiveStatuses = ["active", "trialing", "past_due"];
      const isActive = validActiveStatuses.includes(subscription.status);

      // Update Firestore with fresh data
      const updatedData = {
        tier: tier,
        isActive: isActive,
        expiryDate: admin.firestore.Timestamp.fromMillis(
          subscription.current_period_end * 1000
        ),
        periodStart: admin.firestore.Timestamp.fromMillis(
          subscription.current_period_start * 1000
        ),
        stripeProductId: productId,
        stripeStatus: subscription.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await admin.firestore()
        .collection("subscriptions")
        .doc(userId)
        .update(updatedData);

      logger.info(
        `✅ Manual sync completed for user: ${userId}, ` +
        `tier: ${tier}, status: ${subscription.status}`
      );

      return {
        success: true,
        message: "Assinatura sincronizada com sucesso!",
        syncedData: {
          tier,
          isActive,
          status: subscription.status,
          productId,
        },
      };
    } catch (error) {
      logger.error(`Error syncing subscription for user ${userId}:`, error);
      throw new Error(`Erro ao sincronizar: ${error}`);
    }
  });
