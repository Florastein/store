const content = {
  email_confirmation: {
    eyebrow: 'EMAIL CONFIRMATION',
    heading: 'Confirm it’s really you',
    intro: 'Use the verification code below to confirm your email address and finish setting up your Store account.',
    action: 'confirm your email address',
    securityNote: 'If you did not create a Store account, you can safely ignore this email.',
  },
  password_reset: {
    eyebrow: 'PASSWORD RESET',
    heading: 'Reset your password',
    intro: 'Use the verification code below to continue resetting your Store password.',
    action: 'reset your password',
    securityNote: 'If you did not request a password reset, secure your account and ignore this email.',
  },
  login: {
    eyebrow: 'SECURE LOGIN',
    heading: 'Complete your login',
    intro: 'Use the verification code below to securely sign in to your Store account.',
    action: 'complete your login',
    securityNote: 'If you did not try to sign in, do not share this code and review your account security.',
  },
};

const purposeSelect = document.querySelector('#purpose');

function renderPreview() {
  const selected = content[purposeSelect.value];
  for (const [id, value] of Object.entries(selected)) {
    document.querySelector(`#${id}`).textContent = value;
  }
}

purposeSelect.addEventListener('change', renderPreview);
renderPreview();
