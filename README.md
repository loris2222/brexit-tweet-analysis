# Brexit tweet analysis

## Info
This project aims at analyzing the communities of twitter users based on their stance over Brexit. 
Mentions between users and used hastags have been analyzed and compared to their stance, a graphical representation allows for visual interpretation of the results.

## Dataset setup
### Using the original dataset and scraping with your preferred settings
- Download dataset from [dataverse](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/KP4XRP)
- You should download it into a `/data` folder and it should look like this
![folder structure](https://raw.githubusercontent.com/loris2222/brexit-tweet-analysis/master/pics/datafolder.png)  

### Using the preprocessed files and the first 7200 tweets from the dataset
- Create a `/data` folder and copy the contents of `/preprocessed` into `/data`

## Running
Follow the **workflow** appendix in the **report** to run the project.  

⚠️ You need to create your database with a Neo4J version that supports the "Graph Algorithms" plugin.
