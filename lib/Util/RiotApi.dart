import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RiotApi {
  Map summonerData;
  Map matchData;
  List summonerLeagueData;
  //This is for the new function implementation... DetailedMatchData()
  var matches;
  List matchDataListForUi;
  List numberOfKillsPerMatch;
  String globalChampName;

  Map matchDataForUi;

//Stores id of the champions from matches.
  List championIDList;
  List urlList;
  Map championInformation;

  String apiKey = "RGAPI-cd3ed7f7-f45f-4d97-8cf5-3d1bd9bbd70d";

  //Constructor (Template)
  RiotApi() {
    print("RiotAPI object is instantiating...");
    getStaticChampionData();
  }

  //List data;
//todo image caching

  Future<void> setSummonerData(String summonerName) async {
    print("Summoner nammmeee " + summonerName);
    var response = await http.get(
        Uri.encodeFull(
            "https://tr1.api.riotgames.com/lol/summoner/v3/summoners/by-name/$summonerName?api_key=$apiKey"),
        headers: {"Accept": "application/json"});
    summonerData = JSON.decode(response.body);
    print("Summoner datatata " + summonerData["profileIconId"].toString());
  }

  String getSummonerIconLink() {
    int profileIconId = summonerData["profileIconId"];
    print(profileIconId);
    String newUrl =
        "http://ddragon.leagueoflegends.com/cdn/8.9.1/img/profileicon/$profileIconId.png";
    return newUrl;
  }

  Future<void> getSummonerLeagueInfo() async {
    var summonerID = summonerData['id'];
    var response = await http.get(
        Uri.encodeFull(
            "https://tr1.api.riotgames.com/lol/league/v3/positions/by-summoner/$summonerID?api_key=$apiKey"),
        headers: {"Accept": "application/json"});
    summonerLeagueData = JSON.decode(response.body);
  }

  Future<void> getMatchListByAccountId() async {
    int accountID = summonerData["accountId"];
    var response = await http.get(
        Uri.encodeFull(
            'https://tr1.api.riotgames.com/lol/match/v3/matchlists/by-account/$accountID?endIndex=10&api_key=$apiKey'),
        headers: {"Accept": "application/json"});
    matchData = JSON.decode(response.body);
    matches = matchData['matches'];
    championIDList = new List();

    for (int i = 0; i < 10; i++) {
      print(matches[i]["champion"]);
      championIDList.add(matches[i]["champion"]);
    }
  }

  Future<void> getStaticChampionData() async {
    var response = await http.get(
        Uri.encodeFull(
            "https://tr1.api.riotgames.com/lol/static-data/v3/champions?locale=en_US&champListData=image&dataById=true&api_key=$apiKey"),
        headers: {"Accept": "application/json"});
    Map temp = JSON.decode(response.body);
    //To set the champion informations.
    championInformation = temp["data"];
    int i = 1;
    print(championInformation["$i"]["name"]);
  }



  void getTheChampNameFromMatch(int championId){
    championInformation.forEach((k,v){
        if(championInformation[k]["id"] == championId){
          Map temp = championInformation[k]["image"];
          String champName = temp["full"];
          champName = champName.substring(0, champName.length - 4);
          globalChampName = champName;
        }
    });
  }

  //This is a function to get the match id's of the last 10 games and get the data inside of them by using MATCh API from Riot... The api response has huge raw data, so we eliminate many of them...
  Future<void> getDetailedMatchData() async{
    matchDataListForUi = new List();
    int participantId;
    for(int i = 0 ; i < 10; i++){
      var matchId = matches[i]["gameId"];
      var response = await http.get(Uri.encodeFull("https://tr1.api.riotgames.com/lol/match/v3/matches/$matchId?api_key=$apiKey"),
          headers: {"Accept": "application/json"});
      Map rawMatchData = JSON.decode(response.body);
      List participantIdentities = rawMatchData["participantIdentities"];
      for(int i = 0; i < 10; i++){
        Map playerDto = participantIdentities[i]["player"];
        if(playerDto["summonerId"] == summonerData["id"]){
          participantId = participantIdentities[i]["participantId"];
          participantId--;
        }
      }
      List participants = rawMatchData["participants"];
      Map participantStatsDto = participants[participantId]["stats"];

      getTheChampNameFromMatch(participants[participantId]["championId"]);
      String champName = globalChampName;
      bool gameResult = participantStatsDto["win"];
      int numberOfKills = participantStatsDto["kills"];
      int numberOfDeaths = participantStatsDto["deaths"];

      matchDataForUi = {"kill" : "$numberOfKills",
        "deaths" : "$numberOfDeaths",
        "gameResult" : gameResult,
        "championName" : champName
      };

      matchDataListForUi.add(matchDataForUi);
    }

  }


}
