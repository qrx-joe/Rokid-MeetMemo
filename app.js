// MeetMemo AIUI app entry.
// Keep this file thin: app-level lifecycle only. Page logic lives in pages/.
// Services (parser/store/demo-data) will be added when the capture flow lands.

export default {
  onLaunch() {
    // Visible in dev console; safe to keep for first-run sanity check.
    console.log('[MeetMemo] App launched');
  },

  globalData: {
    // Reserved for cross-page state once we wire navigation.
    // Today only contact-card is registered; nothing to share yet.
  }
};
