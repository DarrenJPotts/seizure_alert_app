/**
 * On/off flag for the safety-critical functions: SOS fan-out, cancel,
 * escalation, Heads Up expiry, watch actions and the caregiver alert screens.
 *
 * These functions deliberately do NOT use the budget kill switch in
 * killswitch.js. That switch is flipped automatically when the monthly budget
 * is reached, and a seizure alert must never be dropped because of spend.
 * Instead they read one Remote Config parameter, `sos_functions_enabled`, which
 * only a person changes (Firebase console → Remote Config), for example to stop
 * an abuse spike.
 *
 * Failure policy is the opposite of the kill switch: if Remote Config cannot
 * be read, keep the last value that was read successfully, or `true` if none
 * has been. An outage must not silence alerts; an explicit "off" set by a
 * person is still respected while Remote Config is unreachable.
 */

const SAFETY_FLAG_PARAM = "sos_functions_enabled";
const SAFETY_FLAG_CACHE_TTL_MS = 30 * 1000;

let cached = { enabled: true, fetchedAt: -Infinity };

function _resetSafetyFlagCache() {
  cached = { enabled: true, fetchedAt: -Infinity };
}

/**
 * @param {() => Promise<boolean>} loadFlag reads the current parameter value.
 * @param {number} now
 * @returns {Promise<boolean>}
 */
async function safetyFunctionsEnabled(loadFlag, now = Date.now()) {
  if (now - cached.fetchedAt < SAFETY_FLAG_CACHE_TTL_MS) return cached.enabled;

  try {
    const enabled = (await loadFlag()) !== false;
    cached = { enabled, fetchedAt: now };
  } catch (e) {
    console.error(
      `Could not read Remote Config ${SAFETY_FLAG_PARAM}; keeping last known value (${cached.enabled}).`,
      e
    );
    cached = { enabled: cached.enabled, fetchedAt: now };
  }
  return cached.enabled;
}

/**
 * Builds the loader used in production from a firebase-admin RemoteConfig.
 * A parameter missing from the template falls back to `true`.
 */
function remoteConfigFlagLoader(remoteConfig) {
  return async () => {
    const template = await remoteConfig.getServerTemplate({
      defaultConfig: { [SAFETY_FLAG_PARAM]: true },
    });
    return template.evaluate().getBoolean(SAFETY_FLAG_PARAM);
  };
}

module.exports = {
  safetyFunctionsEnabled,
  remoteConfigFlagLoader,
  SAFETY_FLAG_PARAM,
  SAFETY_FLAG_CACHE_TTL_MS,
  _resetSafetyFlagCache,
};
