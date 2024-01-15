const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialisation de l'application admin Firebase
if (!admin.apps.length) {
    admin.initializeApp();
}

exports.createUser = functions.https.onCall(async (data, context) => {
    // Déstructurez les données et utilisez parseFloat pour convertir les chaînes en nombres
    const { email, password, nom, prenom, role, fonction, imageUrl, ville, telephone } = data;
    let latitudeNumber = parseFloat(data.latitude);
    let longitudeNumber = parseFloat(data.longitude);

    // Si la conversion échoue, utilisez 0.0 comme valeur par défaut
    latitudeNumber = isNaN(latitudeNumber) ? 0.0 : latitudeNumber;
    longitudeNumber = isNaN(longitudeNumber) ? 0.0 : longitudeNumber;

    try {
        // Création de l'utilisateur dans Firebase Auth
        const userCredential = await admin.auth().createUser({ email, password });

        // Ajout des détails de l'utilisateur à Firestore
        await admin.firestore().collection('users').doc(userCredential.uid).set({
            nom,
            prenom,
            email,
            role,
            fonction,
            imageUrl,
            ville,
            telephone
            // Enregistrez les valeurs numériques de latitude et longitude
            latitude: latitudeNumber,
            longitude: longitudeNumber,
            status: 'active' // ou toute autre valeur d'état que vous souhaitez définir
        });

        return { uid: userCredential.uid };
    } catch (error) {
        console.error("Erreur lors de la création de l'utilisateur:", error);
        throw new functions.https.HttpsError('internal', `Erreur lors de la création de l'utilisateur: ${error.code} - ${error.message}`);
    }
});

exports.deleteUser = functions.https.onCall(async (data, context) => {
    const uid = data.uid;

    try {
        // Suppression de l'utilisateur de Firebase Auth
        await admin.auth().deleteUser(uid);

        // La suppression de l'utilisateur de Firestore est déjà gérée dans l'application Dart.

        return { success: true };
    } catch (error) {
        console.error("Erreur lors de la suppression de l'utilisateur:", error);
        throw new functions.https.HttpsError('internal', `Erreur lors de la suppression de l'utilisateur: ${error.code} - ${error.message}`);
    }
});
