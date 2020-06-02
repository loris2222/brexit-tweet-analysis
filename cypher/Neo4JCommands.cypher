//CLEAR ALL
//MATCH (n) DETACH DELETE n;

create index on :User(id);
create index on :Tweet(id);
create index on :Hashtag(id);
create index on :Hashtag(text);
create index on :Stance(id);
create index on :Sentiment(id);
create index on :User(tag);

//Create user and tweet nodes
//Link tweets to their stance and sentiment
//Link users to the tweets they authored
:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///withText.csv" AS row WITH row
MERGE(tweet:Tweet {id:row.ID})
ON CREATE SET tweet.text = row.text

:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///withText.csv" AS row WITH row
MERGE (user:User {id:row.user_id})
ON CREATE SET user.tag = row.user_tag

:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///withText.csv" AS row WITH row
MERGE (stance:Stance {id:row.t_stance})
MERGE (sentiment:Sentiment {id:row.t_sentiment})


:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///withText.csv" AS row WITH row
MATCH (tweet:Tweet {id:row.ID})
MATCH (user:User {id:row.user_id})
MATCH (stance:Stance {id:row.t_stance})
MATCH (sentiment:Sentiment {id:row.t_sentiment})
MERGE (tweet)-[:HasStance]->(stance)
MERGE (tweet)-[:HasSentiment]->(sentiment)
MERGE (user)-[:Tweets]->(tweet);

//Create additional user nodes from mentions
//Some users have been mentioned in tweets but 
//they are not present in the dataset.
:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///mentionedUsers.csv" AS row
MERGE(u:User {tag:row.u_tag})
ON CREATE SET u.id = row.u_id;

//Link user nodes to their sentiment and stance
:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///userStance.csv" AS row WITH row
MATCH (user:User {id:row.u_id})
MERGE (stance:Stance {id:row.u_stance})
MERGE (sentiment:Sentiment {id:row.u_sentiment})


:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///userStance.csv" AS row WITH row
MATCH (user:User {id:row.u_id})
MATCH (stance:Stance {id:row.u_stance})
MATCH (sentiment:Sentiment {id:row.u_sentiment})
MERGE (user)-[:HasStance]->(stance)
MERGE (user)-[:HasSentiment]->(sentiment);

//Set for each user stance and sentiment properties
//This is a derived property that is directly 
//inferred from the sentiment/stance they are
//linked to.
MATCH (u:User)
SET u.stance="undefined"
SET u.sentiment="undefined";

MATCH (u:User)-[:HasStance]-(st:Stance)
SET u.stance=st.id;

MATCH (u:User)-[:HasSentiment]-(se:Sentiment)
SET u.sentiment=se.id;

//Create hashtag nodes and link tweets that 
//make use of them.
:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///hashtags.csv" AS row
MATCH (tweet:Tweet {id:row.ID})
MERGE (hashtag:Hashtag {text:toLower(row.hashtag)})
MERGE (tweet)-[:Tags]->(hashtag);

//Link tweets to users they mention
:auto USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///mentions.csv" AS row
MATCH (tweet:Tweet {id:row.ID})
MERGE (user:User {tag:row.mention})
MERGE (tweet)-[:Mentions]->(user);

//Link users by mentions 
MATCH (n:User)-[:Tweets]->(:Tweet)-[:Mentions]->(m:User)
MERGE (n)-[:RefersTo]->(m);

//Link users to tags
MATCH (n:User)-[:Tweets]->(:Tweet)-[:Tags]->(t:Hashtag)
MERGE (n)-[:UsesHashtag]->(t);


//Set in degree for nodes based on how many
//other users refer to that user.
CALL algo.degree.stream("User", "RefersTo", {direction: "incoming"})
YIELD nodeId, score
SET algo.asNode(nodeId).referring = score;

Match (n:User)
set n:countHashtags;

Match (n:Hashtag)
set n:countHashtags;

//Set in degree for hashtags based on how many users use it
CALL algo.degree.stream(countHashtags, "UsesHashtag", {direction: "incoming"})
YIELD nodeId, score
SET algo.asNode(nodeId).hashtagUseCount = score;

Match (n:User)
remove n:countHashtags;

Match (n:Hashtag)
remove n:countHashtags;

MATCH (n)
WHERE NOT n:Hashtag
REMOVE n.hashtagUseCount;

//Map each instance of stance to an
//integer and set the relative property
//to display the communities by colour.
MATCH (n:User)
WHERE n.stance="remain"
SET n.stanceid=1;

MATCH (n:User)
WHERE n.stance="leave"
SET n.stanceid=2;

MATCH (n:User)
WHERE n.stance="other"
SET n.stanceid=3;

MATCH (n:User)
WHERE n.stance="undefined"
SET n.stanceid=4;
