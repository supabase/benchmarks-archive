var firebase = require('firebase')

var firebaseConfig = {
  apiKey: process.env.FIRESTORE_API_KEY,
  authDomain: process.env.FIRESTORE_AUTH_DOMAIN,
  databaseURL: process.env.FIRESTORE_DATABASE_URL,
  projectId: process.env.FIRESTORE_PROJECT_ID,
  storageBucket: process.env.FIRESTORE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIRESTORE_MESSAGING_SENDER_ID,
  appId: process.env.FIRESTORE_APP_ID,
}

const main = async () => {
  // Initialize Firebase
  var app = firebase.initializeApp(firebaseConfig)

  var db = app.firestore()
  var n = 1

  // write 1 million documents in batches of 500
  for (var j = 0; j < 2000; j++) {
    // Get a new write batch
    let batch = db.batch()

    for (var i = 0; i < 500; i++) {
      let myRef = db.collection('read').doc(n.toString())
      batch.set(myRef, { slug: n })
      n = n + 1
    }

    // Commit the batch
    await batch.commit()
  }
}

main().then(console.log).catch(console.error)
