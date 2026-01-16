import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2024-11-20.acacia',
});

// Only initialize if key is provided
if (!process.env.STRIPE_SECRET_KEY) {
  console.warn('⚠️  STRIPE_SECRET_KEY not set. Stripe Connect features will not work.');
}

const COMMISSION_RATE = 15.00; // 15% platform commission

/**
 * Create a Stripe Connect account for a provider
 * Returns the account ID and onboarding link
 */
export async function createConnectAccount(email: string, name: string) {
  try {
    const account = await stripe.accounts.create({
      type: 'express',
      country: 'US', // Change to your country
      email: email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      business_type: 'individual', // or 'company'
    });

    // Create account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/stripe/reauth`,
      return_url: `${process.env.FRONTEND_URL || 'http://localhost:3000'}/stripe/return`,
      type: 'account_onboarding',
    });

    return {
      accountId: account.id,
      onboardingUrl: accountLink.url,
    };
  } catch (error: any) {
    console.error('Error creating Stripe Connect account:', error);
    throw new Error(`Failed to create Stripe account: ${error.message}`);
  }
}

/**
 * Get the onboarding status of a Stripe Connect account
 */
export async function getAccountStatus(accountId: string) {
  try {
    const account = await stripe.accounts.retrieve(accountId);
    return {
      chargesEnabled: account.charges_enabled,
      payoutsEnabled: account.payouts_enabled,
      detailsSubmitted: account.details_submitted,
    };
  } catch (error: any) {
    console.error('Error retrieving Stripe account:', error);
    throw new Error(`Failed to retrieve account: ${error.message}`);
  }
}

/**
 * Create a payment intent with automatic split (15% to platform, 85% to provider)
 */
export async function createPaymentIntentWithSplit(
  amount: number,
  currency: string,
  providerStripeAccountId: string,
  applicationFeeAmount: number
) {
  try {
    // Create payment intent on the provider's connected account
    const paymentIntent = await stripe.paymentIntents.create(
      {
        amount: Math.round(amount * 100), // Convert to cents
        currency: currency.toLowerCase(),
        application_fee_amount: Math.round(applicationFeeAmount * 100), // Platform commission in cents
        on_behalf_of: providerStripeAccountId,
        transfer_data: {
          destination: providerStripeAccountId,
        },
      },
      {
        stripeAccount: providerStripeAccountId,
      }
    );

    return paymentIntent;
  } catch (error: any) {
    console.error('Error creating payment intent with split:', error);
    // Fallback: Create payment intent on platform account, then transfer
    return await createPaymentIntentWithTransfer(amount, currency, providerStripeAccountId, applicationFeeAmount);
  }
}


/**
 * Confirm a payment intent
 */
export async function confirmPaymentIntent(paymentIntentId: string) {
  try {
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    
    if (paymentIntent.status === 'succeeded') {
      return paymentIntent;
    }

    // If not already succeeded, confirm it
    const confirmed = await stripe.paymentIntents.confirm(paymentIntentId);
    return confirmed;
  } catch (error: any) {
    console.error('Error confirming payment intent:', error);
    throw new Error(`Failed to confirm payment: ${error.message}`);
  }
}

/**
 * Calculate commission amounts
 */
export function calculateCommission(totalAmount: number) {
  const platformCommission = (totalAmount * COMMISSION_RATE) / 100;
  const providerAmount = totalAmount - platformCommission;
  
  return {
    platformCommission,
    providerAmount,
    commissionRate: COMMISSION_RATE,
  };
}

/**
 * Create a login link for provider to access their Stripe dashboard
 */
export async function createLoginLink(accountId: string) {
  try {
    const loginLink = await stripe.accounts.createLoginLink(accountId);
    return loginLink.url;
  } catch (error: any) {
    console.error('Error creating login link:', error);
    throw new Error(`Failed to create login link: ${error.message}`);
  }
}
