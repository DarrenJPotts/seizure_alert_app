// Delete the profile first so daily-log security rules reject new client writes.
// Existing child records stay deletable by the owner if a retry is needed.
async function deleteDailyData(db, userRef, batchSize = 400) {
  await userRef.delete();
  let deleted = 0;
  while (true) {
    const snapshot = await userRef.collection("dailyLogs").limit(batchSize).get();
    if (snapshot.empty) return deleted;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += snapshot.docs.length;
  }
}
module.exports = { deleteDailyData };
