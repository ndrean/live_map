// Source: https://levelup.gitconnected.com/rate-limiting-a0783293026a

const state = new Map();

async function getRateLimitState(key) {
  return state.get(key);
}

async function replaceRateLimitState(key, newState, oldState) {
  state.set(key, newState);
}

function update({ tokenCount, timestamp }, { interval, bucketCapacity }, now) {
  const increase = Math.floor((now - timestamp) / interval);
  const newTokenCount = Math.min(tokenCount + increase, bucketCapacity);
  const newTimestamp =
    newTokenCount < bucketCapacity ? timestamp + interval * increase : now;
  return { tokenCount: newTokenCount, timestamp: newTimestamp };
}

function take(oldState, options, now) {
  const { tokenCount, timestamp } = oldState
    ? update(oldState, options, now)
    : { tokenCount: options?.bucketCapacity, timestamp: now };
  if (tokenCount > 0 && now >= timestamp) {
    console.log("not wait");
    // if there is a token available and the timestamp is in the past take the token and leave the timestamp un-changed
    return { tokenCount: tokenCount - 1, timestamp };
  }
  console.log("wait");
  // update the timestamp to a time when a token will be available, leaving the token count at 0
  return { tokenCount, timestamp: timestamp + options?.interval };
}

function disableClick(e) {
  e.stopPropagation();
  e.preventDefault();
}

export default async function takeToken(key, options) {
  window.addEventListener("click", disableClick, true);
  const now = Date.now();
  const oldState = await getRateLimitState(key);
  const newState = take(oldState, options, now);
  // // replaceRateLimitState should throw if current state doesn't match oldState to avoid concurrent token usage
  await replaceRateLimitState(key, newState, oldState);
  if (newState.timestamp - now >= 0) {
    console.log("await end");
    await new Promise((r) => setTimeout(r, newState.timestamp - now));
  }
  window.removeEventListener("click", disableClick, true);
}
