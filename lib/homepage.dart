import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Match {
  final String equipe1;
  final String equipe2;
  final DateTime dateDuMatch;
  int score1;
  int score2;
  String id;

  Match({
    required this.equipe1,
    required this.equipe2,
    required this.dateDuMatch,
    this.score1 = 0,
    this.score2 = 0,
    this.id = '',
  });

  factory Match.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    Timestamp timestamp = data['datedumatch'];
    return Match(
      equipe1: data['equipe1'] ?? '',
      equipe2: data['equipe2'] ?? '',
      dateDuMatch: timestamp.toDate(),
      score1: data['score1'] ?? 0,
      score2: data['score2'] ?? 0,
      id: doc.id,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Match? selectedMatch;
  TextEditingController _commentController = TextEditingController();

  Future<String> getUserPrenom() async {
    User? user = _auth.currentUser;
    if (user != null) {
      var userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['prenom'] ?? 'Utilisateur';
    } else {
      return 'Utilisateur';
    }
  }

  Stream<List<Match>> getUpcomingMatches() {
    return _firestore
        .collection('matchs')
        .where('statut', isEqualTo: 'À venir')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Match.fromFirestore(doc)).toList());
  }

  void updateScore(int equipe, int delta) async {
    if (selectedMatch != null) {
      int newScore1 = equipe == 1 ? selectedMatch!.score1 + delta : selectedMatch!.score1;
      int newScore2 = equipe == 2 ? selectedMatch!.score2 + delta : selectedMatch!.score2;

      newScore1 = newScore1 < 0 ? 0 : newScore1;
      newScore2 = newScore2 < 0 ? 0 : newScore2;

      await _firestore.collection('matchs').doc(selectedMatch!.id).update({
        'score1': newScore1,
        'score2': newScore2,
      });

      setState(() {
        selectedMatch = Match(
          equipe1: selectedMatch!.equipe1,
          equipe2: selectedMatch!.equipe2,
          dateDuMatch: selectedMatch!.dateDuMatch,
          score1: newScore1,
          score2: newScore2,
          id: selectedMatch!.id,
        );
      });
    }
  }

  void declareWinner(String equipeGagnante) async {
    if (selectedMatch != null) {
      await _firestore.collection('matchs').doc(selectedMatch!.id).update({
        'vainqueur': equipeGagnante,
      });
    }
  }

  void endMatch() async {
    if (selectedMatch != null) {
      await _firestore.collection('matchs').doc(selectedMatch!.id).update({
        'statut': 'terminé',
      });
    }
  }

  void deleteComment(String commentId) async {
    if (selectedMatch != null) {
      await _firestore.collection('matchs').doc(selectedMatch!.id)
          .collection('commentaires').doc(commentId).delete();
    }
  }



  void addComment(String commentaire) async {
    if (selectedMatch != null) {
      String commentId = DateTime.now().millisecondsSinceEpoch.toString();
      DateTime now = DateTime.now();
      await _firestore.collection('matchs').doc(selectedMatch!.id)
          .collection('commentaires').doc(commentId).set({
        'commentaire': commentaire,
        'dateAjout': now, // Date et heure actuelles
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: getUserPrenom(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text('Bonjour, ${snapshot.data}');
            }
            return Text('Chargement...');
          },
        ),
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3, // 3/4 de l'écran
            child: selectedMatch == null
                ? Center(child: Text('Sélectionnez un match'))
                : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedMatch!.equipe1} vs ${selectedMatch!.equipe2}',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => updateScore(1, 1),
                        child: Icon(Icons.add),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => updateScore(1, -1),
                        child: Icon(Icons.remove),
                      ),
                      Text("Score ${selectedMatch!.equipe1}: ${selectedMatch!.score1}"),
                    ],
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => updateScore(2, 1),
                        child: Icon(Icons.add),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => updateScore(2, -1),
                        child: Icon(Icons.remove),
                      ),
                      Text("Score ${selectedMatch!.equipe2}: ${selectedMatch!.score2}"),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => declareWinner(selectedMatch!.equipe1),
                    child: Text('Déclarer ${selectedMatch!.equipe1} vainqueur'),
                  ),
                  ElevatedButton(
                    onPressed: () => declareWinner(selectedMatch!.equipe2),
                    child: Text('Déclarer ${selectedMatch!.equipe2} vainqueur'),
                  ),
                  ElevatedButton(
                    onPressed: endMatch,
                    child: Text('Fin du Match'),
                    style: ElevatedButton.styleFrom(primary: Colors.red),
                  ),
                  SizedBox(height: 20),
                  Text('Ajouter un commentaire:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,  // Assurez-vous de définir ce contrôleur
                          decoration: InputDecoration(
                            hintText: 'Votre commentaire',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          if (_commentController.text.isNotEmpty) {
                            addComment(_commentController.text);
                            _commentController.clear(); // Nettoyer le champ après l'envoi
                          }
                        },
                      ),
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('matchs').doc(selectedMatch!.id)
                          .collection('commentaires').orderBy('dateAjout', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                        var commentaires = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: commentaires.length,
                          itemBuilder: (context, index) {
                            var commentaire = commentaires[index];
                            DateTime dateAjout = (commentaire['dateAjout'] as Timestamp).toDate();
                            return ListTile(
                              title: Text(commentaire['commentaire']),
                              subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(dateAjout)),
                              trailing: IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                onPressed: () => deleteComment(commentaire.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1, // 1/4 de l'écran
            child: StreamBuilder<List<Match>>(
              stream: getUpcomingMatches(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var matches = snapshot.data!;

                return ListView.builder(
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    Match match = matches[index];
                    return ListTile(
                      title: Text('${match.equipe1} vs ${match.equipe2}'),
                      subtitle: Text(
                          'Date: ${match.dateDuMatch.toLocal().toString()}'),
                      onTap: () {
                        setState(() {
                          selectedMatch = match;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
